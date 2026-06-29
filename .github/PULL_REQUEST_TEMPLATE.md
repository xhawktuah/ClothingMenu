---
name: Pull Request - Premium Clothing UI
about: Adds the Premium Clothing UI, NPC placement plugin, improved equip logic, and outfits browser.

---

Summary
-------

This pull request implements the following features on the feature/premium-clothing-ui branch:

- A prebuilt, editable ScreenGui (created via a creator script) named PremiumClothingUI so designers can tweak layout visually in Studio.
- A Studio plugin source (plugins/NPCPlacement.plugin.lua) that lets designers place persistent NPC spawn-parts under workspace.<NPCSpawnFolder>.
- Server-side asset preloading into ReplicatedStorage.ClothingAssets and persistent NPC spawning from parts placed in workspace.
- Multi-slot outfit saving using DataStore with keys "outfit_slots_<UserId>" and a configurable number of outfit slots.
- An outfits browser UI and client-side wiring for Save/Load/Delete/Rename/QuickApply flows.
- Improved equip logic that attempts to parent preloaded accessories/shirts/pants, and falls back to applying a HumanoidDescription where applicable.
- Notification/toast support via remote events and client UI.

Files of note:
- ReplicatedStorage/ClothingConfig.lua
- ServerScriptService/ClothingServer.lua
- StarterGui/ClientMain.lua
- tools/PremiumClothingUICreator.lua
- plugins/NPCPlacement.plugin.lua
- INSTALLATION.md

Testing notes
-------------
- Run tools/PremiumClothingUICreator.lua in Studio to generate the PremiumClothingUI ScreenGui in StarterGui, then edit as needed.
- Install the plugin by creating a new plugin in Studio and pasting plugins/NPCPlacement.plugin.lua. Use it to place NPC spawn-parts under the configured folder.
- Add AssetId values (numeric) into ClothingConfig to enable previews and equipment.
- Enable API Services to test DataStore saving/loading.

Why this change
----------------
Converts a runtime-generated GUI into an editable designer-friendly ScreenGui, adds persistent NPC placement, robust equip handling (including HumanoidDescription fallback), and a user-friendly outfits browser — matching the user's request for a fully polished GTA/FiveM-style clothing system with a luxury glassmorphism UI.

