# LUI v2601b

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

## Installation note

- CurseForge users can install or update the complete package normally.
- For manual installation, delete the old `LUI` and `LUIOptions` addon folders before copying the new versions.
- Do not merge the release into an older manual installation because obsolete Lua files may remain behind.
- Deleting the addon folders does not delete profiles stored under `WTF`, but backing up `WTF` before a major update is recommended.
