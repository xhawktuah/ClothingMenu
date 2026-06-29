-- PremiumClothingUICreator.lua
-- Creates a polished, editable ScreenGui named 'PremiumClothingUI' in StarterGui.
-- Run this script in Studio (Command Bar or as a plugin action) to generate the ScreenGui for designers.

local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
    -- This creator should only run in Studio
    return
end

-- Avoid creating duplicates
if StarterGui:FindFirstChild("PremiumClothingUI") then
    warn("PremiumClothingUI already exists in StarterGui")
    return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PremiumClothingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = StarterGui

-- Main panel (right side)
local main = Instance.new("Frame")
main.Name = "MainPanel"
main.AnchorPoint = Vector2.new(1, 0.5)
main.Position = UDim2.new(1, -24, 0.5, 0)
main.Size = UDim2.new(0, 520, 0.86, 0)
main.BackgroundColor3 = Color3.fromRGB(18,18,18)
main.BackgroundTransparency = 0.18
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(42,42,42)
mainStroke.Thickness = 1
mainStroke.Parent = main

-- Gloss reflection top
local reflect = Instance.new("Frame")
reflect.Name = "Reflection"
reflect.Size = UDim2.new(1, -24, 0, 80)
reflect.Position = UDim2.new(0, 12, 0, 12)
reflect.BackgroundColor3 = Color3.new(1,1,1)
reflect.BackgroundTransparency = 0.88
reflect.Parent = main
local rCorner = Instance.new("UICorner", reflect)
rCorner.CornerRadius = UDim.new(0, 18)
local rGrad = Instance.new("UIGradient", reflect)
rGrad.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1))
rGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.82), NumberSequenceKeypoint.new(1,1)})

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "PREMIUM CLOTHING"
title.TextColor3 = Color3.fromRGB(240,240,240)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 24, 0, 24)
title.Size = UDim2.new(0, 300, 0, 28)
title.Parent = main

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(17,17,17)
closeBtn.BackgroundTransparency = 0.2
closeBtn.Size = UDim2.new(0,40,0,40)
closeBtn.Position = UDim2.new(1, -60, 0, 16)
closeBtn.Parent = main
local cCorner = Instance.new("UICorner", closeBtn)
cCorner.CornerRadius = UDim.new(0,12)
local cStroke = Instance.new("UIStroke", closeBtn)
cStroke.Color = Color3.fromRGB(42,42,42)

-- Viewport preview
local viewport = Instance.new("ViewportFrame")
viewport.Name = "Preview"
viewport.Size = UDim2.new(0, 240, 0, 360)
viewport.Position = UDim2.new(0, 24, 0, 76)
viewport.BackgroundTransparency = 1
viewport.Parent = main

-- Controls container
local controls = Instance.new("Frame")
controls.Name = "Controls"
controls.Size = UDim2.new(1, -300, 1, -120)
controls.Position = UDim2.new(0, 300, 0, 76)
controls.BackgroundTransparency = 1
controls.Parent = main

local uiList = Instance.new("UIListLayout", controls)
uiList.Padding = UDim.new(0, 12)
uiList.SortOrder = Enum.SortOrder.LayoutOrder

-- Helper to create category block
local function makeCategory(name, order)
    local cont = Instance.new("Frame")
    cont.Name = name .. "_Container"
    cont.Size = UDim2.new(1, 0, 0, 110)
    cont.BackgroundTransparency = 1
    cont.LayoutOrder = order
    cont.Parent = controls

    local t = Instance.new("TextLabel")
    t.Name = "CatTitle"
    t.Size = UDim2.new(1,0,0,20)
    t.Position = UDim2.new(0,0,0,0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = name:upper()
    t.TextColor3 = Color3.new(1,1,1)
    t.TextSize = 14
    t.Parent = cont

    local itemLabel = Instance.new("TextLabel")
    itemLabel.Name = "ItemLabel"
    itemLabel.Size = UDim2.new(1,0,0,14)
    itemLabel.Position = UDim2.new(0,0,0,22)
    itemLabel.BackgroundTransparency = 1
    itemLabel.Font = Enum.Font.Gotham
    itemLabel.Text = "ITEM: 1"
    itemLabel.TextColor3 = Color3.fromRGB(220,220,220)
    itemLabel.TextSize = 12
    itemLabel.Parent = cont

    local left = Instance.new("TextButton")
    left.Name = "Left"
    left.Size = UDim2.new(0,36,0,36)
    left.Position = UDim2.new(0,6,0,40)
    left.Text = "<"
    left.Font = Enum.Font.GothamBold
    left.TextSize = 18
    left.Parent = cont
    local leftCorner = Instance.new("UICorner", left)
    leftCorner.CornerRadius = UDim.new(0,8)

    local num = Instance.new("TextLabel")
    num.Name = "Number"
    num.Size = UDim2.new(0,120,0,36)
    num.Position = UDim2.new(0,54,0,40)
    num.BackgroundTransparency = 1
    num.Font = Enum.Font.GothamBold
    num.Text = "1 / 1"
    num.TextColor3 = Color3.new(1,1,1)
    num.TextSize = 16
    num.Parent = cont

    local right = left:Clone()
    right.Name = "Right"
    right.Position = UDim2.new(0,186,0,40)
    right.Text = ">"
    right.Parent = cont

    -- Buttons container
    local btnFrame = Instance.new("Frame")
    btnFrame.Name = "Buttons"
    btnFrame.Size = UDim2.new(1,0,0,44)
    btnFrame.Position = UDim2.new(0,0,0,68)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = cont

    local buy = Instance.new("TextButton")
    buy.Name = "BuyBtn"
    buy.Text = "BUY"
    buy.Font = Enum.Font.GothamBold
    buy.TextSize = 14
    buy.Size = UDim2.new(0,110,0,36)
    buy.Position = UDim2.new(0,6,0,4)
    buy.BackgroundColor3 = Color3.fromRGB(17,17,17)
    buy.BackgroundTransparency = 0.2
    buy.TextColor3 = Color3.new(1,1,1)
    buy.Parent = btnFrame
    local buyCorner = Instance.new("UICorner", buy)
    buyCorner.CornerRadius = UDim.new(0,18)
    local buyStroke = Instance.new("UIStroke", buy)
    buyStroke.Color = Color3.fromRGB(42,42,42)

    local equip = buy:Clone()
    equip.Name = "EquipBtn"
    equip.Text = "EQUIP"
    equip.Position = UDim2.new(0,128,0,4)
    equip.Parent = btnFrame

    return cont
end

-- Create categories
local shirt = makeCategory("SHIRT", 1)
local pants = makeCategory("PANTS", 2)
local hat = makeCategory("HAT", 3)
local glasses = makeCategory("GLASSES", 4)
local shoes = makeCategory("SHOES", 5)

-- Outfits browser (bottom left)
local outfitsFrame = Instance.new("Frame")
outfitsFrame.Name = "OutfitsBrowser"
outfitsFrame.Size = UDim2.new(0, 260, 0, 160)
outfitsFrame.Position = UDim2.new(0, 24, 1, -200)
outfitsFrame.BackgroundTransparency = 0.2
outfitsFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
outfitsFrame.Parent = main
local obCorner = Instance.new("UICorner", outfitsFrame)
obCorner.CornerRadius = UDim.new(0,14)
local obStroke = Instance.new("UIStroke", outfitsFrame)
obStroke.Color = Color3.fromRGB(42,42,42)

local obTitle = Instance.new("TextLabel")
obTitle.Name = "Title"
obTitle.Size = UDim2.new(1,0,0,28)
obTitle.Position = UDim2.new(0,12,0,8)
obTitle.BackgroundTransparency = 1
obTitle.Font = Enum.Font.GothamBold
obTitle.Text = "Outfits"
obTitle.TextColor3 = Color3.fromRGB(240,240,240)
obTitle.TextSize = 16
obTitle.Parent = outfitsFrame

local slotsFrame = Instance.new("Frame")
slotsFrame.Name = "Slots"
slotsFrame.Size = UDim2.new(1,-24,1,-44)
slotsFrame.Position = UDim2.new(0,12,0,40)
slotsFrame.BackgroundTransparency = 1
slotsFrame.Parent = outfitsFrame

local slotsLayout = Instance.new("UIGridLayout", slotsFrame)
slotsLayout.CellSize = UDim2.new(0,74,0,74)
slotsLayout.CellPadding = UDim2.new(0,8,0,8)

-- Create slot placeholders equal to default 6 slots (designer can change)
for i = 1, 6 do
    local slotBtn = Instance.new("TextButton")
    slotBtn.Name = "Slot_" .. i
    slotBtn.Size = UDim2.new(0,74,0,74)
    slotBtn.Text = "Slot\n" .. i
    slotBtn.Font = Enum.Font.GothamBold
    slotBtn.TextSize = 14
    slotBtn.BackgroundColor3 = Color3.fromRGB(26,26,26)
    slotBtn.TextColor3 = Color3.fromRGB(220,220,220)
    slotBtn.Parent = slotsFrame
    local sCorner = Instance.new("UICorner", slotBtn)
    sCorner.CornerRadius = UDim.new(0,12)
end

-- Bottom action bar (save)
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(1, -48, 0, 64)
actionBar.Position = UDim2.new(0, 24, 1, -84)
actionBar.BackgroundColor3 = Color3.fromRGB(18,18,18)
actionBar.BackgroundTransparency = 0.18
actionBar.Parent = main
local abarCorner = Instance.new("UICorner", actionBar)
abarCorner.CornerRadius = UDim.new(0,18)
local abarStroke = Instance.new("UIStroke", actionBar)
abarStroke.Color = Color3.fromRGB(42,42,42)

local saveBtn = Instance.new("TextButton")
saveBtn.Name = "SaveBtn"
saveBtn.Text = "SAVE"
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextSize = 16
saveBtn.Size = UDim2.new(0,140,0,40)
saveBtn.Position = UDim2.new(1,-160,0.5,-20)
saveBtn.BackgroundColor3 = Color3.fromRGB(17,17,17)
saveBtn.BackgroundTransparency = 0.18
saveBtn.TextColor3 = Color3.new(1,1,1)
saveBtn.Parent = actionBar
local saveCorner = Instance.new("UICorner", saveBtn)
saveCorner.CornerRadius = UDim.new(0,18)
local saveStroke = Instance.new("UIStroke", saveBtn)
saveStroke.Color = Color3.fromRGB(42,42,42)

-- Notification toast (top center)
local notify = Instance.new("Frame")
notify.Name = "Notification"
notify.Size = UDim2.new(0,320,0,48)
notify.Position = UDim2.new(0.5,-160,0,18)
notify.BackgroundColor3 = Color3.fromRGB(36,36,36)
notify.BackgroundTransparency = 0.08
notify.Visible = false
notify.Parent = main
local nCorner = Instance.new("UICorner", notify)
nCorner.CornerRadius = UDim.new(0,12)
local nText = Instance.new("TextLabel")
nText.Name = "Text"
nText.Size = UDim2.new(1,0,1,0)
nText.BackgroundTransparency = 1
nText.Font = Enum.Font.Gotham
nText.TextSize = 16
nText.TextColor3 = Color3.fromRGB(240,240,240)
nText.Text = ""
nText.Parent = notify

print("PremiumClothingUI created in StarterGui. Designers can now edit it visually.")
