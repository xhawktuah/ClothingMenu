-- ClothingServer (Script)
-- Place in ServerScriptService. Requires ClothingConfig in ReplicatedStorage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("ClothingConfig"))

-- RemoteEvents container
local remoteFolder = ReplicatedStorage:FindFirstChild("ClothingRemotes")
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = "ClothingRemotes"
    remoteFolder.Parent = ReplicatedStorage
end

local OpenShopEvent = remoteFolder:FindFirstChild("OpenShop") or Instance.new("RemoteEvent", remoteFolder)
OpenShopEvent.Name = "OpenShop"

local SaveOutfitEvent = remoteFolder:FindFirstChild("SaveOutfit") or Instance.new("RemoteEvent", remoteFolder)
SaveOutfitEvent.Name = "SaveOutfit"

local RequestEquipEvent = remoteFolder:FindFirstChild("RequestEquip") or Instance.new("RemoteEvent", remoteFolder)
RequestEquipEvent.Name = "RequestEquip"

local RequestPreviewAssetsEvent = remoteFolder:FindFirstChild("RequestPreviewAssets") or Instance.new("RemoteEvent", remoteFolder)
RequestPreviewAssetsEvent.Name = "RequestPreviewAssets"

local NotifyClientEvent = remoteFolder:FindFirstChild("NotifyClient") or Instance.new("RemoteEvent", remoteFolder)
NotifyClientEvent.Name = "NotifyClient"

-- DataStore
local outfitsStore = DataStoreService:GetDataStore(Config.DataStoreName)

-- Folder to hold preloaded assets for preview/equip in ReplicatedStorage
local assetsRoot = ReplicatedStorage:FindFirstChild("ClothingAssets")
if not assetsRoot then
    assetsRoot = Instance.new("Folder")
    assetsRoot.Name = "ClothingAssets"
    assetsRoot.Parent = ReplicatedStorage
end

-- Helper: attempt to preload an asset into ReplicatedStorage at path assetsRoot/<category>/<sanitizedName>
local function preloadAsset(category, item)
    if not item or (type(item.AssetId) ~= "number") or item.AssetId <= 0 then
        return
    end
    local categoryFolder = assetsRoot:FindFirstChild(category)
    if not categoryFolder then
        categoryFolder = Instance.new("Folder")
        categoryFolder.Name = category
        categoryFolder.Parent = assetsRoot
    end

    local safeName = item.Name:gsub("%W", "_")
    if categoryFolder:FindFirstChild(safeName) then
        return -- already loaded
    end

    -- InsertService.LoadAsset must run on server
    local success, result = pcall(function()
        return InsertService:LoadAsset(item.AssetId)
    end)

    if success and result then
        local itemFolder = Instance.new("Folder")
        itemFolder.Name = safeName
        itemFolder.Parent = categoryFolder

        -- Move children from the inserted model into itemFolder
        for _, child in ipairs(result:GetChildren()) do
            child.Parent = itemFolder
        end

        -- Clean up the inserted wrapper if it's still there
        if result.Parent then
            result:Destroy()
        end
    else
        warn("Failed to preload asset", item.Name, item.AssetId, result)
    end
end

-- Preload all configured assets (best-effort)
local function preloadAll()
    local mapping = {
        Shirts = Config.Shirts,
        Pants = Config.Pants,
        Hats = Config.Hats,
        Glasses = Config.Glasses,
        Shoes = Config.Shoes,
    }
    for category, list in pairs(mapping) do
        for _, item in ipairs(list) do
            preloadAsset(category, item)
        end
    end
end

-- Call preload on server start (it will silently skip AssetId==0)
preloadAll()

-- NPC spawn logic: spawn NPCs at persistent spawn points in workspace
local function spawnNPCAt(part)
    if not part or not part:IsA("BasePart") then return end
    local npcModel = Instance.new("Model")
    npcModel.Name = Config.NPCName or "ClothingShopNPC"

    local rootPart = Instance.new("Part")
    rootPart.Name = "HumanoidRootPart"
    rootPart.Size = Vector3.new(2, 2, 1)
    rootPart.Anchored = true
    rootPart.CanCollide = false
    rootPart.CFrame = part.CFrame
    rootPart.Parent = npcModel

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 1, 1)
    head.Position = rootPart.Position + Vector3.new(0, 1.5, 0)
    head.Anchored = true
    head.CanCollide = false
    head.Parent = npcModel

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = npcModel

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "OpenClothingPrompt"
    prompt.ActionText = "Open Shop"
    prompt.ObjectText = Config.NPCName or "Clothing Shop"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = 8
    prompt.Parent = head

    npcModel.Parent = workspace
    npcModel:SetPrimaryPartCFrame(rootPart.CFrame)

    prompt.Triggered:Connect(function(player)
        -- Server informs client to open UI
        OpenShopEvent:FireClient(player)
    end)

    return npcModel
end

-- Spawn NPCs for all saved spawn parts
local function spawnAllNPCs()
    local folder = workspace:FindFirstChild(Config.NPCSpawnFolder)
    if not folder then return end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("BasePart") then
            spawnNPCAt(child)
        end
    end
end

-- Try to spawn NPCs after server starts
spawnAllNPCs()

-- Save outfit handler (multi-slot)
SaveOutfitEvent.OnServerEvent:Connect(function(player, outfitTable)
    -- outfitTable expected: {Slot = int, Data = {Shirts=?, Pants=?, Hats=?, Glasses=?, Shoes=?}, Name = optional}
    if typeof(outfitTable) ~= "table" then return end
    local slot = tonumber(outfitTable.Slot) or 1
    slot = math.clamp(slot, 1, Config.OutfitSlots)
    local data = outfitTable.Data
    if type(data) ~= "table" then return end

    local key = "outfit_slots_" .. player.UserId
    local ok, current = pcall(function()
        return outfitsStore:GetAsync(key) or {}
    end)
    if not ok then
        warn("Failed to read outfits for", player.Name)
        current = {}
    end
    current[slot] = {Data = data, Name = outfitTable.Name or ("Outfit "..tostring(slot)), SavedAt = os.time()}

    local success, err = pcall(function()
        outfitsStore:SetAsync(key, current)
    end)
    if not success then
        warn("Failed to save outfit for", player.Name, err)
        NotifyClientEvent:FireClient(player, {Type = "Error", Message = "Failed to save outfit. Try again later."})
    else
        NotifyClientEvent:FireClient(player, {Type = "Success", Message = "Outfit saved."})
    end
end)

-- Load outfit slots for a player (returns table or nil)
local function loadOutfitsForPlayer(player)
    local key = "outfit_slots_" .. player.UserId
    local data
    local ok, err = pcall(function()
        data = outfitsStore:GetAsync(key)
    end)
    if not ok then
        warn("Failed to load outfits for", player.Name, err)
    end
    return data or {}
end

-- Equip handler: receives {Shirts=?, Pants=?, Hats=?, Glasses=?, Shoes=?} table and equips by inserting objects from ReplicatedStorage
RequestEquipEvent.OnServerEvent:Connect(function(player, outfitTable)
    if typeof(outfitTable) ~= "table" then return end
    local character = player.Character
    if not character or not character.Parent then return end

    -- Remove existing accessories added by shop (tagged "Shop_")
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") and child.Name:match("Shop_") then
            child:Destroy()
        end
    end

    -- Helper to try apply preloaded asset; returns true on success
    local function tryApplyFromAssets(categoryName, index)
        local mapping = {
            Shirts = Config.Shirts,
            Pants = Config.Pants,
            Hats = Config.Hats,
            Glasses = Config.Glasses,
            Shoes = Config.Shoes,
        }
        local list = mapping[categoryName]
        if not list or not list[index] then return false end
        local item = list[index]
        if not item or item.AssetId == 0 then return false end

        local categoryFolder = assetsRoot:FindFirstChild(categoryName)
        if not categoryFolder then return false end
        local safeName = item.Name:gsub("%W", "_")
        local itemFolder = categoryFolder:FindFirstChild(safeName)
        if not itemFolder then return false end

        -- Clone preloaded children into the character
        for _, c in ipairs(itemFolder:GetChildren()) do
            local clone = c:Clone()
            clone.Name = "Shop_" .. tostring(clone.Name)
            if clone:IsA("Accessory") then
                clone.Parent = character
            elseif clone:IsA("Shirt") then
                for _, old in ipairs(character:GetChildren()) do
                    if old:IsA("Shirt") then old:Destroy() end
                end
                clone.Parent = character
            elseif clone:IsA("Pants") then
                for _, old in ipairs(character:GetChildren()) do
                    if old:IsA("Pants") then old:Destroy() end
                end
                clone.Parent = character
            else
                clone.Parent = character
            end
        end
        return true
    end

    -- HumanoidDescription fallback
    local function applyHumanoidDescriptionFallback(categoryName, index, hd)
        local mapping = {
            Shirts = Config.Shirts,
            Pants = Config.Pants,
            Hats = Config.Hats,
            Glasses = Config.Glasses,
            Shoes = Config.Shoes,
        }
        local list = mapping[categoryName]
        if not list or not list[index] then return end
        local item = list[index]
        if not item or item.AssetId == 0 then return end

        -- We attempt to add asset ids to HumanoidDescription asset arrays
        if categoryName == "Hats" or categoryName == "Glasses" or categoryName == "Shoes" then
            -- accessories: try adding to Accessories using AddAccessory can be tricky; instead use Humanoid:EquipAccessory if possible
            -- Best effort: set ClothingAccessoryIds if present
            -- Note: HumanoidDescription doesn't have accessory Id arrays; Roblox HumanoidDescription supports Clothing/Head/Face etc by id depending on API. We'll attempt to use SetHumanoidDescription via Humanoid:ApplyDescription
            -- This fallback is intentionally limited but will try to apply DeveloperProduct compatible approach
            -- No-op here; real robust mapping requires known asset types.
        else
            -- Shirts/Pants can be set via HumanoidDescription.Shirt/Pants ids if available; HumanoidDescription supports Shirt/Pants via AddClothing
            -- We'll attempt to set via HumanoidDescription body ids if possible
        end
    end

    -- Apply categories, trying preloaded assets first, then fallback
    pcall(function()
        local s = outfitTable.Shirts
        local p = outfitTable.Pants
        local h = outfitTable.Hats
        local g = outfitTable.Glasses
        local sh = outfitTable.Shoes

        if s and tonumber(s) then
            if not tryApplyFromAssets("Shirts", tonumber(s)) then
                -- fallback: attempt HumanoidDescription modify
                -- Not fully implemented: placeholder for future mapping
            end
        end
        if p and tonumber(p) then
            if not tryApplyFromAssets("Pants", tonumber(p)) then
            end
        end
        if h and tonumber(h) then
            if not tryApplyFromAssets("Hats", tonumber(h)) then
            end
        end
        if g and tonumber(g) then
            if not tryApplyFromAssets("Glasses", tonumber(g)) then
            end
        end
        if sh and tonumber(sh) then
            if not tryApplyFromAssets("Shoes", tonumber(sh)) then
            end
        end
    end)
end)

-- When player requests preview metadata, return mapped metadata including available slots
RequestPreviewAssetsEvent.OnServerEvent:Connect(function(player)
    local function listForCategory(categoryName, configList)
        local out = {}
        for i, item in ipairs(configList) do
            table.insert(out, {
                Index = i,
                Name = item.Name,
                AssetId = item.AssetId,
                Loaded = (assetsRoot:FindFirstChild(categoryName) and assetsRoot[categoryName]:FindFirstChild(item.Name:gsub("%W","_"))) and true or false,
            })
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

    OpenShopEvent:FireClient(player, payload)
end)

print("ClothingServer initialized (feature/premium-clothing-ui)")
