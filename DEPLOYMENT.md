# NHR deployment runbook

## Prerequisites

- A current FiveM FXServer/txAdmin installation with OneSync enabled
- MariaDB or MySQL with a dedicated database and restricted application user
- `oxmysql`, `ox_lib`, `ox_target`, `spawnmanager`, `chat`, and `pma-voice`

## Fresh installation

1. Back up the server configuration and database.
2. Import `resources/[nhr]/nhr_core/sql/nhr.sql` into the NHR database.
3. Copy `resources/[nhr]` into the server resources directory.
4. Set the real database credentials in the `mysql_connection_string`.
5. Merge `server.cfg.example` without changing its dependency order.
6. Configure ACE administrators and remove the example identifier.
7. Optionally configure the server-only webhook in `nhr_logs/config.lua`.
8. Start the server and run `nhrhealth` in the server console.

## Upgrade installation

1. Stop the server and take a database backup.
2. Replace the NHR resource folders while preserving intentional config changes.
3. Do not re-import the full schema. `nhr_core` applies pending versioned migrations.
4. Start the server and confirm `migrations=true` in the `nhrhealth` output.

## Acceptance checklist

- Create and load two test characters, reconnect, and verify persistence.
- Deposit, withdraw, transfer, and inspect personal bank statements.
- Buy a vehicle, store/retrieve it, finance one, and complete a private sale.
- Buy a business, toggle it open, deposit society funds, inspect history, hire/fire,
  and sell it back to the city.
- Replace an ID, obtain a driver license, switch an existing job, and use both documents.
- Complete every driving-school checkpoint, damage/abandon the exam vehicle to verify
  failure, and confirm City Hall only replaces an existing driver license.
- Use `/showid` and `/showlicense` to present documents to a nearby character.
- Buy a property, grant/revoke a key, and confirm both characters enter the same instance
  and see the same storage.
- Place/remove furniture with `/furnish`, verify live synchronization, reconnect, then
  sell the property and confirm keyholders are safely evicted.
- Start and renew a seven-day lease, end it manually, and test expiration on staging by
  temporarily shortening its database due date; confirm keys and occupants are removed.
- Send/pay an invoice and confirm both personal and society transaction entries.
- Issue/pay a citation and confirm personal and police society transaction entries.
- Trade a metadata-bearing item and verify its metadata survives the transfer.
- Join public and emergency radio channels; remove the radio and confirm disconnect.
- Test phone calls and police/EMS/taxi/tow service requests.
- Confirm time/weather synchronization with two clients, then test the ACE-restricted
  `/time`, `/weather`, and `/blackout` commands from staff and non-staff accounts.
- Verify proximity chat range, `/me`, `/do`, `/ooc`, HOME scoreboard counts, `/emotes`,
  `/e <name>`, and the `X` emote-cancel binding.
- Test last stand, unconscious bleedout, EMS revival in both stages, and hospital respawn.
- Confirm an admin action and a large transfer appear in `nhr_audit_logs`.
- Restart the server and verify stored state, stock, ownership, and migrations remain.

## Operations

- Keep `nhr_logs/config.lua` private because it may contain a webhook secret.
- Review `nhr_audit_logs`, security alerts, and the FXServer console regularly.
- Tune `nhr_security/config.lua` for custom weapons or permitted server vehicles.
- Test resource/config updates on a staging server before production rollout.
