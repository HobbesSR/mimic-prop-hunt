# Mimic Hunt Gamemode

This is a "reverse prop hunt" gamemode for Garry's Mod, where players playing as Mimics disguise themselves as props, while Hunters try to find and eliminate them. This implementation is a proof-of-concept based on an initial design document.

## Installation

1.  **Locate your Garry's Mod installation.**
    *   You can find this by right-clicking Garry's Mod in your Steam Library, selecting "Manage", and then "Browse local files".
2.  **Navigate to the `addons` folder.**
    *   The full path will be something like: `.../steamapps/common/GarrysMod/garrysmod/addons`.
3.  **Place this folder (`mimic_hunt`) inside the `addons` directory.**
    *   The final structure should be `.../addons/mimic_hunt/addon.json`, etc.

## How to Play

### Launch Options

For easier debugging and development, it is recommended to launch Garry's Mod with the following options:

```
-condebug -console -insecure -allowlocalhttp
```

You can set these by right-clicking the game in Steam -> Properties -> General -> Launch Options.

### Starting a Game

1.  Launch Garry's Mod.
2.  From the main menu, select the "Mimic Hunt" gamemode.
3.  Start a new game on any map (e.g., `gm_construct`).
4.  Alternatively, you can open the developer console and type `map gm_construct` followed by `gamemode mimic_hunt`.

### Gameplay

*   **Teams**: Players are split into Hunters and Mimics.
*   **Mimics**: Your goal is to survive the round. You can disguise yourself as any physics prop. To do so, look at a prop and press your `USE` key (default: E). You cannot move if a Hunter has a direct line of sight to you.
*   **Hunters**: Your goal is to eliminate all Mimics before the time runs out.

## Development & Testing

*   **Fast Reloads**: For rapid development, it is highly recommended to use a **Garry's Mod Dedicated Server**. This allows you to reload scripts without restarting the entire game.
*   **Hot Reloading**: You can use the console command `lua_openscript <filename>` to re-execute a specific Lua script after making changes, which can speed up iteration.
*   **Bots**: The design document suggests adding simple bots for testing. You can add a hook to spawn bots using `+bot_mimics 8` in the launch options, though the bot logic itself is not yet implemented in this version.

## Implementation Notes

*   This initial version sticks closely to the provided design document.
*   The "Paranoia Meter" and "Ping Grenade" mechanics for hunters are mentioned in the design but not fully detailed; they are not included in this initial implementation.
*   The player model for mimics is simply replaced. A more robust implementation might use a proper entity parenting or a NextBot-like system.
*   The logic for assigning players to teams is basic and aims for a 3:1 Hunter-to-Mimic ratio.
*   No custom sounds or content are included yet.
