NHRInventory = {}
NHRInventory.PlayerSlots = 40
NHRInventory.PlayerWeight = 30000
NHRInventory.DropSlots = 20
NHRInventory.DropWeight = 50000
NHRInventory.DropDistance = 2.5
NHRInventory.DropLifetime = 30 * 60 * 1000
NHRInventory.TrunkSlots, NHRInventory.TrunkWeight = 40, 120000
NHRInventory.GloveboxSlots, NHRInventory.GloveboxWeight = 10, 10000

NHRInventory.Items = {
    water = { label = 'Water', weight = 500, stack = true, usable = true, description = 'A bottle of water.' },
    sandwich = { label = 'Sandwich', weight = 350, stack = true, usable = true, description = 'A simple sandwich.' },
    phone = { label = 'Phone', weight = 250, stack = false, usable = true, description = 'A personal smartphone.' },
    id_card = { label = 'ID Card', weight = 10, stack = false, usable = true, description = 'Government identification.' },
    driver_license = { label = 'Driver License', weight = 10, stack = false, usable = true, description = 'A state-issued driving credential.' },
    bandage = { label = 'Bandage', weight = 150, stack = true, usable = true, description = 'Treats minor injuries.' },
    repairkit = { label = 'Repair Kit', weight = 2500, stack = true, usable = true, description = 'Basic vehicle repair tools.' },
    radio = { label = 'Radio', weight = 400, stack = false, usable = true, description = 'A handheld radio.' },
    lockpick = { label = 'Lockpick', weight = 100, stack = true, usable = true, description = 'A fragile lockpick.' },
    evidence_bag = { label = 'Evidence Bag', weight = 100, stack = false, usable = false, description = 'Sealed police evidence.' },
    marked_bills = { label = 'Marked Bills', weight = 0, stack = true, usable = false, description = 'Cash with recorded serial numbers.' },
    metal = { label = 'Metal', weight = 500, stack = true, usable = false, description = 'Crafting material.' },
    plastic = { label = 'Plastic', weight = 250, stack = true, usable = false, description = 'Crafting material.' },
    electronics = { label = 'Electronics', weight = 200, stack = true, usable = false, description = 'Electronic components.' },
    weapon_pistol = { label = 'Pistol', weight = 1200, stack = false, usable = true, description = 'A serialized handgun.' },
    pistol_ammo = { label = 'Pistol Ammunition', weight = 15, stack = true, usable = true, description = '9mm cartridges.' }
}
