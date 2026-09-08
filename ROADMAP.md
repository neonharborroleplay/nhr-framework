# NHR build roadmap

## Foundation (implemented)

- Character/account schema, multicharacter, player lifecycle
- Money accounts, metadata, multi-job and multi-gang data
- Saved position, spawning, exports, ACE admin foundation

## Playable server layer (next)

- `nhr_inventory`: slots, weight, metadata, usable items, persistence and drops
  (implemented), including dual-pane stashes, trunks and gloveboxes
- `nhr_shops`: proximity-validated convenience and hardware stores (implemented)
- `nhr_hud`: health, armor, hunger, thirst, stress, speed, fuel and voice state (implemented)
- `nhr_banking`: ATMs, deposits, withdrawals, transfers and statements (implemented);
  society accounts and history are implemented in `nhr_management`
- `nhr_vehicles`, `nhr_dealership`, `nhr_garages`, `nhr_vehiclekeys`, `nhr_fuel`
  (implemented), including financing, private sales, fuel stations and vehicle inventory
- `nhr_status`: needs decay and death persistence (implemented); consumables and
  hospital respawn, body-part injuries and a configurable last-stand phase are implemented
- `nhr_jobs`, `nhr_management`, and `nhr_cityhall` (implemented)

## Roleplay systems

- Police restraints, evidence, jail and dispatch are implemented
- MDT citizen/vehicle search, reports, citations and warrants are implemented
- EMS treatment, body-part injuries, revival and hospital respawn are implemented
- Housing purchase/resale, seven-day leases, shared property keys/storage, synchronized
  furniture and door locks are implemented
- Phone, contacts, messages, live pma-voice calls, a dedicated phone NUI, and
  police/EMS/taxi/tow service request apps are implemented
- Shops, timed crafting, robberies, financing, laundering and basic economy balancing are implemented
- Businesses, invoices, player trading, weapon licensing, dealer stock, radio channels,
  service requests, and crafting progression are implemented
- Business lifecycle controls, bank/society statements, private vehicle sales,
  centralized logs, abuse throttles, and server health checks are implemented
- City Hall documents/job switching, property key sharing, voice HUD state, invoice
  history, citation notifications, history and payment are implemented
- Nearby document presentation, two-stage incapacitation/bleedout, property resale,
  and persistent allowlisted interior furniture are implemented
- Sequential server-validated driving exams, license replacement, recurring lease
  renewal/expiration, eviction and stale-key cleanup are implemented
- Admin menu, reports, audit log and moderation tools

Each milestone is versioned independently so servers can update individual NHR
resources without replacing the core.

## Post-roadmap expansion

- Server-authoritative clock, weather cycle, blackout state and world density controls
- Proximity IC chat, `/me`, `/do`, rate-limited global `/ooc`, and chat suggestions
- Hold-to-view player scoreboard with police, EMS and staff availability counts
- Allowlisted animation/scenario emotes with menu, command and cancellation key
