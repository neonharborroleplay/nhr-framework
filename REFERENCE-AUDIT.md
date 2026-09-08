# Harbor reference audit

The Harbor archive was inspected only to establish expected server coverage and
deployment shape. No Qbox resource, source file, SQL schema, UI, configuration block,
or compatibility bridge is included in NHR.

## Reference coverage observed

- Character/core lifecycle and spawning
- Inventory and target dependencies
- Appearance and identity
- Police, medical, management, and administration
- Vehicles, garages, dealerships, keys, and fuel
- Properties, doors, banking, phone, voice, and weather
- Civilian jobs, robberies, crafting, drugs, racing, and other activities

## NHR approach

NHR implements those domains through its own 40-resource suite and `nhr_` contracts.
Optional activity packs such as dedicated bus, taxi, tow, garbage, diving, farming,
and racing loops can be added as NHR-native modules without changing `nhr_core`.
