This repo contains an official stripped-down Unity project of the game Shortest Trip to Earth (https://store.steampowered.com/app/812040/) for content modding purposes.

**Note that this README is still work in progress and may change significantly. Any feedback that would make it more usable is appreciated.**

# Usage rules

All content and code in this repo is owned by the developer Interactive Fate, our publisher Iceberg Interactive, or is licensed from other parties and included in binary form (similarly to how we include code in game build available on Steam). We grant you permission to only use the contents of this repo for making modifications to the game Shortest Trip to Earth.

# General modding guidelines

The game can be thought to consist of 3 parts:
* First and the most important is the game data. This includes ships, modules, levels, perks, menu, UI elements and much more. Most of the game content lives in _Unity Asset Bundles_. Think of these as compressed archives that the game unpacks when it loads and uses what it finds inside. Modding the game (via _Steam Workshop_ or Mods/ folder) basically means that you can provide your own asset bundles that add or replace game content. We use the same method ourselves for DLCs. Besides asset bundles, we use .tsv files for game translations. There is a separate guide for it here https://steamcommunity.com/sharedfiles/filedetails/?id=2244605825
* Secondly, there is the save folder. It stores current run progress, unlocked perks, scoreboard and more. Save files are in binary format saved using Unity Easy Save 2 plugin (ES2 for short). If you have that plugin installed in Unity Editor then you can edit save files directly. Another and often a better way is to write scripts in Unity that can edit save files.
* Thirdly, there is the logic/code. It lives in dll files that are part of the core game build. It's the hardest thing to mod because we can't publish full source code, but with enough time and dedication it can be done, we've seen it :). Since the game code lives in game install folder, _Steam Workshop_ items or anything in Mods/ folder can't change/replace it directly, but workshop item can instruct player how to apply changes to the game install.

In house, we have one big Unity project that we all work on and when it's time to release an update, we make a build. For modding we have this repo where the game source code is replaced with compiled dll files and most of the content is replaced with external references. There should be still enough complete assets (some ships, a few modules of each type, some crewmembers, etc) including all graphics, particle effects, sounds, etc to learn how we have things set up. The project in this repo can be used to create asset bundles that the game automatically loads.

Copying any asset bundle or tsv file into Mods/ (or its subfolder) relative to the game install folder makes the game load it. The game also looks into ../../workshop/content/812040/ which is where _Steam Workshop_ downloads its workshop item files.

# What's inside the project

Now it is time to mention that some parts of the game use Unity plugins that are not free. We have licenses to use them, but we can't sublicense them. Without those plugins, some of the game content can't be easily edited. For example all interactable items on starmap use Playmaker for popups shown on screen. If you have Playmaker plugin then you see a nice graphical interface with editable boxes and arrows showing how you progress through it. Without that plugin you see a rather complex tree structure where you may be able to change some texts or values, but can't really see what it does in the game. Still, many things in starmap item data is outside Playmaker data structures and can be changed easily, like its sprite or how likely sector generator spawns asteroids around it.

The root folder of the stte-mod repo can be opened in Unity Editor as a project. The project is made in Unity Editor version 2018.4.10f1. Later versions, especially the latest 2018.4 iteration, may work too but is not tested. (download link: https://unity3d.com/unity/qa/lts-releases?version=2018.4&page=2). In Unity Editor, only Assets/ folder contents are directly visible. Assets/RST/ contents are auto-generated from our main project and its contents will change whenever a new game build is made public.

* **Assets/RST/Prefabs/**
Each ship, ship module, ship module slot, crewmember, etc is one prefab. These are either complete prefabs where you can see full transform hierarchy, all used components and referenced assets (sprites, animations, audio clips, etc), or empty prefabs with just an ExternalPrefab component. Those are used in place of a complete prefab where it needs to be referenced.

* **Assets/Plugins/**
Most of the script assemblies (dll) that the game uses are in here. These are not exactly the same as in the released game build. Here we have some Unity Editor related parts left in, otherwise, some of our editor tools included here wouldn't work.

* **Assets/RST/Animations/**, **Assets/RST/Materials/**, **Assets/RST/Sounds/** and **Assets/RST/Textures/**
Here are the assets that prefabs use. In stte-mod we only include assets that are used by complete prefabs.

* **Assets/Example content/**
Here is an example to demonstrate how a mod source structure may look like. It is set up to add and replace some items in the game. To get it into the game, an asset bundle has to be created from this.

* **AssetBundles/**
Built asset bundles will be placed here.

* other folders outside **Assets/**
These are used for various purposes by Unity, just leave them as is.

# Prefabs

Here's general info about what a prefab is in Unity. https://docs.unity3d.com/560/Documentation/Manual/Prefabs.html In our game prefabs have some additional rules.

Prefabs you create should usually be assigned to asset bundles. Otherwise, they won't be included in built asset bundles. No prefabs in Assets/RST/ has asset bundle set because they already are in the base game. Other asset types shouldn't be assigned to asset bundles explicitly, because then unity can decide by itself which dependencies to include in asset bundle.

Each prefab has a unique number assigned to it called prefabId. For new prefabs it has to be manually generated by right-clicking on the first component name (for a bridge module, the component is ShipModule for example) and choosing "Regen PrefabId" from the context menu. When the game is loaded, all prefabs are loaded into a Dictionary<int,GameObject> that maps prefabIds to loaded prefabs. If there are two prefabs with the same id, then the one loaded later will be added to prefab dictionary and is used in the game. This allows replacing base game content with modded content because game first loads asset bundles from game install folder and then from Mods/ and Steam Workshop folders.

Prefabs depend on each other. In Unity Editor we use PrefabRef fields in components for defining dependencies (PrefabRef is a struct containing a GameObject and an int). A PrefabRef field provides the convenience of drag-dropping prefabs in it, but it also automatically fills prefabId stored inside. When the game or an asset bundle is built, only the prefabId is what's included in the build.

All prefabs have one main component attached. It should always be the first after mandatory Transform. For example, there are Ship, ShipModule, Perk, Crewmember, Explosion, Beam, etc components. These components contain game logic, but also expose fields that are editable in Inspector. Many fields have Tooltips that can be seen when hovered. Almost always there are additional components which are either mandatory or optional that also have editable fields.

When setting up a prefab a proper tag and layer should be used. Otherwise, expect unexpected behaviour. It's best to look these up from complete prefabs.

# Building and using mods

On game load, all .tsv and .ab files it finds are read. TSV files can contain community translations and they can be made with a text editor. AB files are asset bundles containing prefabs and their dependencies. Asset bundles must be built from inside Unity. For both, they need to be placed either in Mods/ relative to game install or somewhere in Steam Workshop folders.

Building an asset bundle:
* Make sure all prefabs you want to include have AssetBundle name set. Its dependencies like sprites shouldn't have AssetBundle name set.
* Open "Window/AssetBundle Browser" from Unity main menu
* Now Configure tab should show what would be included in asset bundle. If there are unneeded dependencies, try to figure out where they come from and remove them
* Build tab has a button that starts building all asset bundles shown on Configure tab into Output Path folder. Before pressing Build, ensure the following settings:
   BuildTarget is StandaloneWindows64
   OutputPath is AssetBundles/
   ClearFolders is checked
   Compression is ChunkBasedCompression (LZ4)
   Other advanced settings should be unchecked
* Wait for asset bundle build to complete. One done, open AssetBundles/ folder and add .ab extension to files that don't have it
* Copy your .ab file into Mods/ folder relative to game install or into your Steam Workshop folder (AssetBundles.ab and manifest files don't need to be copied)
* Fire up the game as usual and look into output_log.txt in savegame folder. It should tell how many prefabs it could load and replace. If there are no lines about your asset bundles being loaded then they are probably in the wrong folder or don't have .ab extension.
