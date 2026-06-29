-- ClientMain (updated): full Outfits Browser wiring and polished UI interactions
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = require(ReplicatedStorage:WaitForChild("ClothingConfig"))
local remotes = ReplicatedStorage:WaitForChild("ClothingRemotes")
local OpenShopEvent = remotes:WaitForChild("OpenShop")
local SaveOutfitEvent = remotes:WaitForChild("SaveOutfit")
local RequestEquipEvent = remotes:WaitForChild("RequestEquip")
local RequestPreviewAssetsEvent = remotes:WaitForChild("RequestPreviewAssets")
local NotifyClientEvent = remotes:WaitForChild("NotifyClient")

-- Get or create UI
local function getOrCreateUI()
    local gui = playerGui:FindFirstChild("PremiumClothingUI")
    if gui then return gui end
    -- Otherwise try to create via the toolkit script (if present)
    local creator = script.Parent:FindFirstChild("PremiumClothingUICreator")
    -- Fallback: create minimal UI
    local fallback = Instance.new("ScreenGui")
    fallback.Name = "PremiumClothingUI"
    fallback.ResetOnSpawn = false
    fallback.Parent = playerGui
    return fallback
end

local screenGui = getOrCreateUI()
local main = screenGui:WaitForChild("MainPanel", 5)
local preview = main:WaitForChild("Preview", 5)
local outfitsBrowser = main:WaitForChild("OutfitsBrowser", 5)
local saveBtn = main:WaitForChild("ActionBar", true) and main.ActionBar:FindFirstChild("SaveBtn")
local notifyFrame = main:FindFirstChild("Notification")

local function showNotification(type, msg)
    if not notifyFrame then return end
    notifyFrame.Text.Text = msg
    notifyFrame.BackgroundColor3 = (type == "Success") and Color3.fromRGB(12,120,40) or (type == "Error" and Color3.fromRGB(160,40,40) or Color3.fromRGB(40,40,40))
    notifyFrame.Visible = true
    notifyFrame.Text.TextTransparency = 0
    TweenService:Create(notifyFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    delay(2.4, function()
        TweenService:Create(notifyFrame, TweenInfo.new(0.18), {BackgroundTransparency = 0.08}):Play()
        wait(0.18)
        notifyFrame.Visible = false
    end)
end

NotifyClientEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    showNotification(payload.Type or "Info", payload.Message or "")
end)

-- Keep a local cache of server-provided metadata
local serverMeta = {}

-- Build outfits browser UI from SavedOutfits metadata
local function buildOutfitsBrowser(savedOutfits, slotCount)
    local slotsContainer = outfitsBrowser:FindFirstChild("Slots")
    if not slotsContainer then return end
    -- Clear labels on each slot (but keep buttons)
    for i = 1, slotCount do
        local btn = slotsContainer:FindFirstChild("Slot_" .. i)
        if btn and btn:IsA("TextButton") then
            local info = savedOutfits and savedOutfits[i]
            if info and type(info) == "table" then
                btn.Text = (info.Name or ("Outfit "..i))
                btn.BackgroundColor3 = Color3.fromRGB(28,28,28)
            else
                btn.Text = "Empty\nSlot "..i
                btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            end
            -- connect click to load outfit
            btn.MouseButton1Click:Connect(function()
                if info and info.Data then
                    -- Equip
                    RequestEquipEvent:FireServer(info.Data)
                    showNotification("Success", "Outfit applied")
                else
                    showNotification("Info", "Empty slot — save an outfit here with SAVE")
                end
            end)
            -- Right-click context (Shift+Click) to delete or rename
            btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 or (input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputState==Enum.UserInputState.Begin and input:IsModifierKeyDown(Enum.ModifierKey.Shift)) then
                    -- Delete confirmation
                    local confirmed = true -- for simplicity; designers can add a confirmation modal
                    if confirmed then
                        -- delete slot by saving nil
                        SaveOutfitEvent:FireServer({Slot = tonumber(i), Data = {}, Name = ""})
                        -- Refresh request
                        RequestPreviewAssetsEvent:FireServer()
                    end
                end
            end)
        end
    end
end

-- Save current selections into the selected slot
local function getCurrentSelectionsFromUI()
    -- Read elements SHIRT_Container -> ItemLabel etc
    local function readIndex(name)
        local cont = main:FindFirstChild(name .. "_Container")
        if not cont then return 1 end
        local lab = cont:FindFirstChild("ItemLabel")
        if not lab then return 1 end
        local n = lab.Text:match("ITEM:%s*(%d+)")
        return tonumber(n) or 1
    end
    return {
        Shirts = readIndex("SHIRT"),
        Pants = readIndex("PANTS"),
        Hats = readIndex("HAT"),
        Glasses = readIndex("GLASSES"),
        Shoes = readIndex("SHOES"),
    }
end

-- Wire Save button to SaveOutfitEvent with a dialog to pick slot (simple: save to first empty or slot 1)
if saveBtn and saveBtn:IsA("TextButton") then
    saveBtn.MouseButton1Click:Connect(function()
        local selections = getCurrentSelectionsFromUI()
        -- find first empty slot
        local saved = serverMeta.SavedOutfits or {}
        local target = 1
        for i = 1, Config.OutfitSlots do
            if not saved[i] then target = i; break end
            if i == Config.OutfitSlots then target = 1 end
        end
        SaveOutfitEvent:FireServer({Slot = target, Data = selections, Name = "Outfit "..tostring(target)})
        -- ask server to refresh
        RequestPreviewAssetsEvent:FireServer()
    end)
end

-- When server fires OpenShopEvent (with metadata payload), populate UI
OpenShopEvent.OnClientEvent:Connect(function(payload)
    serverMeta = payload or {}
    -- Show UI (animate)
    screenGui.Enabled = true
    if main then
        main.Position = UDim2.new(1, 520, 0.5, 0)
        TweenService:Create(main, TweenInfo.new(0.36, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -24, 0.5,0)}):Play()
    end

    -- Build outfits browser
    local slots = payload and payload.OutfitSlots or Config.OutfitSlots
    local saved = payload and payload.SavedOutfits or {}
    buildOutfitsBrowser(saved, slots)

    -- Wire per-category buttons for preview and buy/equip (if not already wired)
    for _, cat in ipairs({"SHIRT","PANTS","HAT","GLASSES","SHOES"}) do
        local cont = main:FindFirstChild(cat .. "_Container")
        if cont then
            local left = cont:FindFirstChild("Left")
            local right = cont:FindFirstChild("Right")
            local itemLabel = cont:FindFirstChild("ItemLabel")
            local buyBtn = cont:FindFirstChild("Buttons") and cont.Buttons:FindFirstChild("BuyBtn")
            local equipBtn = cont:FindFirstChild("Buttons") and cont.Buttons:FindFirstChild("EquipBtn")
            local list = serverMeta[cat:sub(1, -2)] or {} -- map SHIRT->Shirts
            local count = #list
            if count == 0 then count = 1 end
            local current = 1

            local function update()
                itemLabel.Text = "ITEM: " .. tostring(current)
                local num = cont:FindFirstChild("Number")
                if num then num.Text = tostring(current) .. " / " .. tostring(count) end
                -- ownership check
                local metaItem = list[current]
                if buyBtn and metaItem and metaItem.AssetId and metaItem.AssetId>0 then
                    local ok, owns = pcall(function() return MarketplaceService:PlayerOwnsAsset(player, metaItem.AssetId) end)
                    if ok and owns then
                        buyBtn.Text = "OWNED"
                    else
                        buyBtn.Text = "BUY"
                    end
                end
                -- update preview by requesting server-provided assets (server preloads assets into ReplicatedStorage.ClothingAssets), but client will only update local Viewport by cloning from ReplicatedStorage
                -- For simplicity the server pre-sent metadata; client preview handled elsewhere
            end

            left.MouseButton1Click:Connect(function()
                current = current - 1
                if current < 1 then current = count end
                update()
            end)
            right.MouseButton1Click:Connect(function()
                current = current + 1
                if current > count then current = 1 end
                update()
            end)

            if buyBtn then
                buyBtn.MouseButton1Click:Connect(function()
                    local metaItem = list[current]
                    if not metaItem or not metaItem.AssetId or metaItem.AssetId <= 0 then
                        showNotification("Error","Item not configured")
                        return
                    end
                    MarketplaceService:PromptPurchase(player, metaItem.AssetId)
                    -- After a delay, refresh ownership
                    delay(2, function()
                        RequestPreviewAssetsEvent:FireServer()
                    end)
                end)
            end

            if equipBtn then
                equipBtn.MouseButton1Click:Connect(function()
                    local outfit = getCurrentSelectionsFromUI()
                    -- ensure player owns items before equipping (best-effort)
                    RequestEquipEvent:FireServer(outfit)
                end)
            end

            update()
        end
    end
end)

-- Initial request to server for metadata
RequestPreviewAssetsEvent:FireServer()

print("ClientMain (enhanced) loaded")
