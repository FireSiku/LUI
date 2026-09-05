# LUI v2609 developer notes

## A note about the cleanup

The first version of this update removed too much. Siku was right to call that out.

I restored the Emmy files, the Curse warning, the specialized-font and LibWindow notes, the Experience Bars explanation, the global color options, the unitframe name and status tags, and the complete custom Artwork panel feature. The Russian locale is also back to the correct `ruRU` casing.

`api/devapi.lua` is smaller, but it cannot be removed yet because Chat still uses its database helpers. To make the difference clear, the old method is now `LegacyToggle` and the current ModuleMixin method is `Toggle`.

I kept `ColorSelect` instead of bringing the old combined `ColorMenu` function back. The current controls still offer Individual, Class and Theme colors; restoring both implementations would only duplicate the same setting.

The unused `TEX_DIR` and `ALPHA` locals remain removed. `ANIM_DURATION` is back and is now used for all main-panel fade calculations.

## Retail 12.1 changes

LUI now targets interface `120100` and includes oUF 14.0.3. Health, power, class resources, casts, absorbs, prediction, range and indicators were updated for the current APIs.

LUI no longer writes cooldown values to Blizzard action buttons. Those values can be protected or secret in Retail 12.1, so Blizzard has to own the cooldown display. Unsafe frame changes are delayed until combat ends.

Unitframe auras now use Blizzard's AuraContainer system. `Player & Pet Only` uses Blizzard's `PLAYER` filter because addons can no longer safely separate player, pet and vehicle sources. Icon size, spacing, wrapping, growth, amount, cooldown display, stacks and timers are still configurable.

## Backdrops and borders

I replaced LUI's active legacy backdrop calls with `api/backdrop.lua`. It draws LUI backgrounds and SharedMedia borders with ordinary textures instead of adding `BackdropTemplate` to every frame.

There were 92 active LUI-owned `SetBackdrop` calls before the conversion; there are none now. Border texture, color, thickness and insets are still configurable. Numeric values are converted before calculations, which also fixes the number-versus-string error seen while changing border thickness.

Blizzard-owned tooltips still use Blizzard's NineSlice system. This avoids changing frames that Blizzard or another addon owns and fixes the hard-coded white center that affected SavedInstances and LibQTip tooltips.

## Unitframes, options and profiles

The existing player, target, focus, pet, party, raid, boss, arena and main-tank layouts remain available. I fixed child-frame option routing, group growth, damaged imported layouts and the Retail color handling. The editable LUI color palettes and name-length options are still present.

Cast-bar preview now has a separate Stop Preview button and stops automatically when it is no longer safe to keep the preview active.

The working module settings were moved into `LUIOptions`. Numeric fields keep numeric database values, position settings use clearer direction labels, and disabled modules no longer leave empty option pages.

Profile export includes the selected Artwork theme and Unitframe layout. Imports are checked before replacing profile data, and Backup, Restore and Revert are available in the options and through slash commands.

## Chat, infotexts and artwork

Chat was updated for the current Blizzard frame, tab, edit-box and message APIs. Disabling it restores the Blizzard state that LUI changed.

Friends and Guild now use the current Friend List, Battle.net, Club and Guild APIs. I fixed the empty or misplaced hover windows, their backgrounds, paging and row widths.

Artwork still supports built-in and custom themes, the orb, navigation bar, main panels, both sidebars and user-created panels. Full texture paths and custom texture coordinates are supported again.

The sidebar presets cover Blizzard bars, Bartender4, Dominos, Details and both Blizzard Damage Meter windows. LUI can position supported third-party frames, but it no longer rewrites another addon's profile.

## Code removed on purpose

Some old code still had to go:

- The Cooldown module wrote protected Blizzard cooldown state.
- Fader belonged to the retired unitframe path.
- GMOTD used a legacy guild call that caused `ADDON_ACTION_BLOCKED`.
- Genesis Motes used obsolete Zereth Mortis container APIs.
- The custom bank and reagent-bank handlers were disabled and not loaded.
- Old third-party installers wrote directly into other addons' saved variables.
- The old oUF prediction files duplicate functionality now owned by oUF 14.
- The retired Unitframe option files duplicate the new `LUIOptions/Unitframes.lua` page.
- The old setup, FAQ, ArtworkV3 and RaidDebuffs files were either unloaded or depended on APIs that no longer exist.

These removals are about avoiding broken or duplicate runtime code. Documentation, editor helpers and working user options are not being treated as dead code anymore.

## Testing

Pahn tested settings, profiles, import/export, raid use and scaling. Teks and BaeBlade helped with general module checks, Jay tested the raid and unitframe paths, and Nikko tested Blizzard bars, Blizzard Damage Meter, Bartender4 and Dominos.

The static checks pass: all Lua and XML files parse, every active TOC/XML path resolves, and there are no remaining LUI-owned legacy backdrop calls or direct action-button cooldown writes.
