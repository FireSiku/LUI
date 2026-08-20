# LUI — Next Generation World of Warcraft User Interface

LUI is a complete and highly configurable user-interface replacement for **World of Warcraft Retail**. It combines LUI's distinctive artwork with integrated unit frames, information displays, a minimap, a micro menu, utility modules, and an extensive in-game options panel.

The current Retail build has been modernized for the latest Blizzard UI systems while preserving the appearance, layouts, and configuration freedom that long-time LUI users expect.

## Highlights

- A complete LUI interface with automatic first-time setup
- Highly configurable player, target, focus, pet, party, raid, boss, arena, and main-tank unit frames
- Modern health, power, cast bar, aura, absorb, heal-prediction, class-resource, and indicator support
- Configurable LUI artwork, information texts, minimap, micro menu, mirror bars, raid menu, tooltips, and other interface modules
- Profile management for different characters, roles, or layouts
- **Profile import and export**, including module settings and the selected custom LUI theme and unit-frame layout
- **Out-of-combat unit-frame previews** for individual frames and complete party, raid, boss, arena, and main-tank groups
- Optional support for compatible third-party addons and replacements; built-in LUI modules can be enabled or disabled where supported

## Installation

### CurseForge app

Install or update **LUI Core** through the CurseForge app. The app installs the required `LUI` and `LUIOptions` addon folders.

### Manual installation

1. Exit World of Warcraft completely.
2. Back up your `WTF` folder if you want an additional copy of your settings.
3. Delete the existing `Interface/AddOns/LUI` and `Interface/AddOns/LUIOptions` folders.
4. Extract the new `LUI` and `LUIOptions` folders into `World of Warcraft/_retail_/Interface/AddOns`.
5. Start World of Warcraft and enable both addons.

**Do not merge a new release into old LUI addon folders.** A clean replacement prevents obsolete files from older versions from being loaded. Removing the addon folders does not remove your profiles; those are stored separately in the account's `WTF` folder.

## First start

New users can follow LUI's installation wizard. Existing users normally keep their saved profiles when updating, although backing up the `WTF` folder before a major release is always recommended.

Open the options through the LUI micro menu or with the usual LUI options command. Unit-frame previews and profile transfer tools are available in the options while out of combat.

## Profile sharing

The profile transfer page can generate a text string for the active profile. An imported profile includes its module namespaces and the selected custom LUI theme and unit-frame layout. Account-wide records such as accumulated gold totals are intentionally not exported.

Imports are validated, cannot run during combat, and ask for confirmation before replacing an existing profile with the same name.

## Compatibility

- This project page is for **World of Warcraft Retail**.
- The current modernization targets the Blizzard 12.1 UI API and includes oUF 14.0.1 integration.
- The Classic edition is maintained separately by **Nitsah**.
- Optional integrations are only active when their corresponding third-party addons are installed.

## Project legacy and credits

LUI was originally created by **Loui** during the Wrath of the Lich King era. **Siku** has developed and maintained LUI for roughly sixteen years and remains the lead developer of the Retail project. **Nitsah** maintains the Classic edition.

The current Retail modernization was rebuilt and coordinated by **Pahn** to help Siku move LUI onto the modern Blizzard and oUF APIs. It remains part of Siku's LUI project, with testing and feedback contributed by the LUI community.

## Source, issues, and support

- Source code: [FireSiku/LUI on GitHub](https://github.com/FireSiku/LUI)
- Bug reports: use the repository's [GitHub issue tracker](https://github.com/FireSiku/LUI/issues)

When reporting a problem, please include the complete error message, the frame or option being used, steps to reproduce it, and a screenshot when the problem is visual.

LUI is licensed under the GNU General Public License v3.0.
