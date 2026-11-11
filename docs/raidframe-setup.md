# Optional addon layouts in v2611

The buttons in Control Panel > Addon Setup copy the selected external addon's
profile or skin into a separate **LUI setup profile**, select that copy and apply
the layout there. The original profile remains available in the addon's own
profile selector. Setup never resets or applies layout values to the original.

This applies to Bartender4, Dominos, Grid2, VuhDo, HealBot and Danders Frames.
Complete the addon's initial setup and save/select your current profile first.
Nothing runs automatically at login.

## Profile selection and repeated setup

- The confirmation names the source and destination, and explains how to
  reselect the original. A profile or target-name change before accepting
  cancels the operation before applying the layout.
- A new copy is named `LUI - <original>`. If that name already exists, LUI uses
  a free suffix; an existing user profile is never adopted by name alone.
- LUI remembers the copies it creates separately for each addon. Running setup
  again from that copy or its original updates the same LUI copy. It does not
  create another numbered profile on each run.
- Selecting another original profile gives that profile its own LUI copy.
  Deleting a setup copy allows a fresh copy to be created on the next setup.
- Copying and switching use the addon's native profile API. Layout tables are
  read again after switching so stale references cannot change the original.
- If copying or applying fails, LUI attempts to reselect the previously active
  profile. A partially configured LUI copy may remain; the source is not reset.
- Automatic profile/skin assignments remain under the addon's own control.
  An existing assignment can therefore select the original again later.

## Action bars

Bartender4 and Dominos have separate optional buttons. Enable one at a time and
apply outside combat. The layout sets up two bottom rows and sidebar positioning
in the LUI copy. Existing keybindings are kept. LUI's sidebar assignments follow
the chosen addon.

## Raid frames

- Grid2, VuhDo, HealBot and Danders Frames have separate optional buttons.
- Use one raid-frame addon at a time and apply outside combat.
- The layout uses 80 x 33 frames, four-unit spacing, raid-group ordering and all
  eight raid groups near the bottom-right corner. The UI reloads afterwards.
- Spells, click bindings, aura indicators and other profiles stay in place.
  VuhDo updates panel 1 in its copy; HealBot puts the party and complete raid
  roster into frame 1 of its new skin. Specialized secondary panels are retained.
- Grid2 themes and Danders automatic raid layouts in the copy receive the
  geometry too. Their indicators and conditions are retained.
- Save the current VuhDo configuration before starting. A locked or imported
  source can be copied without changing its ownership or lock metadata. An
  existing LUI VuhDo copy must be locally writable before it can be updated.
  Creating a copy does not replace VuhDo's default-profile assignment.
- HealBot's native UI lock and unfinished Danders automatic-layout editing
  sessions block setup until they are finished.
- The LUI raid artwork attaches to the chosen frames and matches their size.
  This setting is also available under Artwork > LUI Panels. Danders is included
  in the raid presets and suppresses duplicate native LUI raid frames.

## Source contracts checked

| Addon | Release | Profile boundary |
| --- | --- | --- |
| Bartender4 / Dominos | AceDB integration | `SetProfile` to a new destination, then `CopyProfile` from the source, including namespaces |
| Grid2 | 4.1.11 | AceDB; `GridProfileAPI.lua`, `GridLayout.lua`, `GridFrame.lua` |
| VuhDo | v3.220 | Native Save As and load in `VuhDoNewOptionsGeneralSkinsShared.lua` |
| HealBot | 26.11.06.2 | Native `setNewSkin` and `Set_Current_Skin` in `HealBot_Options.lua` |
| Danders Frames | v5.6.2 | Native `DuplicateProfile` and `SetProfile` in `Core/Profile.lua` |

The adapters change settings owned by LUI or the external addon's LUI setup
copy. They do not modify embedded oUF, install addons, disable other addons,
or run at login. Raid-frame changes are followed by a reload so the respective
addon builds its own secure frames.

## Validation

`lua5.1 tests/addon_setups.lua` exercises the actual LUI options callbacks with
addon API fixtures for all six addons: original and unrelated profile retention,
copied healing settings, repeated setup without duplicate profiles, automatic
layouts, all raid groups, profile/target changes during confirmation, failure
recovery, combat and native addon blockers.

`lua5.1 tests/setup_profiles.lua <Ace3 directory>` additionally uses unmodified
AceDB to check copied loaded and unloaded namespaces, separate nested tables,
retained originals, persistent copy ownership and profile-name collisions.
These are local checks; Retail and Forever in-game verification of the external
addon setups is still required.

The existing Guide screenshots describe the older action-bar copy behavior and
the former placement under General > Welcome. Refresh the setup section and its
screenshots after the in-game layout review.
