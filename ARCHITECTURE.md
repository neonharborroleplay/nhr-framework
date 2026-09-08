# NHR architecture

## Design rules

1. The server owns money, inventory, permissions, jobs, vehicles, property, health,
   and all durable state.
2. Clients request actions; they never write database rows directly.
3. Resources communicate through `nhr_*` exports and events, not framework bridges.
4. Every persistent feature uses the `nhr_` SQL namespace.
5. Resource boundaries follow gameplay ownership, allowing individual NHR systems to
   be upgraded without replacing the core.

## Runtime layers

- Foundation: `nhr_core`, `nhr_logs`, `nhr_security`, `nhr_health`
- Player session: `nhr_multichar`, `nhr_spawn`, `nhr_status`, `nhr_hud`
- Identity: `nhr_appearance`, `nhr_cityhall`, `nhr_phone`
- Economy: `nhr_inventory`, `nhr_shops`, `nhr_banking`, `nhr_economy`, `nhr_billing`
- Vehicles: `nhr_vehicles`, `nhr_vehiclekeys`, `nhr_fuel`, `nhr_garages`,
  `nhr_dealership`, `nhr_vehiclemarket`, `nhr_customs`
- Careers and services: `nhr_jobs`, `nhr_management`, `nhr_police`, `nhr_ambulance`,
  `nhr_dispatch`, `nhr_evidence`, `nhr_mdt`, `nhr_drivingschool`
- World and property: `nhr_world`, `nhr_doorlocks`, `nhr_housing`, `nhr_businesses`
- Activities and social: `nhr_crafting`, `nhr_robberies`, `nhr_trade`, `nhr_radio`,
  `nhr_weapons`, `nhr_chat`, `nhr_emotes`, `nhr_scoreboard`
- Operations: `nhr_admin`

## Public identity

The canonical core export is:

```lua
local NHR = exports.nhr_core:GetCoreObject()
local runtime = exports.nhr_core:GetRuntimeInfo()
```

Character IDs use the configurable `NHRConfig.CharacterIdPrefix`. The default is
`NHR`, producing IDs such as `NHR4FA02C19`.
