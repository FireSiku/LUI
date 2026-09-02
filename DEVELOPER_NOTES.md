# v2609 developer notes

Technical handoff for the Retail 12.1 update. The shorter user-facing list is in `CHANGELOG.md`.

Comparison base: FireSiku/LUI master `7aebd542` (`fix castbar border thickness`). The source-tree comparison is in `FIRESIKU_COMPARISON.md`.

## Runtime and API

- Retail interface: `120100`.
- Embedded oUF updated to 14.0.2.
- LUI's oUF integration was updated for current health, power, additional power, alternative power, class power, runes, stagger, cast, absorb, prediction, range and indicator handling.
- Status-bar colors use the current Retail argument form. Plain color tables are unpacked before they reach `SetStatusBarColor`.
- Alternative power and other restricted values are no longer used in arithmetic or comparisons.
- LUI no longer writes Blizzard action-button cooldown values. Blizzard owns the cooldown spiral and restricted cooldown data.
- Protected frame changes are deferred until combat ends through LUI's out-of-combat wrapper.
- Frost Mage Icicles are handled by the oUF 14.0.2 ClassPower element.

Main files:

- `api/oUF13/`
- `modules/unitframes/layout/layout.lua`
- `api/outofcombatwrapper.lua`
- `api/colors.lua`

## Backdrop migration

- Removed active `SetBackdrop`, `SetBackdropColor`, `SetBackdropBorderColor`, `BackdropTemplate` and `BackdropTemplateMixin` use from LUI-owned runtime code.
- The 26 August audit counted 92 active LUI-owned `SetBackdrop` calls. The final tree has none.
- `LUI:CreateMeAFrame()` no longer adds a backdrop mixin to every frame.
- Added `api/backdrop.lua` for LUI-owned scalable backgrounds and SharedMedia borders. It creates ordinary texture regions and does not modify the target frame's mixins.
- Fixed artwork uses ordinary texture regions.
- Blizzard tooltip frames keep Blizzard's NineSlice implementation.
- SharedMedia borders used by unitframes, bags, chat and other LUI frames keep their configurable texture and thickness through the LUI renderer.
- Embedded AceGUI and SharedMedia widget backdrop code was left alone. Those copies own their templates and are not part of LUI's runtime backdrop layer.
- Removed the unloaded legacy artwork panel file and the retired raid-debuff plugin instead of migrating dead code.

Main files:

- `api/backdrop.lua`
- `LUI.lua`
- `api/frameidentifier.lua`
- `api/profiler.lua`
- `modules/artwork/artwork_navbar.lua`
- `modules/artwork/artwork_orb.lua`
- `modules/bags/bags.lua`
- `modules/bags/toolbars.lua`
- `modules/chat/buttons.lua`
- `modules/chat/editbox.lua`
- `modules/infotext/infotip.lua`
- `modules/micromenu/micromenu.lua`
- `modules/minimap/minimap.lua`
- `modules/mirrorbar/mirrorbar.lua`
- `modules/raidmenu/raidmenu.lua`
- `modules/unitframes/layout/layout.lua`
- `modules/unitframes/options/movable.lua`

## Unitframes

- Kept the existing player, target, focus, pet, party, raid, boss, arena, main-tank and child-frame layouts.
- Removed LUI's custom tag registrations. Names, class text and difficulty text use the bundled oUF tags.
- Fixed child-frame option routing, party growth and main-tank growth.
- Added guards for incomplete or damaged layout and import data.
- Updated health and power color application without replacing the global `oUF.colors` table.
- Kept LUI's established per-frame color palette. The temporary Blizzard-colors test variant was dropped.
- Cast-bar preview has a separate Stop Preview action. Preview stops on combat start, page change, module disable and options close.
- Unitframe setup no longer overwrites oUF's `Power.GetDisplayPower` handler.
- Frame previews and protected cleanup use deferred out-of-combat changes.

## Auras

- Replaced the old unitframe aura path with Blizzard AuraContainer groups.
- Blizzard owns protected aura data, filtering, button assignment and duration data.
- `Player & Pet Only` uses Blizzard's `isFromPlayerOrPlayerPet` result.
- `Dispel Type Border` changes only the border display; it does not change filtering.
- Removed the obsolete `Include Pet`, `Color by Type` and `Fade Others` paths.
- Kept icon size, spacing, wrapping, growth direction, amount, cooldown spiral, reverse mode, stack count and timer settings.
- LUI's outer aura texture uses `PreserveAsset`, preventing Blizzard's blue inset border from replacing it on boss frames.
- Appearance refresh skips explicitly forbidden aura buttons. Button size is set only in Blizzard's initialization callback, before the access restriction is applied.

Main files:

- `modules/unitframes/layout/auras_12_1.lua`
- `modules/unitframes/layout/layout.lua`
- `modules/unitframes/options/toggle.lua`
- `LUIOptions/Unitframes.lua`

## Options and AceConfig

- Moved the remaining working settings into `LUIOptions`.
- Added or repaired pages for Artwork, Bags, Chat, Experience Bars, Infotext, Merchant, Micromenu, Minimap, Mirror Bar, Raid Menu, Tooltip, UI Elements and Unitframes.
- Removed the invalid private `restrictInteraction` option key and the matching AceGUI interaction-area extension.
- Removed the stale CheckBox calls left by that extension.
- Numeric text inputs keep numeric database values. Normal text inputs are no longer converted just because their contents look like a number.
- Missing multiselect tables are created on first use instead of causing an indexing error.
- Horizontal and vertical controls use direction labels plus an editable number field.
- Disabled modules are hidden from the module list instead of being shown as grey pages.
- The options title no longer contains tester or development build labels.
- Blizzard Frame Scale includes the Game Menu and Settings panel and applies the configured value after reload.

Main files:

- `LUIOptions/LUIOptions.lua`
- `LUIOptions/General.lua`
- all module option files under `LUIOptions/`

## Profiles and conversion

- Profile export includes the module profile, selected artwork theme and unitframe layout.
- Account-wide gold history is not exported.
- Imports are validated before replacing profile data.
- Added profile-specific Backup, Restore and Revert actions.
- `/luibackup`, `/luirestore` and `/luirevert` use the same stored backup.
- Retired Cooldown and Fader namespaces are removed during conversion without trying to load those modules.
- Chat creates its module namespace when a profile is switched before the submodule callbacks run.
- Profile conversion remains a one-time prompt per affected profile.

Main files:

- `update.lua`
- `LUIOptions/LUIOptions.lua`
- `modules/chat/chat.lua`

## Chat

- Updated frame, tab, edit-box, temporary-window, link and focus handling for the current Blizzard chat code.
- Short channel names handle Blizzard channel hyperlinks, party/raid leader types and numbered public channels.
- Added separate settings for message fading and chat-tab fading.
- Minimalist tab state is restored when the module is disabled.
- URL and chat-link copy dialogs use the current StaticPopup accessors.
- Copy Chat reads messages through `GetNumMessages` and `GetMessageInfo`; it no longer changes the chat font size to collect regions.
- Copy window width is set after the scroll area exists, fixing the blank window.
- Blizzard buttons, the scroll reminder and LUI's copy button have independent visibility and scale settings.
- Button option disabled states read the Buttons submodule database rather than the parent Chat database.
- Edit-box channel colors use `ChatTypeInfo` together with `GetChatType` and `GetChannelTarget`.
- The configured edit-box background supplies alpha and the fallback color.
- Sticky Channels now explains the setting and keeps each selected chat type active after sending.
- Disabling Chat restores captured Blizzard fonts, fading, tabs, edit boxes, buttons, filters and sticky flags.
- Prat and Chatter are conflict checks only. No code or profile data is copied from either addon.

Main files:

- `modules/chat/chat.lua`
- `modules/chat/buttons.lua`
- `modules/chat/editbox.lua`
- `modules/chat/stickychannels.lua`
- `LUIOptions/Chat.lua`

## Infotext and hover windows

- Kept each existing provider as a separate LibDataBroker object.
- Providers created after login receive a display and are added to the options.
- Friends and Guild use current Battle.net, Friend List, Club and Guild APIs.
- Friends iterates the complete lists and assigns explicit row widths.
- Fixed broadcast anchoring so it cannot form a cyclic anchor family.
- Friends paging is height-based, stays inside the screen and does not draw a partial final row.
- Increased the Friends panel width and kept the panel above the bottom screen edge.
- Friends and Guild backgrounds use their own settings instead of GameTooltip's background state.
- Renamed `Infotip Font` to `Infotext Hover Font` and documented its purpose.
- Added all nine screen anchor points to individual infotext settings.
- Top-screen displays use a 24-pixel row. `Vertical Alignment` applies Top, Center or Bottom to every top-bar display; Top is the default.
- Global `Left / Right` and `Down / Up` controls offset all top-bar displays without changing their individual saved positions.
- Clock uses `C_Calendar` for pending invites.
- Fixed initial realm-gold totals after login.
- Memory updates only while its display is active.

Main files:

- `modules/infotext/infotext.lua`
- `modules/infotext/infotext_init.lua`
- `modules/infotext/infotip.lua`
- `modules/infotext/friends.lua`
- `modules/infotext/guild.lua`
- `modules/infotext/clock.lua`
- `modules/infotext/gold.lua`
- `modules/infotext/memory.lua`
- `LUIOptions/Infotexts.lua`

## Artwork and addon anchors

- Kept built-in themes, custom themes, class-colored artwork, orb, navigation bar, main panels and both sidebars.
- Theme changes refresh Artwork, Micromenu, Minimap and Bags immediately.
- Saved themes retain those module colors; switching themes does not reuse stale colors from the previous theme.
- Kept two generic meter panels. Details window 1 and 2 remain available as presets.
- Added independent presets for Blizzard Damage Meter window 1 and 2. LUI does not modify Blizzard's meter header or settings.
- Corrected Blizzard action-bar labels to match Action Bars 1 through 8 while retaining their real frame names.
- Updated Dominos presets to `DominosFrame1` through `DominosFrame10` and migrates old saved `Dominos BarN` anchors.
- Dominos sidebars call `ShowFrame` and `HideFrame` outside combat and update `state-hidden` from the secure click path in combat.
- Bartender4 Auto-Adjust updates its action-bar profile out of combat.
- Removed the duplicate left-sidebar texture width from the Bartender position calculation.
- Added a left-only fine adjustment of 7 percent of the drawer width. The working right-side formula is unchanged.
- Added Blizzard raid frames, LUI oUF, Plexus, Grid2, HealBot and VuhDo raid-panel anchors.
- Removed automatic Omen, Recount, Bartender and Plexus profile installation.
- Third-party presets only select or position existing frames. LUI does not install or rewrite third-party profiles.

Main files:

- `modules/artwork/SidebarMixin.lua`
- `modules/artwork/artwork_init.lua`
- `modules/artwork/artwork_mainpanels.lua`
- `modules/artwork/themes.lua`
- `LUIOptions/Artwork.lua`

## Tooltip

- Uses Blizzard's existing NineSlice for Blizzard-owned tooltip frames.
- SharedMedia background textures are applied to the NineSlice center with tile size support.
- Selecting no texture enables the configured solid background color and alpha.
- Preserves Blizzard's center color for textured backgrounds. This prevents SavedInstances and other LibQTip tooltips from receiving a hard-coded white center.
- Updated border and health-bar color calls for the current StatusBar API.
- Disabling the module restores captured NineSlice textures and colors, scale, position, scripts, font and health-bar state.
- StoreTooltip handling remains owned by Blizzard.

Main files:

- `modules/tooltip/tooltip.lua`
- `LUIOptions/Tooltip.lua`

## Bags

- Replaced the incomplete AceBucket dependency with a small `C_Timer` bag-update queue.
- `StopBagUpdates` accepts containers that have not created their pending-update table yet.
- LUI handles character bags only. Bank and other container IDs are returned to Blizzard.
- Search, quality borders, new-item animation, quest and item overlays, cooldowns, stack counts and item levels use current item data.
- Removed unused bank and reagent-bank implementations.

Main files:

- `modules/bags/bags.lua`
- `modules/bags/backpack.lua`
- `modules/bags/templates.lua`
- `modules/bags/toolbars.lua`
- `LUIOptions/Bags.lua`

## Other modules

- Experience Bars: fixed event registration, provider assignment and missing color fallback; kept XP, reputation, honor, Azerite and tracked House Favor.
- Micromenu: uses current Retail panels, includes Housing and hides the separate Blizzard `MicroMenu` frame while active.
- Raid Menu: uses current group permissions, ready check, role check, countdown and marker APIs. Added an optional background color independent of Micromenu.
- Minimap: restores the captured Blizzard shape, textures, scripts and `GetMinimapShape` implementation when disabled. Expansion and notification icons have separate position and size settings.
- Mirror Bar: uses the current Blizzard mirror-timer container and keeps optional archaeology progress.
- Merchant: updated repair, selling, stocking, item-data retry and money-limit paths.
- UI Elements: only positions the current top-center objective/widget container. Blizzard Edit Mode keeps ownership of the other HUD systems.
- Frame Identifier: handles anonymous Blizzard frames and non-string region names without passing invalid values to `SetText`.

## Removed code and packaging

- Cooldown module and action-button cooldown hooks.
- Fader module.
- Old full-screen installer and updater UI.
- Old ActionBars and Auras option shells.
- Old raid-debuff plugin and new-player script.
- Omen and Recount integration.
- Automatic Bartender and Plexus profile installers.
- Empty `addons`, `cooldown`, `fader` and API annotation directories.
- Unused template files and retired commented code.
- AceTimer and LibKeyBound packaging dependencies.

## Final test pass

- Pahn: module settings, profiles, import/export, raid use and scaling.
- Teks and BaeBlade: settings and general module checks.
- Jay: raid/unitframe use and the action-button cooldown reproduction.
- Nikko: Blizzard bars, Blizzard Damage Meter, Bartender4 and Dominos sidebar checks; all supported action-bar presets passed.
- The last Dominos visibility update and the 7-pixel-equivalent Bartender left offset were added after the reported sidebar results and should get one final in-game check.

## Static checks

- 222 Lua files parsed as Lua 5.1.
- 24 XML files parsed successfully.
- 246 active TOC/XML load paths resolved.
- ZIP integrity check passed.
- No active LUI-owned legacy backdrop calls remain.
- No direct LUI action-button cooldown writes remain.
- No `restrictInteraction` option key remains.
