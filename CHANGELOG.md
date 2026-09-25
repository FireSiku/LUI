# LUI v2610

## Test13 code audit

- Tooltip: apply scale changes immediately to managed tooltips, preserving their original scale without compounding. The reported 85% was already applied correctly; this is not a confirmed fix for the perceived tooltip size.
- UIElements: share button state hooks across styles and restrict native layout callbacks to the affected managed frame. Keep the Test12 calendar artwork unchanged.
- Experience Bars: dispatch shared tracker events once through the existing anchor.
- Minimap: preserve the native position and scale across repeated module toggles and reinstall the LUI shape callback on re-enable.
- Mirror Bars: accept both boolean and numeric pause values.
- Bags: treat search input as literal text, including pattern characters such as brackets and percent signs.
- Artwork: use the current profile for sidebars, main panels and navigation buttons; prevent deferred updates from reviving disabled panels; honor the right-side background color.
- Chat: preserve untouched voice visibility callbacks, tolerate a cleared last-active edit box, and correct bare IPv4 link patterns.
- Profiles: repair backups containing scalar values, wildcard settings and nested namespaces; preserve the previous backup on capture failure and keep restored namespace metadata separate from profile settings.
- Colors: resolve complete POWER_TYPE resource tokens and prevent rounded color-picker display fields from writing values back.
- Scaling: avoid redundant Blizzard-window scale writes on addon load and skip forbidden frames.
- Unitframes: safely restore real groups when entering combat during a preview; refresh combat-feedback registration after option changes and correct resource-feedback formatting and colors.
- Masque: resolve embedded Darion textures from LUI's bundled media directory.
- Packaging: remove a stale duplicate infotext tooltip Show call and update packaged version metadata.
- Validation: full-package Lua/XML syntax and load-path checks, focused behavior checks and independent reviews passed. In-game verification remains outstanding.

## Test12 follow-up

- UIElements: revert all calendar-specific frame, corner and background changes from Tests 9–11. Keep the original Blizzard calendar artwork and change only the close-button texture crop to remove the LUI artwork's transparent margins.
- Other Test9–11 fixes, including friend-name sizing and the selected oUF updates, are retained.

## Test11 follow-up

- UIElements: replace the calendar's shaped close-button cut-out with standard WoW title-bar and corner artwork. Preserve the native side-border anchors and close-button behavior.
- UIElements: remove the previous close-button fill, reuse the header regions across openings, and restore the original calendar artwork when button styling is disabled.

## Test10 follow-up

- Infotext: reset the previous name-column width before measuring complete Battle.net account/character labels, including hidden pooled rows. Keep one measurement per name in the existing refresh pass.
- UIElements: restore the selected LUI calendar close-button artwork and fill the opening behind it below the native calendar border. Reuse one background texture and hide it when restoring Blizzard styling.
- Validation: targeted Lua checks and syntax validation passed; in-game confirmation of both visual corrections is still pending.

## Test9 follow-up

- UIElements: preserve and darken the native calendar close-button shape to cover the frame cut-out.
- Unitframes: backport upstream oUF's power-token color fix while retaining LUI's secret-value checks.
- Unitframes: backport upstream oUF's nested nameplate castbar handling.
- Compatibility review: Retail 12.1.0 (69933) and Forever 1.60.1 (70009). In-game verification remains required; embedded oUF remains 14.0.3 with selected upstream fixes.

## Test8 follow-up

- Infotext: let normal WoW friend names use the available screen width, matching Battle.net names.
- UIElements: add button styling for Quick Join, its role dialog, and raid/raid-info controls.

## Changes since Alpha 11

- Core: detect Forever and expose client capability checks.
- Unitframes: tolerate missing native arena containers.
- Unitframes: prepare Forever group headers outside combat.
- Artwork: defer Forever panel toggles until combat ends.
- Micromenu: adapt native controls and availability to Forever.
- ExpBars: omit unavailable Forever tracking providers.
- Options: place bar locking beside tracker controls.
- Bags: add an optional native Forever keyring shortcut.
- Bags: preserve the native Forever bank.
- Infotext: show Forever talents instead of Retail specialization.
- UIElements: expose the native Forever swing timer.
- UIElements: migrate the saved Forever button preference.
- Options: build class colors from available class tokens.
- Options: retain confirmation callbacks in generated controls.
- Profiles: validate imported names by UTF-8 character count.
- Unitframes: supply missing prediction and absorb defaults.
- Unitframes: refresh additional-power colors and smoothing.
- Unitframes: honor raid information text anchors.
- Unitframes: add shared text and aura-count font controls.
- Unitframes: apply configured castbar text outlines.
- Unitframes: choose quest-range fallback by API availability.
- Infotext: save Battle.net broadcasts when pressing Enter.
- Infotext: add optional Raider.IO friend scores and details.
- UIElements: reject restricted objects before cosmetic hooks.
- UIElements: register ready-check responses and Legacy window.
- RaidMenu: recheck group-action permissions on click.
- RaidMenu: clear all unit markers with a secure right-click.
- RaidMenu: add native group options and leave controls.
- RaidMenu: hide and restore the native group manager.
- Unitframes: restore native casts during temporary action UIs.
- Tooltip: run styling after the native OnShow handler.
- Bags: retain unchanged slot anchors when reopening.
- UIElements: exclude bag trees and item slots from generic styling.
- UIElements: restore optional LFG queue-eye positioning.
- Bags: hide the native border instead of leaving a center pixel.
- UIElements: prepare known controls through lifecycle callbacks.
- UIElements: register calendar and map cosmetic controls.
- UIElements: style the current catalog shop controls.
- Core: handle options-addon load failures without a nil call.
- Infotext: open Forever equipment sets through the native click path.
- UIElements: add Trading Post button coverage.
- UIElements: skip unchanged button geometry and visual updates.
- UIElements: reconcile only deferred button work after combat.
- Release: identify the combined clients as v2610.

Button performance changes have passed local mock checks; in-game microlag improvement is not yet confirmed.

---

# LUI v2609 Alpha 11

## Changes since last version

- Micromenu: Opening talents or the spellbook no longer prevents moving or adding spells on Blizzard action bars, including after leveling up with an unspent talent point and an active reminder.
- Micromenu: Left-click opens talents and right-click opens the spellbook. Talent reminders and tutorial pointers keep working when moved to LUI's menu.
- Micromenu: The Dungeon Finder queue eye remains visible while searching, even when LUI hides Blizzard's micromenu.
- Micromenu: The Raid Menu can now be closed while the micromenu is collapsed. Rapid clicks, automatic closing and position updates no longer leave it in the wrong state.
- Micromenu: Raid Menu transitions interrupted by combat finish correctly after combat ends.
- Artwork: Fixed panels and sidebars getting stuck or switching twice during repeated clicks and combat transitions.
- UIElements: Button artwork is now included in LUI, so a separate Interface/Buttons folder is no longer needed.
- UIElements: Added independent style choices for the Escape menu and other buttons, including Blizzard Dark, LUI Classic and LUI HD.
- UIElements: Added high-resolution button artwork and a matching Blizzard Dark appearance for LUI options and confirmation dialogs. Classic and HD artwork now use consistent styling across older and newer menu buttons.
- UIElements: Newly opened windows and tabs receive their button styling immediately. Changing styles updates visible buttons without waiting for background discovery.
- UIElements: Fixed missing LUI HD button faces in Group Finder, Guilds and Communities, including disabled buttons. Bag close buttons, specialization controls and window size buttons now follow button customization.
- UIElements: Spell and macro action buttons keep their original appearance. Styling also skips protected or inaccessible addon controls.
- UIElements: Styles can be changed without reloading, and disabling button customization restores Blizzard artwork. Changes made in combat apply after combat ends.
- Core: Added optional action-bar diagnostics with /luidrag to help investigate blocked spell placement and talent reminders. Reports remain local and recording is off by default.

---

# LUI v2609 Alpha 10

## Changes since last version

- Infotext: Fixed missing text and incorrect sizing at login and after loading screens.
- Infotext: Saved fonts, colors and positions now apply correctly when displays refresh or are re-enabled.
- Infotext: A refresh error no longer hides an already working display.
- Infotext: Fixed missing Memory tooltip entries for addons with identical names and incorrect realm names in the Gold tooltip.
- Infotext: Fixed a Loot Specialization display issue and invalid entries in the settings.
- Infotext: Friends names now stay on one line, and the window allows more room for area and realm names.
- Infotext: Added Extra Window Width under Individual Settings > Friends.
- Infotext: Fixed Friends and Guild row spacing, scrolling, note placement and hidden messages.
- Infotext: Reduced repeated Friends and Guild data requests when refreshing their windows.
- Infotext: Friends mouse-control hints now close with the window.
- Micromenu: Raid Menu background, border colors and transparency now apply correctly, including colors linked to the micromenu.
- Micromenu: Added Hide Blizzard Raid Menu, enabled by default; disabling it or the LUI menu restores Blizzard's controls when out of combat.
- Minimap: Area names and coordinates now use the saved text color and transparency consistently.
- Artwork: Renamed Raid to Raid Panel to distinguish the artwork settings from the Raid Menu tools.
- Core: Added LUI DEBUG in the options and through /luidebug to record troubleshooting reports.
- Core: Debug recording is off by default and continues until stopped; starting and stopping require confirmation outside combat and reload the UI.
- Core: Debug reports include errors, versions, module states and recent activity, with the latest three sessions retained.
- Core: Install !BugGrabber to include general Lua errors; blocked actions and Lua warnings can be recorded without it.
- Core: Debug reports can be copied or shared as a saved file, with instructions in the window; nothing is uploaded automatically.
- Core: The optional LUIDiagnostics addon is included alongside LUI and LUIOptions, with updated installation and troubleshooting instructions.

Thanks to Ullwarth for the infotext sizing report and suggested retry approach, and to the community for testing and feedback.

---

# LUI v2609

## Changes since last version

- Core: Updated LUI for Retail Patch 12.1 and the embedded oUF framework to 14.0.3.
- Core: Updated Blizzard API compatibility and protected class and resource color handling.
- Core: Fixed profile switching, conversion, import/export and per-profile backups.
- Core: Restored shared color menus with separate opacity controls and fixed module colors resetting after reloads.
- Core: Restored options pages, hid unavailable modules and fixed options layout and Blizzard frame scaling issues.
- Core: Removed obsolete Cooldown, Fader, installer, updater and addon-integration code.
- Unitframes: Added optional raid-group text to the player frame, with font, color and position settings.
- Unitframes: Added configurable raid-group labels that follow the raid layout and hide for empty groups.
- Unitframes: Added group labels to player and raid previews, with settings in both Compact and Categorized options.
- Unitframes: Added configurable absorb text with short or full values and an option to hide zero values.
- Unitframes: Absorb bars now remain visible at full health, with an indicator for shields exceeding maximum health.
- Unitframes: Fixed frame layers so world nameplates cannot appear between backgrounds, bars and indicators.
- Unitframes: Updated health, power, cast bars, prediction, resources, range and indicators for the current API.
- Unitframes: Updated auras to Blizzard's AuraContainer system and fixed icons, filters, timers, cooldowns and borders.
- Unitframes: Restored name-length, raid-status and palette options, and skipped combat-feedback updates when disabled.
- Unitframes: Protected frame changes now wait until combat ends.
- Chat: Fixed short channel names, fading, links, copy-chat and scroll reminder buttons.
- Chat: Restored edit-box positioning, history, channel colors, textures and borders, and clarified related settings.
- Tooltip: Fixed blacked-out backgrounds, tiled seams and overlapping borders.
- Tooltip: Added border texture selection while keeping the Blizzard border as the default.
- Tooltip: Reorganized appearance settings and separated health-bar, health-text and border color controls.
- Tooltip: Corrected own-guild and other-guild colors and removed Blizzard's frame-settings hint from LUI unit tooltips.
- Tooltip: Fixed forbidden-object errors from backdrop and anchoring changes on embedded Blizzard tooltips.
- Infotext: Updated Friends, Guild and other displays for the current APIs.
- Infotext: Clock instance labels no longer shift the time display; full instance details remain available in the tooltip.
- Infotext: Fixed Clock errors caused by unavailable fonts or missing difficulty names.
- Infotext: Armor now refreshes after portals and zone changes, showing -- when durability is unavailable.
- Infotext: Errors in one display no longer interrupt other displays, and incomplete displays can retry initialization.
- Infotext: Added background and border settings for Friends and Guild windows and removed tiled background seams.
- Infotext: Spread Memory updates across frames to prevent timeouts with many addons loaded.
- Infotext: Improved alignment with larger fonts and added global X/Y offsets and all standard screen anchors.
- Artwork: Fixed artwork, top-bar, micromenu and minimap backgrounds appearing behind world nameplates.
- Artwork: Restored custom panels, texture paths and per-panel themes, including top action-bar artwork settings.
- Artwork: Fixed sidebar presets and visibility for Blizzard bars, Bartender4 and Dominos, including Bartender4 positioning.
- Artwork: Added presets for both Blizzard Damage Meter windows.
- Micromenu: Added a separate Raid Menu background color.
- Addons: Fixed tooltip backgrounds for SavedInstances and other LibQTip addons.
- Bags: Added separate texture, thickness and color settings for bag and item borders, including bag slots and utility buttons.
- Bags: Separated background artwork, opacity and item backplates so colors no longer overwrite the selected artwork.
- Bags: Corrected border thickness and sizing for supported Blizzard, Stripped and Details textures.
- Bags: Fixed quality colors for common and poor items and equipped bags, and removed borders from empty slots and duplicate native borders.
- Bags: Added Fill Bags from Bottom, with sorting and slot layout following the selected direction.
- Bags: Newly looted items use the free area without moving existing items, while retaining normal stacking and bag restrictions.
- Bags: Fixed profile updates, toolbar styling, character-bag handling and missing separators in the gold display.
- Bank: Added optional LUI styling for character and Warband banks; Use LUI Bank is disabled by default.
- Bank: Bank styling uses bag textures and quality colors while retaining Blizzard's tabs, item actions and controls.
- Bank: Added row size, slot spacing, scale and optional extra spacing after every two columns.
- Bank: Added an independent Fill Bank from Bottom option.
- Bank: Adjusted the window to fit deposit controls and simplified Warband titles and tab styling.
- Experience Bars: Added optional automatic reputation tracking after positive reputation gains.
- Experience Bars: Fixed profile changes, missing-width errors and tracker refreshes.
- Experience Bars: Added configurable labels, reputation faction names and optional hover tooltips.
- Experience Bars: Added a lock option and drag area for positioning bars.
- Experience Bars: Added an option to give the secondary bar its own position and width.
- Experience Bars: Updated Azerite and House Favor tracking and handling of unavailable tracker data.
- Merchant: Updated coin display formatting for the current currency API.
- UIElements: Updated Experience Bars, Mirror Bar, Minimap, Micromenu, Merchant and UI Elements for Retail 12.1.

Thanks to Teks, BaeBlade, Jay, Nikko, Dvuk13 and the LUI community for testing and feedback.

---

# LUI v2608

## Changes since last version

- Core: Updated LUI for Retail Patch 12.1 and the embedded oUF framework to 14.0.1.
- Core: Updated version checks and compatibility with Blizzard's protected values and current APIs.
- Core: Added profile import/export, including module settings, custom artwork themes and unit-frame layouts.
- Core: Profile imports validate the data, preserve conflicting custom resources and require confirmation before replacing a profile.
- Core: Profile imports are blocked in combat; account-wide records such as gold totals are not transferred.
- Core: Fixed the Control Panel failing to open and corrected module states and options availability.
- Core: Updated release titles and framework documentation, and removed obsolete media files.
- Unitframes: Added movable previews for individual frames and groups, including a 25-player raid layout and supported pet and target frames.
- Unitframes: Previews use the selected layout, save positions through the frame mover and hide during combat or profile changes.
- Unitframes: Added separate Icons Per Row settings for buffs and debuffs; existing profiles keep their single-row layout until changed.
- Unitframes: Updated health and power text, prediction and absorbs for protected combat values.
- Unitframes: Fixed prediction and absorb settings applying immediately and corrected copied frame settings.
- Unitframes: Disabled power bars now stay hidden while configured power text continues updating.
- Unitframes: Replaced legacy aura handling with Blizzard's AuraContainer system and restored buff and debuff controls.
- Unitframes: Restored aura counts, timers, cooldown spirals, reverse mode and icon styling.
- Unitframes: Fixed duplicate or expired aura icons and party frames showing the target's debuffs.
- Unitframes: Updated cast bars, cast text, borders, colors and shielded-cast settings for oUF 14.
- Unitframes: Prevented duplicate cast bars when another frame represents the player.
- Unitframes: Updated totems, class resources, rune colors, indicators and range fading.
- Unitframes: Replaced legacy bar smoothing with oUF 14 interpolation.
- Unitframes: Restored settings updates across frame pages and corrected pet and target frame names, counts and option routing.
- Unitframes: Fixed V2 texture and cast-bar settings references.
- Unitframes: Restored non-player tooltips and Blizzard target pinging with protected unit information.
- Unitframes: Fixed missing frames for some classes and specializations, including Frost Mages and Death Knights.
- Unitframes: Protected size and layout changes now wait until combat ends.
- Micromenu: Added a Housing button with a visibility option and updated existing buttons for current Blizzard windows.
- Infotext: Fixed guild-member class colors for localized class names.
- Core: Corrected Clock, Artwork, Toggle and V2Textures refresh behavior.
- Addons: Deferred protected Bartender installer and sidebar changes until out of combat.
- Addons: Removed TutorialHelper hooks that could taint Blizzard action buttons.
- Addons: Fixed Lua compatibility issues in the Plexus integration and color-picker declarations.

