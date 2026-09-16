# LUI v2609 Alpha 10

## Infotexts

- Improved the reliability of the clock and other infotexts on first login and after loading screens, addressing missing text and incorrect sizing.
- Saved fonts, colors and positions are now applied consistently, including when infotexts are turned back on.
- An error while refreshing an infotext no longer hides an already working display.
- The clock's instance label now keeps the correct font when the display is refreshed.
- Fixed missing or overwritten entries in the Memory tooltip when addons share the same display name.
- Corrected which realm is shown for connected-realm groups in the Gold tooltip.
- Cleaned up a minor issue in the Loot Specialization display and prevented unusable entries from being added to the infotext settings.

## Friends and Guild

- Battle.net names and current character names now stay together on one line.
- The Friends window automatically allows room for full area and realm names. Added **Extra Window Width** under **Infotext > Individual Settings > Friends** for players who prefer a wider window.
- Long notes and messages now have enough space, improving row spacing and scrolling. The last entries in a list remain reachable.
- Improved list updates and prevented repeated requests for friends or guild data when a window refreshes.
- Fixed notices and guild messages that could remain hidden after the list changed, including the messages shown when no friends are online or a character has no guild.
- Corrected note placement for friends playing other games and rank placement when guild notes are hidden.
- The Friends mouse-control hints now close together with the Friends window.

## Raid Menu and Minimap

- Raid menu background and border colors, including transparency, now apply correctly at login and after settings changes. Colors linked to the micromenu also update when its appearance changes.
- Added **Hide Blizzard Raid Menu** under **Micromenu > Raid Menu**, enabled by default, to prevent both raid menus from appearing together. Turning it off, or disabling the LUI raid menu or micromenu, restores Blizzard's normal controls.
- Changes to Blizzard's raid menu wait until combat ends when necessary. Party and raid unit frames are unaffected.
- Minimap area names and coordinates now consistently use the saved text color and transparency.
- Renamed the Artwork **Raid** entry to **Raid Panel** and clarified that it controls the artwork behind the raid frames. Raid tools remain under **Micromenu > Raid Menu**.

## LUI DEBUG

- Added **LUI DEBUG** to the options, also available through `/luidebug`, to help record and share information when a problem occurs.
- The guided window explains how to start recording, stop and save a session, and share a report with the LUI team. Starting and stopping require confirmation outside combat and reload the interface.
- Recording is off by default. Once started, it continues through combat, reloads and logins until you stop it.
- Reports include error details, WoW and addon versions, active LUI modules and information about what was happening when an error occurred. Install **!BugGrabber** to include general Lua errors; blocked actions and Lua warnings can also be recorded without it.
- Keeps the latest three sessions and groups repeated errors to make reports easier to read.
- Reports can be copied from the window or shared as a saved file. The window explains where to find it; nothing is uploaded automatically.
- The optional **LUIDiagnostics** addon is included alongside LUI and LUIOptions. Installation and troubleshooting instructions have been updated.

Thanks to Ullwarth for the original infotext sizing report and suggested retry approach, and to the community for testing and feedback.

---

# LUI v2609

This release updates LUI for World of Warcraft Retail 12.1 while keeping the original artwork, themes and layouts.

## Core

- Updated the embedded oUF runtime to 14.0.3.
- Updated status bars, tooltips, auras and other UI code for the current Blizzard API.
- Restored secret-safe class and resource color handling for protected Retail values.
- Restored shared color menus with separate opacity controls across Artwork, Bags, Experience Bars, Micromenu and Minimap.
- Fixed profile switching, profile conversion, import/export and per-profile backups.
- Restored the current options pages and hid modules that are not available.
- Fixed Blizzard frame scaling and several AceConfig layout and state issues.
- Preserved individual module colors across reloads and kept Bags colors independent from artwork themes, retaining the class-colored background and default opacity.

## Unit frames

- Added optional raid-group text to the player frame, with position, font, size and color settings. It is disabled by default, stays empty outside raids and follows the player's subgroup through roster and vehicle changes using the existing oUF group tag.
- Added separate group labels to LUI raid frames, enabled by default. Labels follow each group's layout, stay outside the unit frames and hide for empty groups. Text scales to fit the narrower 40-player columns; font, color and distance from the frames are configurable.
- Included both displays in unit-frame previews: the player preview shows a sample group number, and the raid preview labels its group columns. Added their controls to both Compact and Categorized options.
- Added optional absorb text to each unit frame, with live shield totals, short/full numbers, prefix, font, color, opacity, position and an option to hide zero values, including when shield values are protected.
- Updated absorb bars to extend from the current health fill and overlap filled health when needed, keeping shields visible at full health. Added an overflow indicator for shields exceeding maximum health and preserved existing absorb display settings.
- Kept unit-frame backgrounds, bars and indicators on consistent layers so world nameplates cannot appear between them.
- Updated health, power, cast, absorb, prediction, class-resource, range and indicator handling.
- Moved unit-frame auras to Blizzard's current AuraContainer system.
- Fixed missing aura icons, filters, timers, cooldowns, dispel borders and boss-frame icon borders.
- Restored name-length, raid-status and editable unitframe palette options.
- Synced PvP and honor indicator handling with the secret-value changes in oUF 14.0.3.
- Avoided `UNIT_COMBAT` updates when every combat-feedback option is disabled.
- Deferred protected frame changes until combat ends to avoid taint errors.

## Chat, tooltips and infotext

- Fixed tooltip background textures being blacked out by the native tint and removed forced background tiling from tooltips and Friends/Guild windows to prevent grid-like seams.
- Grouped tooltip appearance and health-text controls, using the standard color-type labels and border opacity directly in the individual color picker.
- Added SharedMedia border texture selection, retained the native Blizzard border as the default, and prevented overlapping native/custom borders. Kept custom border rendering safe when tooltip dimensions are protected.
- Separated tooltip health-bar color and opacity settings from border colors, and added health-text visibility and color controls. Clarified the own-guild and other-guild color options, which remain saved per profile.
- Fixed short channel names, message and tab fading, chat links, copy-chat and scroll reminder buttons.
- Restored edit-box positioning, history, channel colors, textures and borders.
- Added clear descriptions for sticky channels and hover-window font settings.
- Updated Friends, Guild and the remaining infotext providers for the current APIs.
- Clock: Kept the time display fixed by showing instance information separately. Added compact difficulty labels including N, HC, M, M+ and MFlex, while keeping the full instance name and difficulty available in the tooltip.
- Fixed Clock initialization errors by using a fallback when the display font is not yet available.
- Fixed Clock tooltip errors for saved instances with no localized difficulty name, keeping those lockouts visible in the tooltip.
- Fixed Armor durability updates after portals and zone transitions by refreshing on world entry and player inventory changes. Unavailable durability now displays `--` instead of an incorrect 100%.
- Prevented individual infotext initialization and settings errors from interrupting other displays. Errors remain reported, and incomplete displays can retry initialization when the panels are rebuilt.
- Added background and border texture and color options for the Friends and Guild windows, matching the standard LUI tooltip defaults.
- Corrected unit-tooltip guild colors so the player's guild is green and other guilds are blue.
- Removed Blizzard's frame-settings hint from LUI player, party and raid frame tooltips.
- Limited backdrop and anchoring updates to safe, LUI-managed tooltips, preventing forbidden-object errors on embedded Blizzard widgets.
- Deferred memory collection, usage refreshes and sorting across frames to prevent timeouts with many loaded addons.
- Improved top-bar alignment for larger infotext fonts, added global horizontal and vertical offsets and enabled all standard screen anchors.

## Artwork and addon support

- Raised artwork, top-bar, micromenu and minimap backgrounds above world nameplates while keeping them below interface controls.
- Fixed sidebar presets and visibility for Blizzard action bars, Bartender4 and Dominos.
- Restored user-created artwork panels, custom/full-path textures and per-panel theme selection.
- Fixed Bartender4 auto-positioning on the left sidebar.
- Added presets for both Blizzard Damage Meter windows.
- Added a separate Raid Menu background color for better icon contrast.
- Enabled texture category, preset and custom texture settings for the action-bar top artwork.
- Fixed tooltip backgrounds used by SavedInstances and other LibQTip-based addons.

## Bags

- Added separate SharedMedia texture, thickness and color controls for bag frames and item borders, including the bag bar and utility buttons.
- Separated background artwork, opacity, item backplates and borders. Background color no longer tints selected artwork, and item backplates stay beneath their icons.
- Corrected visible border thickness for the bundled Stripped textures and supported Blizzard borders. Kept Details BarBorder 1 and 2 outlines stable as thickness changes, and adjusted Details BarBorder 3 sizing.
- Applied item-quality colors to common and poor items and equipped bags. Empty item slots no longer show an item border, and native borders no longer overlap LUI borders.
- Added Fill Bags from Bottom and kept its saved state in sync with Clean Bags. Reversed the displayed slots within each bag to remove gaps between partially filled and full bags, and deferred cleanup until the selected direction has updated.
- Arranged newly looted items in the free area in both fill directions: from the top left when filling bags from the bottom, or from the bottom right when filling from the top. Existing items keep their displayed positions while looting; native stacking, bag filters and reagent restrictions remain in effect.
- Refreshed bag layout, fonts, search opacity and colors from the active profile. Kept toolbar styling current after native bag-slot updates and restored separators in the gold display.

## Bank

- Added optional LUI styling for Blizzard's current character and Warband banks. Use LUI Bank is disabled by default and restores Blizzard's appearance when turned off.
- Reused bag textures, item borders and quality colors while retaining native bank tabs, item actions, search, deposits, withdrawals and confirmation dialogs.
- Added bank row size, slot spacing, scale and optional extra spacing after every two columns.
- Added an independent Fill Bank from Bottom display option so Clean Bank fills toward the bottom of the selected tab without changing the bag sorting preference.
- Sized the bank window to contain the deposit controls and reagent checkbox text. Shortened the Warband title and tab label, removed the bright selected-tab glow and kept native tab sockets without an extra LUI outline.

## Other fixes

- Added an optional automatic reputation tracker that follows the last reported faction with a positive reputation gain, in either bar position or with separate bars. Reputation losses do not change the watched faction; the option is disabled by default.
- Fixed Experience Bars retaining an old profile after profile changes, preventing missing-width errors and keeping layout, text and drag settings tied to the active profile.
- Fixed Bags update handling and character-bag ownership.
- Updated merchant coin-texture formatting to the current `C_CurrencyInfo` API.
- Updated Experience Bars, Mirror Bar, Minimap, Micromenu, Merchant and UI Elements for Retail 12.1.
- Added configurable tracker labels and optional hover tooltips to Experience Bars, including watched reputation faction names.
- Added a lock option and visible drag area for freely positioning Experience Bars while preserving anchor-relative X/Y offsets.
- Fixed Experience Bar tracker refreshes so the active primary and secondary trackers update correctly when their availability changes.
- Improved Azerite and House Favor tracking for current Retail APIs and added safer handling for unavailable tracker data.
- Added an option to separate two active Experience Bars, giving the secondary bar its own position and width instead of splitting the primary bar.
- Removed obsolete Cooldown, Fader, installer, updater and old addon-integration code.

Thanks to Teks, BaeBlade, Jay, Nikko, Dvuk13 and the LUI community for testing and feedback.

---

# LUI v2608

## Retail modernization for Blizzard 12.1 and oUF 14.0.1

This changelog documents the complete release delta from the previous FireSiku LUI Retail version.

## New features

### Profile import and export

- Added complete profile import and export under the Profiles options.
- Exports the active LUI profile and all AceDB module namespaces.
- Includes the selected custom Artwork theme and Unitframes layout data.
- Excludes account-wide records such as accumulated gold totals.
- Validates the transfer prefix, format version, serialized structure, profile data, module namespaces, and custom resources before importing.
- Rejects empty, oversized, malformed, incompatible, or unsafe profile strings.
- Blocks profile imports during combat.
- Requests confirmation before replacing an existing profile with the same name.
- Preserves conflicting custom themes and layouts under collision-safe imported names.
- Switches to the imported profile and reloads the interface when required.

### Unit-frame previews

- Added an out-of-combat preview system for LUI unit frames.
- Added controls for Preview All, individual frames, Party, Raid, Boss, Arena, and Main Tank.
- Added previews for party target/pet, boss target, arena target/pet, and main-tank target chains.
- Added a movable 25-player raid preview using the correct 5x5 layout.
- Previews use the real selected LUI layout and live player data instead of unrelated placeholder boxes.
- Preview containers integrate with the existing LUI unit-frame mover and save positions through the normal layout database.
- The corresponding live group frame is temporarily hidden while its preview is active and restored afterward.
- Preview frames automatically hide in combat and stop safely during profile changes.
- Added recovery for partially created preview frames after layout errors.

### Aura rows

- Added separate **Icons Per Row** settings for buffs and debuffs on every supported unit-frame page.
- The existing Amount setting remains the total number of displayed icons.
- Aura icons now wrap into additional rows after the configured per-row limit.
- Existing profiles retain their previous single-row behavior until the new setting is changed.

### Micromenu

- Added a Housing button using Blizzard's current Housing dashboard and secure microbutton path.
- Added a matching visibility option to the Micromenu settings.
- Corrected the Housing icon orientation and LUI presentation.

## Framework and Blizzard API

- Replaced the embedded oUF 13.4.5 framework with official oUF 14.0.1 core files and its current element load list.
- Updated the LUI and LUIOptions interface metadata for Blizzard 12.1 Retail.
- Added compatibility aliases required by the original FireSiku layouts while moving runtime behavior to oUF 14.
- Updated event, power, aura, private-aura, range, rune, stagger, threat, summon, quest, PvP, raid-target, ready-check, and resurrection paths for the current Blizzard API and secret-value rules.
- Replaced legacy LUI smoothing hooks with oUF 14 status-bar interpolation.
- Retained the latest Death Knight rune implementation, including the rune color correction.

## Health, power, prediction, and absorbs

- Rebuilt Health and Power text handling so protected combat values are not read, compared, or arithmetically combined by addon Lua.
- Connected the existing value, percentage, and missing-value modes to Blizzard's intended protected-value APIs:
  - `UnitHealthPercent`
  - `UnitPowerPercent`
  - `UnitHealthMissing`
  - `UnitPowerMissing`
- Kept the shared LUI text and layout settings working across player, target, focus, pet, party, raid, boss, arena, and child-frame pages.
- Updated Additional Power and Alternative Power for the oUF 14 power model.
- Mapped LUI heal-prediction and absorb settings to the oUF 14 Health subwidgets.
- Corrected live option refresh paths for heal prediction and absorbs.
- Corrected copied unit-frame settings to use the current HealthBar, PowerBar, HealthPredictionBar, and TotalAbsorbBar database keys.
- Prevented disabled Power bars from being shown again by native oUF updates while allowing configured secret-safe power text to continue updating.

## Buffs and debuffs

- Replaced legacy frame aura handling with Blizzard 12.1 AuraContainer objects.
- Blizzard now owns protected aura data, filtering, updates, and AuraButton creation instead of addon Lua decoding secret values.
- Restored Buff and Debuff containers on all relevant unit-frame layouts, including the player frame.
- Connected all visible aura options to the new containers:
  - Enable or disable
  - Player Only
  - Include Pet
  - Color By Type
  - Total icon count
  - Icons per row
  - Icon size and spacing
  - X/Y offset
  - Anchor
  - Horizontal and vertical growth
  - Aura Timer
  - Disable Cooldown
  - Cooldown Reverse
- Added LUI-style icon edges, application counts, and configurable numeric duration text.
- Restored animated cooldown spirals, including reverse mode.
- Kept timer and application-count text above the cooldown swipe layer.
- Prevented duplicate icons when an existing damage-over-time effect is refreshed.
- Corrected stale icons remaining after an aura expired.
- Prevented party-frame debuff containers from displaying the current target's auras.
- Corrected live aura refreshes and prevented the legacy oUF 13 aura element from being enabled for AuraContainer frames.

## Cast bars, class resources, and indicators

- Reworked cast bars for oUF 14 DurationObjects and current callback signatures.
- Updated cast name and time text, borders, option-driven colors, and shielded-cast presentation.
- Restored target, focus, party, raid, boss, and other supported castbar paths.
- Prevented duplicate target, focus, or group cast bars when those frames represent the player and the player cast bar is already visible.
- Updated totem durations and class-resource integration for the current framework.
- Updated indicator and range paths for protected values and oUF 14.
- Updated leader, group-role, ready-check, raid-target, resurrection, summon, quest, PvP classification, threat, and range-fading behavior.

## Unit-frame options and routing

- Audited the visible General, Health Bar, Power Bar, prediction, absorb, text, portrait, aura, indicator, castbar, and shielded-castbar option pages.
- Reconnected their runtime apply paths to the current elements.
- Restored Buff and Debuff activation controls on every applicable unit-frame tab.
- Fixed party-pet, boss-target, and arena-target child-frame names.
- Corrected boss and main-tank child counts.
- Corrected arena and main-tank option routing.
- Applied every child layout database after its parent creates the frames so child tabs no longer silently fail to update.
- Corrected several V2 texture and castbar database references.
- Deferred protected size and layout changes until combat ends, preventing `SetWidth` and related combat-lockdown failures.

## Tooltips, pinging, and mouse interaction

- Restored unit tooltips for non-player units when Blizzard protects the tooltip GUID.
- Preserved tooltip functionality when a protected GUID cannot be resolved to a public unit token.
- Restored Blizzard target pinging on LUI unit frames without copying protected target strings through addon Lua.
- Verified environment and unit-frame interaction paths outside combat and in group content.

## Control Panel and modules

- Rebuilt the Control Panel module list as a concrete AceConfig table.
- Fixed the options window failing to open when the embedded AceConfig version rejected a function in a group's `args` field.
- Generated the module list from registered LUI modules.
- Sorted module entries consistently.
- Reported their actual enabled or disabled state.
- Marked always-on components clearly.
- Disabled module option pages are now intentionally greyed out in the navigation list.
- Corrected Infotext and Addons tab availability checks.
- Corrected guild-member class-color lookup so localized class names no longer incorrectly fall back to white.

## Combat lockdown and taint prevention

- Wrapped the Bartender installer and sidebar adjustment paths so protected frame changes run outside combat.
- Avoided insecure sidebar show/hide operations on protected anchored frames during combat.
- Removed raw TutorialHelper action-button hooks that tainted Blizzard's protected ActionButton attribute updates.
- Deferred protected LUI unit-frame changes until combat ends.
- Updated secret-value checks throughout the affected oUF elements and LUI integration paths.

## Additional compatibility and interface fixes

- Corrected Micromenu behavior for current Blizzard frames and buttons.
- Corrected Clock, Artwork, Toggle, V2Textures, and related refresh paths retained in the rebuilt package.
- Updated the Retail build and interface constants used by LUI version checks.
- Fixed Lua compatibility issues in the Plexus integration and Emmy ColorPicker declaration.
- Fixed UnitFrames going missing for certain classes or specializations such as Frost Mages and Death Knights.
- Added oUF 14 compatibility documentation and updated the embedded framework metadata, documentation, and license.
- Rebuilt the Control Panel and option title presentation for a release build.
- Removed obsolete empty and `_old` media files from the release package.

## Verification

- The final release ZIP contains only the required `LUI` and `LUIOptions` top-level folders.
- All 275 Lua files pass the available Lua 5.1 static parser check.
- All 27 XML files pass structural parsing.
- All TOC and XML load references resolve with matching paths and filename case.
- The final ZIP passes archive-integrity validation.
- Dedicated local checks cover profile transfer, preview creation, the 25-frame raid grid, mover save/restore, preview cleanup, and multi-row aura dimensions.
- Community testers verified profile import/export, unit-frame previews, aura timers and cooldowns, aura refresh/removal, target pinging, non-player tooltips, cast bars, and the new icons-per-row setting in game.
