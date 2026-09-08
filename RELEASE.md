# NHR Framework 1.0.0

This is the first clean NHR distribution.

## Included

- 45 NHR-native resources
- 155 Lua source/manifest/configuration files
- Four custom NUI applications
- Complete fresh-install SQL schema and incremental migration runner
- Manual and txAdmin deployment configurations
- Server-authoritative economy, inventory, identity, vehicle, property, job,
  emergency-service, communications, activity, moderation, and security layers
- Native NHR Character Studio with saved appearance, camera focus modes, clothing and
  tattoo shop map locations, overlay editing, props, and clothing components

## Namespace contract

- Resources: `nhr_*`
- Events: `nhr_resource:side:event`
- SQL tables and indexes: `nhr_*`
- State bags: `nhr*`
- ACE permissions: `nhr.admin` and `nhr.mod`
- Character identifiers: configurable `NHR` prefix

## Validation

- All Lua files pass parser validation with FiveM hash literals normalized for the
  parser.
- All NUI JavaScript passes syntax validation.
- Every resource has a manifest and is started by `txadmin/server.cfg`.
- All local manifest dependencies resolve to an included NHR resource.
- No Qbox/QBCore resource names, events, exports, schema names, or compatibility
  bridge are present in the runtime distribution.
