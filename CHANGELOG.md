# LUI v2609

This release updates LUI for World of Warcraft Retail 12.1 while keeping the original artwork, themes and layouts.

## Core

- Updated the embedded oUF runtime to 14.0.2.
- Updated status bars, tooltips, auras and other UI code for the current Blizzard API.
- Fixed profile switching, profile conversion, import/export and per-profile backups.
- Restored the current options pages and hid modules that are not available.
- Fixed Blizzard frame scaling and several AceConfig layout and state issues.

## Unit frames

- Updated health, power, cast, absorb, prediction, class-resource, range and indicator handling.
- Moved unit-frame auras to Blizzard's current AuraContainer system.
- Fixed missing aura icons, filters, timers, cooldowns, dispel borders and boss-frame icon borders.
- Deferred protected frame changes until combat ends to avoid taint errors.

## Chat and infotext

- Fixed short channel names, message and tab fading, chat links, copy-chat and scroll reminder buttons.
- Restored edit-box positioning, history, channel colors, textures and borders.
- Added clear descriptions for sticky channels and hover-window font settings.
- Updated Friends, Guild and the remaining infotext providers for the current APIs.
- Improved top-bar alignment for larger infotext fonts, added global horizontal and vertical offsets and enabled all standard screen anchors.

## Artwork and addon support

- Fixed sidebar presets and visibility for Blizzard action bars, Bartender4 and Dominos.
- Fixed Bartender4 auto-positioning on the left sidebar.
- Added presets for both Blizzard Damage Meter windows.
- Added a separate Raid Menu background color for better icon contrast.
- Fixed tooltip backgrounds used by SavedInstances and other LibQTip-based addons.

## Other fixes

- Fixed Bags update handling and character-bag ownership.
- Updated Experience Bars, Mirror Bar, Minimap, Micromenu, Merchant and UI Elements for Retail 12.1.
- Removed obsolete Cooldown, Fader, installer, updater and old addon-integration code.

## Credits

LUI was created by Loui. The Retail version is maintained by Siku, and the Classic version by Nitsah. Retail cleanup and coordination for v2609 were handled by Pahn, with testing and feedback from Teks, BaeBlade, Jay, Nikko and the LUI community.
