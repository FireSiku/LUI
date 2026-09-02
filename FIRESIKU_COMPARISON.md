# Changes from FireSiku master

Comparison base:

- Repository: `FireSiku/LUI`
- Commit: `7aebd54200d750680216f4191994f5d91145471d`
- Commit: `fix castbar border thickness`
- Checked out: 30 August 2026
- Target build: LUI v2609 for Retail 12.1

`CHANGELOG.md` is the short release list. Implementation details are in `DEVELOPER_NOTES.md`.

## Source summary

The count covers Lua, XML and TOC source files. Bundled libraries, documentation and repository metadata are excluded.

- 126 existing files changed.
- 51 existing files unchanged.
- 4 runtime files added.
- 53 old or source-only files are not shipped in the v2609 runtime package.

## Version and runtime

| FireSiku master | v2609 |
| --- | --- |
| LUI v2608 | LUI v2609 |
| Retail code before the 12.1 pass | Retail interface `120100` |
| oUF 14.0.1 | oUF 14.0.2 |
| Mixed legacy backdrop code | LUI texture-based backdrop renderer |
| Legacy unitframe aura path | Blizzard AuraContainer groups |
| Old and partly empty option pages | Working module settings in LUIOptions |

## Added runtime files

- `api/backdrop.lua` — LUI backgrounds and SharedMedia borders without `BackdropTemplate`.
- `modules/expbars/housefavor.lua` — tracked House Favor bar.
- `modules/micromenu/alerts.lua` — current micro-menu alert handling.
- `scripts/colorpicker.lua` — current color-picker wrapper.

## Main changes

### Core and Blizzard API

- Updated health, power, alternative power, class power, cast, absorb, prediction, range and indicator handling for Retail 12.1.
- Updated all active LUI status-bar color calls for the current argument form.
- Stopped using restricted values in addon arithmetic and comparisons.
- Removed LUI writes to Blizzard action-button cooldowns.
- Deferred protected frame changes until combat ends.
- Added safe handling for anonymous Blizzard frames and non-string region names.

### Backdrops

- Removed active LUI-owned `SetBackdrop`, `BackdropTemplate` and `BackdropTemplateMixin` use.
- Added one renderer for LUI backgrounds and configurable SharedMedia borders.
- Kept Blizzard NineSlice on Blizzard-owned tooltip frames.
- Removed the hard-coded white tooltip center that affected SavedInstances and other LibQTip tooltips.

### Unitframes and auras

- Updated the bundled oUF integration to 14.0.2.
- Replaced the old aura implementation with Blizzard AuraContainer groups.
- Fixed boss-frame aura borders, player/pet filtering, dispel borders, timers, cooldown display, wrapping and growth.
- Removed direct size changes on protected aura buttons.
- Fixed child-frame option routing, party growth, main-tank growth and damaged layout data.
- Removed the old custom tag registrations and retired raid-debuff plugin.

### Options and profiles

- Restored the working module pages in LUIOptions.
- Fixed AceConfig state, numeric input, multiselect and layout errors.
- Hidden disabled modules instead of leaving grey menu entries.
- Fixed Blizzard frame scaling, including the Game Menu and Settings panel.
- Fixed profile switching, one-time conversion, import/export and per-profile backup actions.
- Removed retired Cooldown and Fader profile namespaces during conversion.

### Chat

- Fixed short channel names, message fading, tab fading and sticky-channel settings.
- Fixed URL and chat-link copy dialogs and the blank Copy Chat window.
- Updated Copy Chat to use `GetMessageInfo`.
- Split Blizzard buttons, scroll reminder and copy-button visibility and scale settings.
- Fixed edit-box channel colors and background alpha.
- Fixed the Chat namespace during profile changes.

### Infotext

- Updated Friends, Guild, Clock, Gold, Memory and the remaining providers for current APIs.
- Fixed the player's own broadcast, Friends paging, panel width and screen bounds.
- Added all nine screen anchors to individual infotexts.
- Added Top, Center and Bottom vertical alignment for every top-bar display.
- Added global Left/Right and Down/Up offsets without replacing individual positions.
- Increased the top infotext row height so larger fonts stay on the artwork bar.
- Renamed `Infotip Font` to `Infotext Hover Font`.

### Artwork and external bars

- Kept the original themes, panels, orb, navigation bar and sidebars.
- Added Blizzard Damage Meter window 1 and 2 presets without modifying its header.
- Corrected Blizzard action-bar labels while retaining Blizzard's real frame names.
- Updated Dominos frame names, saved-anchor migration and sidebar visibility.
- Updated Bartender4 profile positioning and corrected the left-sidebar auto-position offset.
- Added raid-panel anchors for Blizzard, LUI oUF, Plexus, Grid2, HealBot and VuhDo.
- Removed automatic third-party profile installation.

### Other modules

- Bags: replaced the incomplete bucket update path and returned bank containers to Blizzard.
- Experience Bars: fixed events, providers and missing colors; added tracked House Favor.
- Tooltip: updated NineSlice background, border and health-bar handling.
- Raid Menu: updated group actions and added an independent background color.
- Micromenu: updated Retail panels and Housing handling.
- Minimap, Mirror Bar, Merchant and UI Elements: updated current frames and APIs.

## Removed runtime code

### Retired modules and integrations

- `modules/cooldown/`
- `modules/fader/`
- `addons/` profile installers for Bartender, Details, Omen, Plexus and Recount
- `modules/unitframes/plugins/oUF_RaidDebuffs.lua`
- `modules/bags/bank.lua`
- `modules/bags/reagent.lua`
- `modules/chat/GMOTD.lua`
- `modules/expbars/genesis.lua`
- `modules/infotext/dualspec_wrath.lua`
- `modules/infotext/weaponspeed.lua`

### Replaced option and setup files

- Old LUIOptions pages for Action Bars, Auras, Colors, Cooldown, Fader and Raid Menu.
- Old split unitframe option files under `modules/unitframes/options/`.
- Old installer, updater, Blizzard mover, hide-Blizzard and new-player scripts.
- Old artwork panel and UI Elements helper files.
- API annotation files used only during development.

## Changed source areas

- Core: `LUI.lua`, `init.lua`, `update.lua`, `LUI.toc`
- API: colors, frame identifier, module helpers, combat wrapper, profiler, restore and utilities
- oUF: core plus health, power, cast, class-resource, absorb, prediction, range and indicator elements
- Modules: Artwork, Bags, Chat, Experience Bars, Infotext, Merchant, Micromenu, Minimap, Mirror Bar, Raid Menu, Tooltip, UI Elements and Unitframes
- Options: every shipped LUIOptions module page

## Files intentionally left unchanged

The comparison found 51 matching source files. These include stable media registration, locale data, utility code and module pieces that did not require a Retail 12.1 change. Bundled third-party libraries are packaged dependencies and are not counted as LUI source changes.
