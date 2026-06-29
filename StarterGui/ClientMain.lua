-- ClientMain (LocalScript)
-- This LocalScript assumes there is a pre-built ScreenGui named "PremiumClothingUI" in StarterGui.
-- Place this LocalScript in StarterGui as a child of PremiumClothingUI or in StarterPlayerScripts.

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

-- Utility: find or wait for the ScreenGui
local function getScreenGui()
    local gui = playerGui:FindFirstChild("PremiumClothingUI")
    if gui then return gui end
    -- if not found, wait a short time; developers should place the ScreenGui into StarterGui
    return playerGui:WaitForChild("PremiumClothingUI", 10)
end

local screenGui = nil
local mainFrame = nil
local vpFrame = nil

-- Notification helper
local function notify(type, message)
    -- Fire toast in UI if present
    if screenGui and screenGui:FindFirstChild("Notification") then
        local notifyFrame = screenGui.Notification
        local text = notifyFrame:FindFirstChild("TextLabel")
        if text then
            text.Text = message
            notifyFrame.Visible = true
            notifyFrame.BackgroundColor3 = (type == "Success") and Color3.fromRGB(20,100,20) or (type=="Error" and Color3.fromRGB(120,20,20) or Color3.fromRGB(40,40,40))
            spawn(function()
                wait(2.2)
                notifyFrame.Visible = false
            end)
        end
    end
end

NotifyClientEvent.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    notify(payload.Type or "Info", payload.Message or "")
end)

-- Build a simple viewport preview if the prebuilt GUI doesn't have one
local function createFallbackGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "PremiumClothingUI"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "MainPanel"
    frame.Size = UDim2.new(0,420,0.85,0)
    frame.AnchorPoint = Vector2.new(1,0.5)
    frame.Position = UDim2.new(1,-24,0.5,0)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BackgroundTransparency = 0.2
    frame.Parent = gui

    local vp = Instance.new("ViewportFrame")
    vp.Name = "Preview"
    vp.Size = UDim2.new(0,200,0,300)
    vp.Position = UDim2.new(0,12,0,56)
    vp.BackgroundTransparency = 1
    vp.Parent = frame

    -- Notification frame
    local nf = Instance.new("Frame")
    nf.Name = "Notification"
    nf.Size = UDim2.new(0,200,0,40)
    nf.Position = UDim2.new(0.5,-100,0,12)
    nf.BackgroundColor3 = Color3.fromRGB(40,40,40)
    nf.Visible = false
    nf.Parent = frame
    local ntext = Instance.new("TextLabel")
    ntext.Size = UDim2.new(1,0,1,0)
    ntext.BackgroundTransparency = 1
    ntext.TextColor3 = Color3.new(1,1,1)
    ntext.Text = ""
    ntext.Parent = nf

    return gui
end

-- Initialize GUI references
screenGui = getScreenGui() or createFallbackGui()
mainFrame = screenGui:FindFirstChild("MainPanel")
vpFrame = screenGui:FindFirstChild("Preview")

-- Request server metadata
RequestPreviewAssetsEvent:FireServer()

-- When server opens the shop, make sure the GUI is visible and animate
OpenShopEvent.OnClientEvent:Connect(function(payload)
    screenGui.Enabled = true
    if mainFrame then
        mainFrame.Position = UDim2.new(1,420,0.5,0)
        TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(1,-24,0.5,0)}):Play()
    end
    if payload and payload.SavedOutfits then
        -- Optionally populate outfits browser in GUI if it exists
        if screenGui:FindFirstChild("OutfitsBrowser") then
            -- Developers can implement mapping UI
        end
    end
end)

-- Simple equip request helper (client sends selected indices table)
local function requestEquip(outfit)
    RequestEquipEvent:FireServer(outfit)
end

-- Purchase success/failure handling
MarketplaceService.PromptPurchaseRequested:Connect(function(productId)
    -- Product flow started
end)

-- Ownership update helper (after purchase) - best-effort ownership check
local function checkOwnership(assetId)
    local ok, owns = pcall(function()
        return MarketplaceService:PlayerOwnsAsset(player, assetId)
    end)
    return ok and owns
end

-- Minimal hookups: if ScreenGui contains named elements, wire basic actions
-- This keeps the pre-built ScreenGui editable in Studio. Designers can add buttons and name them accordingly.

local function wireNamedUI()
    if not screenGui then return end
    -- Expect named buttons/containers: SaveBtn, CloseBtn, OutfitSlotsFrame, etc.
    local saveBtn = screenGui:FindFirstChild("SaveBtn", true)
    if saveBtn and saveBtn:IsA("TextButton") then
        saveBtn.MouseButton1Click:Connect(function()
            -- Placeholder: collect current selections from UI elements named SHIRT_Index, etc.
            local outfit = {Shirts = 1, Pants = 1, Hats = 1, Glasses = 1, Shoes = 1}
            SaveOutfitEvent:FireServer({Slot = 1, Data = outfit, Name = "Saved Outfit"})
        end)
    end

    local closeBtn = screenGui:FindFirstChild("CloseBtn", true)
    if closeBtn and closeBtn:IsA("TextButton") then
        closeBtn.MouseButton1Click:Connect(function()
            if mainFrame then
                TweenService:Create(mainFrame, TweenInfo.new(0.28), {Position = UDim2.new(1,420,0.5,0)}):Play()
                task.delay(0.32, function() screenGui.Enabled = false end)
            end
        end)
    end
end

wireNamedUI()

print("ClientMain loaded: UI expects a pre-built PremiumClothingUI ScreenGui in StarterGui. If missing, a fallback GUI was created.")
