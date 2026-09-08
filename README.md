# NHR Framework

NHR is an independently designed, modular FiveM roleplay platform for Neon Harbor.
It has its own player lifecycle, API namespace, events, persistence schema, security
model, resources, and user interfaces. It contains no copied framework resources and
ships without a QB/Qbox compatibility bridge.

## Included framework layers

- `nhr_core`: player lifecycle, multicharacter storage, accounts, metadata,
  multi-job/multi-gang membership, permissions, callbacks, and exports
- `nhr_multichar`: character selection and creation using ox_lib
- `nhr_spawn`: saved-position and first-spawn handling
- `nhr_banking`: secure deposits, withdrawals, online transfers, and ATMs
- `nhr_status`: persistent hunger, thirst, and death state
- `nhr_inventory`: persistent slots, weight, metadata, usable items, starter items,
  world drops, exports, and inventory NUI
- `nhr_shops`: server-priced stores with cash/bank checkout and capacity checks
- `nhr_vehicles`, `nhr_dealership`, `nhr_garages`, `nhr_vehiclekeys`, `nhr_fuel`:
  persistent ownership, purchases, storage, locks, and fuel consumption
- `nhr_hud`: health, armor, needs, stress, speed, and fuel display
- Vehicle trunks/gloveboxes, paid fuel stations, police impounds, hospital respawn,
  starvation/dehydration damage, and server-side revive export
- Job center, validated duty points, paychecks, society accounts, boss actions,
  dispatch, police cuffs/jail/panic, and EMS treatment/revival
- Persistent firearm-casing evidence with on-duty police collection bags
- ACE admin actions, player reports, permanent/temporary bans, and SQL audit logs
- Persistent job-secured door locks, purchasable instanced apartments with private
  storage, and a native full freemode character studio with heritage, facial sculpting,
  overlays, hair, clothing, props, live camera preview, stores, and saved appearance
- Phone numbers, contacts and messages; police MDT; timed crafting; alerted store
  robberies; vehicle loans; marked-bill exchange; and configurable wealth tax
- Live pma-voice phone calls, police search/escort/citations/warrants, EMS body-part
  injuries, dealership test drives, and owner-only vehicle repair/customization
- Versioned startup migrations for incremental NHR database upgrades
- Purchasable businesses, society invoices, metadata-safe player trades, service
  requests, secured pma-voice radios, weapon licensing, dealer stock, and crafting XP
- Business open/close and resale controls, personal and society statements, secure
  private vehicle sales, centralized audit/webhook logs, event throttling, entity and
  abnormal-damage guards, and boot-time dependency/database health checks
- City Hall identification and driver licenses, multi-job switching, shared property
  keys/instances/storage, live voice HUD state, invoice history, and payable citations
- Two-stage last stand/bleedout with server-locked recovery, nearby document sharing,
  property resale, and persistent synchronized interior furniture
- Server-validated driving exams with license issuance/replacement separation, plus
  seven-day property leases with renewal, expiration, eviction and key cleanup
- Synchronized server time/weather/blackouts and population density, proximity IC/RP
  chat, HOME scoreboard, emergency-service counts, and allowlisted cancellable emotes
- SQL schema and server configuration template

## Dependencies

- `oxmysql`
- `ox_lib`
- `ox_target`
- `pma-voice`
- FiveM stock `spawnmanager` and `chat` resources

NHR deliberately keeps external dependencies narrow. Gameplay state remains owned by
NHR resources rather than an external framework compatibility layer.

## Install

For a fresh txAdmin deployment, publish this folder to GitHub and follow
`txadmin/README.md`. The recipe downloads the required dependencies, creates and
imports the database, installs all NHR resources, and writes the final `server.cfg`.

For a manual installation:

1. Import `resources/[nhr]/nhr_core/sql/nhr.sql`.
2. Put the `[nhr]` folder in your server's `resources` directory.
3. Merge `server.cfg.example` into your server configuration.
4. Start the server and create a character.

Set `NHRLogs.Webhook` in `nhr_logs/config.lua` if Discord-compatible webhook delivery
is wanted. Leave it empty to retain SQL-only audit logging. Run `nhrhealth` from the
server console to verify the database, migrations, and required resources. Follow
`DEPLOYMENT.md` for fresh installs, upgrades, and the acceptance-test checklist.

## Common controls

- Hold `HOME` for the scoreboard
- `/me`, `/do`, and `/ooc` for roleplay chat
- `/emotes`, `/e <name>`, or `X` to browse, play, or cancel emotes
- Admins: `/time <hour> <minute>`, `/weather <type>`, and `/blackout`

## Server API

```lua
local player = exports.nhr_core:GetPlayer(source)
player.Functions.AddMoney('bank', 500, 'paycheck')
player.Functions.SetPrimaryGroup('job', 'police', 1)

local playerById = exports.nhr_core:GetPlayerByCitizenId('NHRA1B2C3D4')
```

Every state mutation is server-authoritative. Other resources should use exports
and events instead of querying or updating character rows directly.
