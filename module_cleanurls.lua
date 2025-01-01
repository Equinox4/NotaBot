local prefix = Config.Prefix
local enums = Discordia.enums
local http = require("coro-http")
local sha256 = require('sha256').sha256
local ansiColoursFg = util.ansiColoursFg

--[[
	This module is used to clean URLs from unwanted tracking (or, depending of guild configuration, any) query
	parameters.
	It will replace the URL with a cleaned version, and optionally delete the message that invoked the command.
	To preserve the flow of an happening conversation, a webhook is used to mimic the user that initially posted the
	message.
]]

Module.Name = "cleanurls"


function Module:GetConfigTable()
	return {
		{
			Name = "DeleteInvokationOnAutoCleanUrls",
			Description = "Deletes the message that invoked the clean urls when auto-cleaning urls",
			Type = Bot.ConfigType.Boolean,
			Default = true
		},
		{
			Name = "DeleteButtonExpirationTime",
			Description = "The time, in seconds after which the delete button will disappear",
			Type = Bot.ConfigType.Integer,
			Default = 10
		},
		{
			Name = "IgnoredChannels",
			Description = "Channels where URLs will not be cleaned.",
			Type = Bot.ConfigType.Channel,
			Array = true,
			Default = {}
		}
	}
end

local commonParameters = {
	aliexpress = Set { "spm", "scm", "algo_expid", "algo_pvid" },
	amazon     = Set { "__mk_fr_FR", "pd_rd_", "_encoding", "psc", "tag", "ref", "pf_rd_", "pf", "crid",
		"keywords", "sprefix", "smid", "creative", "th", "linkCode", "sr", "ie", "node", "qid", "dib", "dib_tag", "ref"
	},
	google     = Set { "gs_lcp", "ved", "ei", "sei", "gws_rd", "gs_gbg", "gs_mss", "gs_rn" },
	twitter    = Set { "t", "s" }
}

local defaultRules = {
	["fr.aliexpress.com"] = commonParameters.aliexpress,
	["aliexpress.fr"]     = commonParameters.aliexpress,
	["www.amazon.fr"]     = commonParameters.amazon,
	["www.amazon.de"]     = commonParameters.amazon,
	["bilibili.com"]      = Set { "callback" },
	["bing.com"]          = Set { "cvid", "form", "sk", "sp", "sc", "qs", "pq" },
	["facebook.com"]      = Set { "refsrc", "hrc" },
	["google.fr"]         = commonParameters.google,
	["google.com"]        = commonParameters.google,
	["sourceforge.net"]   = Set { "source", "position" },
	["twitter.com"]       = commonParameters.twitter,
	["fixupx.com"]        = commonParameters.twitter,
	["fxtwitter.com"]     = commonParameters.twitter,
	["twittpr.com"]       = commonParameters.twitter,
	["fixvx.com"]         = commonParameters.twitter,
	["yandex.com"]        = Set { "lr", "redircnt" },
	["yandex.ee"]         = Set { "lr", "redircnt" },
	["youtube.com"]       = Set { "si", "pp", "kw", "feature" },
	["youtu.be"]          = Set { "si" },
	["open.spotify.com"]  = Set { "si" },
	["reddit.com"]        = Set { "share_id" },
}

--[[ TODO
local fixServices = {
	["bsky.app"] = "bskyx.app",
	-- Currently broken
	-- ["deviantart.com"] = "fxdeviantart.com",
	["instagram.com"] = "ddinstagram.com",
	["pixiv.net"] = "ppxiv.net",
	["reddit.com"] = "rxddit.com",
	-- Currently broken
	["threads.net"] = "fixthreads.net",
	["tiktok.com"] = "tnktok.com",
	["tumblr.com"] = "tpmblr.com",
	["twitch.tv"] = "fxtwitch.tv",
	-- Use vxtwitter instead of fxtwitter since it includes greedy analytics
	["twitter.com"] = "vxtwitter.com",
	["x.com"] = "fixvx.com",
}
]]
--	if self.FixServices[host] then
--		local fix = self.FixServices[host]
--		local newHost = host:gsub(host, fix)
--		return protocol .. newHost .. path .. queryString
--	end

function Module:OnLoaded()
	self:RegisterCommand({
		Name = "cleanurlsaddrule",
		Args = {
			{ Name = "domainName", Description = "The domain name", Type = Bot.ConfigType.String, },
			{ Name = "urlParam", Description = "The parameter of the url to filter", Type = Bot.ConfigType.String, }
		},
		Help = function (guild) return Bot:Format(guild, "CLEAN_URLS_ADD_HELP") end,
		PrivilegeCheck = function (member) return member:hasPermission(enums.permission.manageMessages) end,
		Func = function(cmd, domainName, param)
			local guild = cmd.guild

			if not domainName or not param then
				return cmd:reply(Bot:Format(guild, 'CLEAN_URLS_NO_RULE_PROVIDED'))
			end

			local data = self:GetPersistentData(guild)
			local rules = data.Rules

			if rules[domainName] then
				rules[domainName][param] = true
			else
				rules[domainName] = Set { param }
			end

			cmd:reply(Bot:Format(guild, 'CLEAN_URLS_RULE_ADDED', domainName, param))
		end
	})

	self:RegisterCommand({
		Name = "cleanurlsremoverule",
		Args = {
			{ Name = "domainName", Description = "Remove this domain name from the filter list", Type = Bot.ConfigType.String, },
			{ Name = "urlParam", Description = "Remove only this parameter for this domain name from the filter list",
				Type = Bot.ConfigType.String, Optional = true }
		},
		Help = function (guild) return Bot:Format(guild, "CLEAN_URLS_REMOVE_HELP") end,
		PrivilegeCheck = function (member) return member:hasPermission(enums.permission.administrator) end,
		Func = function(cmd, domainName, param)
			local guild = cmd.guild

			if not domainName then
				return cmd:reply(Bot:Format(guild, 'CLEAN_URLS_NO_RULE_PROVIDED'))
			end

			local data = self:GetPersistentData(guild)
			local rules = data.Rules

			if rules[domainName] then
				if not param then
					rules[domainName] = nil
				else
					rules[domainName][param] = nil
					if not next(rules[domainName]) then
						rules[domainName] = nil
					end
				end
			end

			cmd:reply(Bot:Format(guild, 'CLEAN_URLS_RULE_REMOVED', domainName, param or ""))
		end
	})

	self:RegisterCommand({
		Name = "cleanurlslistrules",
		Args = {
			{ Name = "domainName", Description = "Display the rule corresponding to this domain",
				Type = Bot.ConfigType.String, Optional = true }
		},
		Help = function (guild) return Bot:Format(guild, "CLEAN_URLS_LIST_HELP") end,
		PrivilegeCheck = function (member) return member:hasPermission(enums.permission.manageMessages) end,
		Func = function(cmd, domainName)
			local guild = cmd.guild
			local data = self:GetPersistentData(guild)
			local rules = data.Rules

			if not next(rules) or (domainName and not rules[domainName]) then
				return cmd:reply(Bot:Format(guild, 'CLEAN_URLS_NO_RULES'))
			end

			local result = ""

			if not domainName then
				for ruleDomainName, _ in pairs(rules) do
					result = result .. string.format("%s\n", ruleDomainName)
				end
			else
				result = result .. string.format("%s\n%s\n", domainName:colour(ansiColoursFg.cyan),
					table.concat(
						table.map(
							table.keys(rules[domainName]),
							function (param) return param:colour(ansiColoursFg.yellow) end
						),
						", "
					)
				)
			end

			result = string.format("### %s\n```ansi\n%s```", Bot:Format(guild, 'CLEAN_URLS_RULES_HEADER'), result)
			cmd:reply(result)
		end
	})

	self:RegisterCommand({
		Name = "cleanurlsclearrules",
		PrivilegeCheck = function (member) return member:hasPermission(enums.permission.administrator) end,
		Args = {},
		Help = function (guild) return Bot:Format(guild, "CLEAN_URLS_CLEAR_HELP") end,
		Func = function(cmd)
			local guild = cmd.guild
			local data = self:GetPersistentData(guild)
			data.Rules = {}

			cmd:reply(Bot:Format(guild, "CLEAN_URLS_RULES_CLEARED"))
		end
	})

	self:RegisterCommand({
		Name = "cleanurlsdefault",
		PrivilegeCheck = function (member) return member:hasPermission(enums.permission.administrator) end,
		Args = {},
		Help = function (guild) return Bot:Format(guild, "CLEAN_URLS_DEFAULT_HELP") end,
		Func = function(cmd)
			local guild = cmd.guild
			local data = self:GetPersistentData(guild)
			data["Rules"] = defaultRules

			cmd:reply(Bot:Format(guild, "CLEAN_URLS_RULES_RESTORED"))
		end
	})

	return true
end

local function filterURLParams(url, rules)
	local protocol, host, path, queryString = url:match("^(https?://)([^/]+)(/[^?]*)(.-)$")

	if not rules[host] then
		return false
	end

	if not queryString or queryString:sub(2) == "" then
		-- host match but no parameters, nothing to do
		return false
	end

	local queryParams = {}
	for paramName, paramValue in queryString:sub(2):gmatch("([^&=]+)=([^&]*)") do
		if not rules[host][paramName] then
			queryParams[paramName] = paramValue
		end
	end

	local newUrl = protocol .. host .. path

	if next(queryParams) then
		local newQueryString = {}
		for k, v in pairs(queryParams) do
			table.insert(newQueryString, k .. "=" .. v)
		end

		newQueryString = table.concat(newQueryString, "&")
		newUrl = newUrl .. "?" .. newQueryString
	end

	return true, newUrl
end

---comment
---@param message Message
---@param config table<string, any>
---@param data table<string, any>
local function cleanMessage(message, rules)
	local content = message.content

	-- Do not detect urls inside backticks
	local blockquotes = {}
	if content:find("`.+`") then
		for match in content:gmatch('`[^`\n]+`') do
			local hash = sha256(match)
			blockquotes[hash] = match
		end

		for match in content:gmatch('```[^`]+```') do
			local hash = sha256(match)
			blockquotes[hash] = match
		end

		for hash, originalStr in pairs(blockquotes) do
			content = content:gsub(originalStr:gsub("%W", "%%%0"), hash)
		end
	end

	if not content:find("https?://") then
		return false
	end

	for url in content:gmatch("(https?://[^\n%s]+)") do
		local res, newUrl = filterURLParams(url, rules)
		if res then
			content = content:gsub(url:gsub("%W", "%%%0"), newUrl)
		end
	end

	for hash, originalStr in pairs(blockquotes) do
		content = content:gsub(hash, originalStr:gsub("%W", "%%%0"))
	end

	return true, content
end

---@param message Message
function Module:OnMessageCreate(message)
	if message.author.bot or message.webhookId then
		return
	end

	if (message.content:startswith(prefix, true)) then
		return
	end

	local channel = message.channel
	if (not Bot:IsPublicChannel(channel)) then
		return
	end

	local guild = message.guild
	local config = self:GetConfig(guild)
	local data = self:GetPersistentData(guild)

	if table.search(config.IgnoredChannels, channel.id) then
		return
	end

	-- A webhook cannot be associated with a thread, we need to get the parent channel in this case
	local threadId
	if channel.isThread then
		threadId = channel.id
		channel = message.client:getChannel(channel._parent_id)
	end

	local isCleaned, webhookMessageContent = cleanMessage(message, data["Rules"])
	if not isCleaned then
		return
	end

	local webhook = self:GetWebhook(guild, channel)
	local author = message.author
	local components = {
		{
			type = enums.componentType.actionRow,
			components = {
				{
					type = enums.componentType.button,
					style = enums.buttonStyle.danger,
					label = Bot:Format(guild, "CLEAN_URLS_DELETE_BUTTON_LABEL"),
					-- TODO pour être safe ici il faudrait enregistrer une association msg_id => author_id
					-- en config pour éviter que qq'un qui bidouille le front ne puisse bypass la vérification de permission
					-- Mais ce n'est pas critique, on pourra voir ça plus tard
					custom_id = "delete_" .. author.id,
				}
			}
		}
	}

	local attachments = {}
	if message.attachments then
		for _, attachment in pairs(message.attachments) do
			local _, attachmentData = http.request("GET", attachment.url)
				if attachmentData then
					table.insert(attachments, { attachment.filename, attachmentData })
				end
		end
	end

	local webhookMessage = webhook:execute(
		{
			avatar_url = author.avatarURL,
			username   = author.globalName or author.username,
			content    = webhookMessageContent,
			components = components,
		},
		{
			wait = true,
			thread_id = threadId
		},
		attachments
	)

	if config.DeleteInvokationOnAutoCleanUrls then
		message:delete()
	end

	local deletionTime = os.time() + config.DeleteButtonExpirationTime
	-- This will generate a 404 http error if the webhookMessage is deleted
	Bot:ScheduleAction(deletionTime, function()
		webhook:editMessage(
			webhookMessage.id,
			{ components = {} },
			{ thread_id = threadId }
		)
	end)
end

---@param guild Guild
---@return boolean
function Module:OnEnable(guild)
	local data = self:GetPersistentData(guild)

	data["Rules"] = data["Rules"] or defaultRules
	data["WebhooksMappings"] = data["WebhooksMappings"] or {}

	self:SavePersistentData(guild)

	return true
end

---@param interaction Interaction
function Module:OnInteractionCreate(interaction)
	local customId = interaction.data.custom_id
	local guild = interaction.guild

	local authorId = customId:match("delete_(%d+)")
	if not authorId then
		return
	end

	local interactionAuthorId = interaction.member.user.id

	if authorId ~= interactionAuthorId and not interaction.member:hasPermission(interaction.channel, 'manageMessages') then
		return interaction:respond({
			type = enums.interactionResponseType.channelMessageWithSource,
			data = {
				flags = enums.interactionResponseFlag.ephemeral,
				content = Bot:Format(guild, "CLEAN_URLS_WRONG_USER_BUTTON")
			}
		})
	end

	if interaction.message then
		interaction.message:delete()
	end

	interaction:respond({
		type = enums.interactionResponseType.channelMessageWithSource,
		data = {
			flags = enums.interactionResponseFlag.ephemeral,
			content = Bot:Format(guild, "CLEAN_URLS_DELETED_MESSAGE"),
		}
	})
end

---@param guild Guild
---@param channel GuildTextChannel
---@return Webhook
function Module:GetWebhook(guild, channel)
	local data = self:GetPersistentData(guild)
	local webhookId = data.WebhooksMappings[channel.id]

	if not webhookId then
		local webhook = channel:createWebhook(Bot:Format(guild, "CLEAN_URLS_AUDITLOG"))

		data.WebhooksMappings[channel.id] = webhook.id
		self:SavePersistentData(guild)

		return webhook
	end

	return Client:getWebhook(webhookId)
end
