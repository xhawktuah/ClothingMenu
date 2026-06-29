-- ClothingConfig (ModuleScript)
-- Place this ModuleScript in ReplicatedStorage and name it "ClothingConfig"

local Config = {}

-- Editable button sizing variables (change these to resize all UI buttons)
Config.ButtonWidth  = UDim.new(0, 120)    -- example: UDim.new(scale, offset)
Config.ButtonHeight = UDim.new(0, 36)
Config.CornerRadius  = UDim.new(0, 20)
Config.Padding       = 8

-- NPC settings
Config.NPCName = "Clothes Vendor" -- change the NPC name as you like

-- Spawn points folder name in workspace (persistent placement)
Config.NPCSpawnFolder = "ClothingNPCSpawns"

-- Number of outfit slots per player (multi-slot outfits)
Config.OutfitSlots = 6

-- Clothing asset placeholders (edit AssetId values to the real asset IDs)
-- For each item set Name and AssetId. AssetId = 0 means "not configured".
Config.Shirts = {
    {Name = "Classic Tee", AssetId = 0},
    {Name = "Leather Jacket", AssetId = 0},
}

Config.Pants = {
    {Name = "Denim Jeans", AssetId = 0},
    {Name = "Cargo Pants", AssetId = 0},
}

Config.Hats = {
    {Name = "Baseball Cap", AssetId = 0},
    {Name = "Fedora", AssetId = 0},
}

Config.Glasses = {
    {Name = "Aviators", AssetId = 0},
    {Name = "Futuristic Shades", AssetId = 0},
}

Config.Shoes = {
    {Name = "Sneakers", AssetId = 0},
    {Name = "Loafers", AssetId = 0},
}

-- DataStore keys
Config.DataStoreName = "PremiumClothingOutfits_v1" -- change only if needed

-- Marketplace product type mapping (if you prefer Developer Products, set here)
Config.UseAssetPurchases = true -- if true we use AssetId and PromptPurchase

return Config
