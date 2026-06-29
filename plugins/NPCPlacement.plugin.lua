-- NPC Placement Plugin (Studio plugin script)
-- Save this file as plugins/NPCPlacement.plugin.lua in the repo. To use it create a new plugin in Studio and paste the contents into the plugin script body.
-- The plugin will create a folder in workspace named as specified in ReplicatedStorage.ClothingConfig.NPCSpawnFolder and place a part representing a spawn point.

-- NOTE: This file is a Studio plugin source. It won't run at runtime; a developer must install the plugin in Roblox Studio.

local toolbarName = "ClothingShop"
local buttonName = "Place NPC Spawn"

local plugin = plugin -- provided when running as plugin
if not plugin then
    -- Not running as a plugin; this is a source file for plugin creation
    return
end

local toolbar = plugin:CreateToolbar(toolbarName)
local button = toolbar:CreateButton("place_npc_spawn", "Place Clothing NPC Spawn Point", "rbxassetid://4458901886")

button.Click:Connect(function()
    local selection = plugin:GetSelection()
    local studioService = game:GetService("StudioService")
    local spawnFolderName = require(game:GetService("ReplicatedStorage"):WaitForChild("ClothingConfig")).NPCSpawnFolder

    local root = game.Workspace:FindFirstChild(spawnFolderName)
    if not root then
        root = Instance.new("Folder")
        root.Name = spawnFolderName
        root.Parent = game.Workspace
    end

    -- Place a spawn part at the current camera target or at (0,5,0)
    local cam = workspace.CurrentCamera
    local targetCFrame = cam.CFrame * CFrame.new(0, 0, -10)
    local part = Instance.new("Part")
    part.Name = "NPCSpawn"
    part.Size = Vector3.new(2,1,2)
    part.Anchored = true
    part.CanCollide = false
    part.CFrame = targetCFrame
    part.Parent = root

    -- Add a billboard label to identify the spawn point
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0,150,0,40)
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = "Clothing NPC Spawn"
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Parent = billboard

    plugin:Select(part)
end)
