# INSTALLATION.md

This repository contains a premium clothing menu system for Roblox with a prebuilt ScreenGui, server logic, NPC placement plugin source, and multi-slot outfit saving.

Quick install steps (recommended):

1) Open the repository contents in your workspace or copy files into Roblox Studio.

2) ReplicatedStorage:
   - Place the ModuleScript `ClothingConfig.lua` in ReplicatedStorage.

3) ServerScriptService:
   - Place `ClothingServer.lua` in ServerScriptService.

4) StarterGui / Client:
   - Create a ScreenGui in StarterGui named `PremiumClothingUI` (designers can edit this visually).
   - Optionally place `ClientMain.lua` under StarterGui as a LocalScript (or place it in StarterPlayerScripts) so it wires up behavior to the prebuilt ScreenGui.

5) Plugin (optional):
   - The plugin source is under `plugins/NPCPlacement.plugin.lua`. Create a new plugin in Roblox Studio and paste the contents into the plugin script. Activate the plugin to place persistent NPC spawn points (they are saved in workspace under the folder name described in `ClothingConfig.NPCSpawnFolder`).

6) Configure assets:
   - Edit `ReplicatedStorage/ClothingConfig.lua` and put real AssetId values for Shirts/Pants/Hats/Glasses/Shoes.

7) Run the game in Studio server mode. NPCs will spawn at points stored in workspace under the folder specified by `ClothingConfig.NPCSpawnFolder`. Use the ProximityPrompt to open the shop.

Notes:
- The plugin file is a source file to help you create a real Studio plugin; it does nothing at runtime. Installing the plugin is optional but recommended for designer-friendly spawn placement.
- DataStore keys: outfits are saved to a DataStore named by `ClothingConfig.DataStoreName` with key "outfit_slots_<UserId>". Make sure to enable API services when testing DataStore.
