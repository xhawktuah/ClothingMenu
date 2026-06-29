-- Updated ServerScript: HumanoidDescription fallback improved
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("ClothingConfig"))

local remoteFolder = ReplicatedStorage:FindFirstChild("ClothingRemotes")
local OpenShopEvent = remoteFolder:FindFirstChild("OpenShop")
local SaveOutfitEvent = remoteFolder:FindFirstChild("SaveOutfit")
local RequestEquipEvent = remoteFolder:FindFirstChild("RequestEquip")
local RequestPreviewAssetsEvent = remoteFolder:FindFirstChild("RequestPreviewAssets")
local NotifyClientEvent = remoteFolder:FindFirstChild("NotifyClient")

local outfitsStore = DataStoreService:GetDataStore(Config.DataStoreName)
local assetsRoot = ReplicatedStorage:FindFirstChild("ClothingAssets") or Instance.new("Folder", ReplicatedStorage); assetsRoot.Name = "ClothingAssets"

-- Helper: try to apply HumanoidDescription using available asset IDs
local function applyHumanoidDescription(character, mappingTable)
    -- mappingTable expected: {Shirts = index, Pants = index, Hats = index, Glasses = index, Shoes = index}
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local hd = Instance.new("HumanoidDescription")
    local applied = false

    local function setIfAvailable(category, propName)
        local list = Config[category]
        local idx = mappingTable[category]
        if list and idx and list[tonumber(idx)] and list[tonumber(idx)].AssetId and list[tonumber(idx)].AssetId > 0 then
            local aid = list[tonumber(idx)].AssetId
            -- many HumanoidDescription properties expect either string or number; set as string where appropriate
            pcall(function()
                hd[propName] = tostring(aid)
                applied = true
            end)
        end
    end

    -- Shirts / Pants
    setIfAvailable("Shirts", "Shirt")
    setIfAvailable("Pants", "Pants")

    -- Accessories: try multiple accessory properties
    setIfAvailable("Hats", "HatAccessory")
    setIfAvailable("Glasses", "FaceAccessory") -- glasses sometimes considered face
    setIfAvailable("Glasses", "FrontAccessory")
    setIfAvailable("Glasses", "HairAccessory")
    setIfAvailable("Shoes", "WaistAccessory") -- shoes mapping is not standard; keep safe

    if applied then
        local ok, err = pcall(function()
            humanoid:ApplyDescription(hd)
        end)
        if not ok then
            warn("Failed to apply HumanoidDescription fallback:", err)
            return false
        end
        return true
    end
    return false
end

-- RequestEquipEvent listener uses both direct asset parenting and fallback
RequestEquipEvent.OnServerEvent:Connect(function(player, outfitTable)
    if type(outfitTable) ~= "table" then return end
    local character = player.Character
    if not character or not character.Parent then return end

    -- Try to apply preloaded assets first
    local function tryApplyFromAssets(categoryName, index)
        local list = Config[categoryName]
        if not list or not tonumber(index) then return false end
        local item = list[tonumber(index)]
        if not item or item.AssetId == 0 then return false end
        local categoryFolder = assetsRoot:FindFirstChild(categoryName)
        if not categoryFolder then return false end
        local safeName = item.Name:gsub("%W", "_")
        local itemFolder = categoryFolder:FindFirstChild(safeName)
        if not itemFolder then return false end

        for _, c in ipairs(itemFolder:GetChildren()) do
            local clone = c:Clone()
            clone.Name = "Shop_" .. tostring(clone.Name)
            if clone:IsA("Accessory") then
                clone.Parent = character
            elseif clone:IsA("Shirt") then
                for _, old in ipairs(character:GetChildren()) do if old:IsA("Shirt") then old:Destroy() end end
                clone.Parent = character
            elseif clone:IsA("Pants") then
                for _, old in ipairs(character:GetChildren()) do if old:IsA("Pants") then old:Destroy() end end
                clone.Parent = character
            else
                clone.Parent = character
            end
        end
        return true
    end

    local successDirect = false
    pcall(function()
        if outfitTable.Shirts and tryApplyFromAssets("Shirts", outfitTable.Shirts) then successDirect = true end
        if outfitTable.Pants and tryApplyFromAssets("Pants", outfitTable.Pants) then successDirect = true end
        if outfitTable.Hats and tryApplyFromAssets("Hats", outfitTable.Hats) then successDirect = true end
        if outfitTable.Glasses and tryApplyFromAssets("Glasses", outfitTable.Glasses) then successDirect = true end
        if outfitTable.Shoes and tryApplyFromAssets("Shoes", outfitTable.Shoes) then successDirect = true end
    end)

    if not successDirect then
        -- fallback to HumanoidDescription approach to cover clothing types that are better applied via description
        local applied = applyHumanoidDescription(character, outfitTable)
        if applied then
            -- notify client of success
            if NotifyClientEvent then
                pcall(function() NotifyClientEvent:FireClient(player, {Type = "Success", Message = "Equipped outfit (via avatar description)."}) end)
            end
        else
            if NotifyClientEvent then
                pcall(function() NotifyClientEvent:FireClient(player, {Type = "Error", Message = "Failed to equip outfit."}) end)
            end
        end
    else
        if NotifyClientEvent then
            pcall(function() NotifyClientEvent:FireClient(player, {Type = "Success", Message = "Equipped outfit."}) end)
        end
    end
end)

-- Helper to load outfits for player (used when client requests preview assets)
local function loadOutfitsForPlayer(player)
    local key = "outfit_slots_" .. player.UserId
    local data
    local ok, err = pcall(function()
        data = outfitsStore:GetAsync(key)
    end)
    if not ok then
        warn("Failed to load outfits for", player.Name, err)
        return {}
    end
    return data or {}
end

-- RequestPreviewAssetsEvent returns metadata incl saved outfits
RequestPreviewAssetsEvent.OnServerEvent:Connect(function(player)
    local function listForCategory(categoryName, configList)
        local out = {}
        for i, item in ipairs(configList) do
            table.insert(out, {Index = i, Name = item.Name, AssetId = item.AssetId, Loaded = (assetsRoot:FindFirstChild(categoryName) and assetsRoot[categoryName]:FindFirstChild(item.Name:gsub('%W','_'))) and true or false})
        end
        return out
    end

    local payload = {
        Shirts = listForCategory("Shirts", Config.Shirts),
        Pants  = listForCategory("Pants", Config.Pants),
        Hats   = listForCategory("Hats", Config.Hats),
        Glasses= listForCategory("Glasses", Config.Glasses),
        Shoes  = listForCategory("Shoes", Config.Shoes),
        OutfitSlots = Config.OutfitSlots,
        SavedOutfits = loadOutfitsForPlayer(player)
    }

    if OpenShopEvent then
        pcall(function() OpenShopEvent:FireClient(player, payload) end)
    end
end)

print("ClothingServer (enhanced) running")
