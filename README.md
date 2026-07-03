# Not a Bot

Source code of the bot of the french programming discord server NaN (Not a Name).  https://discord.gg/zcWp9sC

## Requirements

- [Luvit](https://luvit.io/) runtime

## Configuration

The bot reads its config from `config.lua`, which is git-ignored (don't commit your token).

1. Copy the default config:

   ```bash
   cp config.lua.default config.lua
   ```

2. Edit `config.lua` and set at minimum:
   - `Token` — your Discord bot token, from the [Discord Developer Portal](https://discord.com/developers/applications) (Bot tab > Reset/Copy Token).
   - `OwnerUserId` — your Discord user ID (enable Developer Mode in Discord, right-click your name, "Copy ID").

For development, create a separate test bot application in the Discord Developer Portal and invite it to a private test server. Use that bot's token in your local `config.lua` so you don't run code against the production bot/server.

### Gateway intents

The bot requests all gateway intents except `guildIntegrations` (see `bot.lua`). Two of these are privileged and must be enabled manually in the Developer Portal (Bot tab) for your application, or the bot will fail to connect:

- **Server Members Intent** (`guildMembers`)
- **Presence Intent** (`guildPresences`)

`AutoloadModules` lists which `module_*.lua` files load at startup — trim it while developing to only the module(s) you're working on, to reduce noise and side effects.

## Running the bot

```bash
luvit bot.lua
```
