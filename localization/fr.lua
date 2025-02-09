local timeUnits = {}
local timeUnitByUnit = {}

do
	local minuteSecond     = 60
	local hourSecond       = 60 * minuteSecond
	local daySecond        = 24 * hourSecond
	local weekSecond       = 7 * daySecond
	local monthSecond      = 30 * daySecond -- Prendre 4 semaines n'aurait fait que 28 jours
	local yearSecond       = 365 * daySecond -- Prendre 12 mois n'aurait fait que 360 jours
	local centurySecond    = 100 * yearSecond
	local millenniumSecond = 10 * centurySecond

	table.insert(timeUnits, {
		AltNames = { "u" },
		NameSingular = "âge de l'Univers",
		NamePlural = "âges de l'Univers",
		Seconds = 13800000 * millenniumSecond
	})

	table.insert(timeUnits, {
		AltNames = { "mi" },
		NameSingular = "millénaire",
		NamePlural = "millénaires",
		Seconds = millenniumSecond,
		One = "un"
	})

	table.insert(timeUnits, {
		AltNames = { "c" },
		NameSingular = "siècle",
		NamePlural = "siècles",
		Seconds = centurySecond,
		One = "un"
	})

	table.insert(timeUnits, {
		AltNames = { "y" },
		NameSingular = "an",
		NamePlural = "ans",
		Seconds = yearSecond,
		One = "un"
	})

	table.insert(timeUnits, {
		AltNames = { "M" },
		NamePlural = "mois",
		Seconds = monthSecond,
		One = "un"
	})

	table.insert(timeUnits, {
		AltNames = { "w" },
		NameSingular = "semaine",
		NamePlural = "semaines",
		Seconds = weekSecond,
		One = "une"
	})

	table.insert(timeUnits, {
		AltNames = { "d" },
		NameSingular = "jour",
		NamePlural = "jours",
		Seconds = daySecond,
		One = "un"
	})

	table.insert(timeUnits, {
		AltNames = { "h" },
		NameSingular = "heure",
		NamePlural = "heures",
		Seconds = hourSecond,
		One = "une"
	})

	table.insert(timeUnits, {
		AltNames = { "m", "min" },
		NameSingular = "minute",
		NamePlural = "minutes",
		Seconds = minuteSecond,
		One = "une"
	})

	table.insert(timeUnits, {
		AltNames = { "s", "sec" },
		NameSingular = "seconde",
		NamePlural = "secondes",
		Seconds = 1,
		One = "une"
	})

	-- Processing
	for _, data in pairs(timeUnits) do
		local function registerUnit(unit)
			if (timeUnitByUnit[unit] ~= nil) then
				error("TimeUnit name " .. unit .. " is already registered")
			end

			timeUnitByUnit[unit] = data
		end

		if data.NameSingular then
			registerUnit(data.NameSingular)
		end

		if data.NamePlural then
			registerUnit(data.NamePlural)
		end

		for _, name in pairs(data.AltNames) do
			registerUnit(name)
		end
	end
end

local function NiceConcat(tab)
	if (#tab > 1) then
		return table.concat(tab, ", ", 1, #tab - 1) .. " et " .. tab[#tab]
	elseif (#tab == 1) then
		return tab[1]
	else
		return ""
	end
end

local function FormatTime(seconds, depth)
	if (type(seconds) ~= "number") then
		return seconds
	end

	local units = timeUnits
	local lastUnit = units[#units]
	if (seconds < lastUnit.Seconds) then
		return "zéro " .. (lastUnit.NameSingular or lastUnit.NamePlural)
	end

	depth = depth or 0

	local txt = {}
	for k, v in pairs(units) do
		if (seconds >= v.Seconds) then
			local count = math.floor(seconds / v.Seconds)
			seconds = seconds - count * v.Seconds
			if (count > 1) then
				table.insert(txt, count .. " " .. v.NamePlural)
			else
				table.insert(txt, v.One .. " " .. (v.NameSingular or v.NamePlural))
			end

			if (depth > 0) then
				depth = depth - 1
				if (depth < 1) then
					break
				end
			end
		end
	end

	return NiceConcat(txt)
end

return {
	FormatTime = FormatTime,
	NiceConcat = NiceConcat,
	Locs = {
		GLOBAL_DEFAULT_REASON                     = "Aucune raison donnée.",

		BOT_HELP_HELP                             = "Affiche la liste des commandes.",
		BOT_HELP_NEXT_BUTTON_LABEL                = "Page Suivante",
		BOT_HELP_PREV_BUTTON_LABEL                = "Page Précédente",

		CLEAN_URLS_NO_RULE_PROVIDED               = "Aucune règle fournie",
		CLEAN_URLS_NO_RULES_PROVIDED              = "Aucune règles fournies",
		CLEAN_URLS_RULE_ADDED                     = "Règle ajoutée : `%s`",
		CLEAN_URLS_RULES_ADDED                    = "Règles ajoutées : %s",
		CLEAN_URLS_RULE_REMOVED                   = "Règle supprimée : `%s`",
		CLEAN_URLS_RULES_REMOVED                  = "Règles supprimées : %s",
		CLEAN_URLS_RULES_CLEARED                  = "Toutes les règles ont été supprimées",
		CLEAN_URLS_RULES_HEADER                   = "Règles",
		CLEAN_URLS_WRONG_USER_BUTTON              = "Ce bouton n'est pas pour vous !",
		CLEAN_URLS_DELETED_MESSAGE                = "Message supprimé",
		CLEAN_URLS_DELETE_BUTTON_LABEL            = "Supprimer",
		CLEAN_URLS_NO_RULES                       = "Aucune règle",
		CLEAN_URLS_AUDITLOG                       = "Nettoyage des liens",

		MODMAIL_CLOSETICKET                       = "Fermer le ticket",
		MODMAIL_TICKETCLOSE_MESSAGE               = "%s a fermé le ticket, ce canal sera automatiquement supprimé %s",
		MODMAIL_TICKETOPENING_MESSAGE             =
		"Bonjour %s, vous pouvez communiquer avec la modération de **%s** via ce canal privé.",
		MODMAIL_TICKETOPENING_MESSAGE_MODERATION  = "Bonjour %s, la modération de **%s** souhaite s'entretenir avec vous.",
		MODMAIL_TICKETMESSAGE                     = "Message associé :",
		MODMAIL_LEFTSERVER                        = "%s a quitté le serveur",
		MODMAIL_NOTACTIVETICKET                   = "Vous ne pouvez effectuer cette action que dans un ticket actif, %s.",
		MODMAIL_NOTAUTHORIZED                     = "Vous n'avez pas la permission de faire ça, %s.",
		MODMAIL_TICKETCLOSED_CONFIRMATION         = "✅ Ticket fermé.",
		MODMAIL_OPENTICKET_BUTTON_LABEL           = "Ouvrir un ticket avec la modération...",
		MODMAIL_FORM_TITLE                        = "Ouvrir un ticket avec la modération",
		MODMAIL_FORM_DESCRIPTION_LABEL            = "Décrivez en quelques mots votre demande :",
		MODMAIL_OPENTICKET_FORBIDDEN              = "Ouvrir un ticket sur ce serveur vous est interdit.",
		MODMAIL_OPENTICKET_NOTALLOWED             = "Vous n'avez pas la permission d'ouvrir un ticket sur ce serveur.",
		MODMAIL_OPENTICKET_NOTALLOWED_OTHERMEMBER =
		"Vous n'avez pas la permission d'ouvrir un ticket pour un autre membre sur ce serveur.",
		MODMAIL_TICKEDOPENED                      = "✅ Un ticket de modération a bien été ouvert : %s.",

		MUTE_ERROR_NOT_PART_OF_GUILD              = "%s n'est pas sur le serveur",
		MUTE_GUILD_MESSAGE                        = "%s a rendu muet %s%s%s",
		MUTE_MUTE_FAILED                          = "❌ impossible de rendre muet %s : %s",
		MUTE_NOTAUTHORIZED                        = "❌ Vous ne pouvez rendre ce membre muet à cause de vos permissions",
		MUTE_PRIVATE_MESSAGE                      = "Vous avez été rendu muet sur **%s** par %s%s%s",
		MUTE_REASON                               = "pour la raison suivante : %s",
		MUTE_THEY_WILL_BE_UNMUTED_IN              = "Ce membre pourra reparler %s",
		MUTE_UNMUTE_FAILED                        = "❌ impossible de rendre la parole à %s : %s",
		MUTE_UNMUTE_GUILD_MESSAGE                 = "%s a rendu la parole à %s%s",
		MUTE_UNMUTE_MESSAGE                       = "La parole vous a été rendue sur **%s** par %s%s",
		MUTE_YOU_WILL_BE_UNMUTED_IN               = "La parole vous sera rendue %s",

		RAID_LOCKSERVER_HELP                      = "Verrouille le serveur afin d'empecher les gens de rejoindre",
		RAID_LOCKSERVER_ALREADY_LOCKED            = "Le serveur est déjà verrouillé",
		RAID_LOCKSERVER_LOCKED_BY                 = "verrouillé par %s",
		RAID_UNLOCKSERVER_HELP                    = "Déverouille le serveur",
		RAID_UNLOCKSERVER_NOT_LOCKED              = "Le serveur n'est pas verrouillé",
		RAID_UNLOCKSERVER_LOCKED_BY               = "déverrouillé par %s",
		RAID_RULEHELP_HELP                        = "Liste les differentes règles possibles",
		RAID_RULEHELP_FIELDS_VALUE                = "**Description:** %s\n**Paramètre:** %s",
		RAID_RULEHELP_TITLE                       = "Listes des règles anti-raid disponibles",
		RAID_RULEHELP_DESCRIPTION                 =
		"Voici la liste des règles disponibles dans le module de raid.\n\nVous pouvez les utiliser avec la commande `!addrule <effet> <règle> <param>`.\n\nListe des effets disponibles:\n%s",
		RAID_ADDRULE_HELP                         = "Ajoute une règle sur les nouveaux membres",
		RAID_ADDRULE_INVALID_EFFECT               = "Effet invalide (valeurs possibles: %s)",
		RAID_ADDRULE_INVALID_RULE                 = "Règle invalide (Utilisez `!rulehelp` afin de voir les règles valides)",
		RAID_ADDRULE_INVALID_RULE_PARAMETERS      = "Paramètre(s) de règle invalide(s): %s",
		RAID_ADDRULE_ADDED                        = "Règle ajoutée en tant que règle n°%s",
		RAID_ALERT_SERVER_LOCKED_UNITL            = "🔒 Le seveur a été verrouillé et sera déverrouillé %s (%s)",
		RAID_ALERT_SERVER_UNLOCKED                = "🔓 Le serveur a été deverrouillé (%s)",
		RAID_LOCK_EXPIRATION                      = "verrouillage expiré",
		RAID_CLEARRULES_HELP                      = "Supprime toutes les règles anti-raid",
		RAID_CLEARRULES_DONE                      = "Les règles ont bien été supprimées",
		RAID_DELRULE_HELP                         = "Supprimes une règle par son n°",
		RAID_DELRULE_OUTOFRANGE                   = "N° de règle invalide",
		RAID_DELRULE_DONE                         = "La règle n°%s a été supprimée",
		RAID_LISTRULES_HELP                       = "Listes les règles anti-raid",
		RAID_LISTRULES_RULE_TITLE                 = "Règle n°%s",
		RAID_LISTRULES_RULE_DETAIL                = "**Règle:** %s**\nConfiguration: %s**\n**Effet:** %s",
		RAID_LISTRULES_TITLE                      = "Liste des règles anti-raid du server",
		RAID_HANDLERULE_WHITELIST                 = "%s a été autorisé à rejoindre (whitelist)",
		RAID_HANDLERULE_RULE                      = "la règle %d - %s(%s)",
		RAID_HANDLERULE_AUTHORIZE                 = "%s a été autorisé à rejoindre en raison de %s",
		RAID_HANDLERULE_BAN_MSG                   = "auto-ban en raison de %s",
		RAID_HANDLERULE_BAN_LOG                   = "%s a été banni en raison de %s",
		RAID_HANDLERULE_KICK_MSG                  = "auto-kick en raison de %s",
		RAID_HANDLERULE_KICK_LOG                  = "%s a été expulsé en raison de %s",
		RAID_AUTOKICK_REASON                      = "Serveur verrouillé",
		RAID_AUTOLOCK_REASON                      = "Verouillage automatique par le système anti-raid",
		RAID_AUTOBAN_BOT_REASON                   = "auto-ban pour soupçon de bot",
		RAID_AUTOMUTE_SPAM_REASON                 = "🙊 %s a été auto-mute à cause de spam dans %s",

		PIN_PIN_HELP                              = string.format("%s\n%s\n\t%s",
			"Épingle un message.",
			"Arguments:",
			"messageId: Le lien du message à épingler"
		),
		PIN_PIN_ERROR                             = "❌ Impossible d'épingler ce message.",
		PIN_UNPIN_HELP                            = string.format("%s\n%s\n\t%s",
			"Désépingle un message",
			"Arguments:",
			"messageId: Le lien du message à désépingler"
		),
		PIN_UNPIN_ERROR                           = "❌ Impossible de désépingler ce message.",

		PRUNEFROM_HELP                            = string.format("%s\n%s\n\t%s",
			"Supprime tous les messages à partir de celui dont l'identifiant a été passé en paramètre.",
			"Arguments:",
			"messageId: L'identifiant du message"
		),
		PRUNE_CANNOT_DELETE                       = "ℹ️ Certains messages n'ont pas pu être supprimés.",
		PRUNE_HELP                                = string.format("%s\n%s\n\t%s",
			"Supprime les n derniers messages.",
			"Arguments:",
			"nbMessages: Le nombre de messages à supprimer"
		),
		PRUNE_RESULT                              = "🧹 %d messages ont été supprimés.",

		VOICE_CHAN_PREFIX                         = "Vocal Privé - ",
		VOICE_CONFIRM                             = "Ces membres peuvent maintenant rejoindre le vocal.",
		VOICE_INTERAC_PLACEHOLDER                 = "Maximum 25 membres.",
		VOICE_MISCONFIG                           = "La clé de configuration 'TriggerChannel' n'a pas été initialisée pour le module 'voice'.",
		VOICE_MSG                                 = "Inviter des membres à rejoindre ce canal:",

		WARN_CLEARWARNS_CLEARED                   = "Les avertissements de %s (%s) ont été effacés.",
		WARN_CLEARWARNS_HELP                      = "Efface tous les avertissements de l'utilisateur spécifié.",
		WARN_NO_WARNS                             = "L'utilisateur %s (%s) n'a aucun avertissement.",
		WARN_WARN_BAN_REACHED                     = "Le membre %s (%s) a suffisament d'avertissements pour être banni (%d avertissements).",
		WARN_WARN_HELP                            = "Avertit un membre.",
		WARN_WARN_MSG                             = "%s a averti %s (avertissement #%d) pour la raison suivante: %s",
		WARN_WARN_MUTE_REACHED                    =
		"Le membre %s (%s) a suffisamment d'avertissements pour être silencié (%d avertissements) %s secondes.",
		WARN_WARN_PERMISSION_DENIED               = "Vous ne pouvez pas avertir ce membre à cause de vos permissions insuffisantes.",
		WARN_WARN_PM                              = "Vous avez reçu un avertissement sur %s pour la raison suivante: %s",
		WARN_WARNLIST_HELP                        = "Affiche tous les avertissements d'un utilisateur.",
		WARN_WARNLIST_ITEM                        = "\nAverti par %s pour la raison suivante: %s",
		WARN_WARNLIST_LIST                        = "Avertissements de %s (%s):",
	}
}
