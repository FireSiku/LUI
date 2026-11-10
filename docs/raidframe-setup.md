# Optional addon layouts in v2611

The buttons in Control Panel > Addon Setup apply to the addon's **currently selected
profile**. Reapplying updates that profile. There is no numbered-copy or
automatic profile creation at login. The confirmation names the target profile;
switching profiles before accepting cancels the operation.

Most addons already create a Default profile during their first login. Complete
that addon's initial setup before using LUI's layout buttons. Bartender/Dominos
create LUI only if their database reports no current profile. VuhDo can save its
working configuration as LUI if it has no selected profile yet.

## Raid frames

- Grid2, VuhDo, HealBot and Danders Frames have separate optional buttons.
- Use one raid-frame addon at a time and apply outside combat.
- The layout uses 80 x 33 frames, four-unit spacing, raid-group ordering and all
  eight raid groups near the bottom-right corner. The UI reloads afterwards.
- Existing spells, click bindings, aura indicators and other profiles stay in
  place. VuhDo updates panel 1; HealBot puts its party and complete raid roster
  into frame 1. Specialized secondary panels are retained.
- Grid2 themes and Danders automatic raid layouts receive the layout geometry
  too. Their indicators and conditions are retained. Other profile assignments
  remain under the addon's own control.
- Hardlocked VuhDo profiles and an unfinished Danders automatic-layout editing
  session must be unlocked/closed before applying.
- The LUI raid artwork attaches to the chosen frames and matches their size.
  This setting is also available under Artwork > LUI Panels. Danders is included
  in the raid presets and suppresses duplicate native LUI raid frames.

## Source contracts checked

| Addon | Release | Relevant source |
| --- | --- | --- |
| Grid2 | 4.1.11 | `GridLayout.lua`, `GridFrame.lua`, `GridLayoutLayouts.lua` |
| VuhDo | v3.220 | `VuhDoNewOptionsGeneralSkinsShared.lua`, `VuhDoDefaults.lua` |
| HealBot | 26.11.06.2 | `HealBot_Vars.lua`, `HealBot_Panel.lua`, `HealBot_Action.lua` |
| Danders Frames | v5.6.2 | `Core/Profile.lua`, `Core/AutoProfiles.lua`, `Frames/Position.lua` |

The adapters change settings owned by LUI or the selected external addon. They
do not modify embedded oUF, install addons, disable other addons, or run at
login. Raid-frame changes are followed by a reload so the respective addon
builds its own secure frames.

## Validation

`lua5.1 tests/addon_setups.lua` exercises the actual LUI options callbacks with
addon API fixtures: repeated application, profile identity, retained healing
settings, automatic layouts, all raid groups, combat, multiple loaded addons,
hardlocked profiles and a profile change during confirmation. These are local
checks; Retail and Forever in-game verification is still required.

The existing Guide screenshots describe the older action-bar copy behavior
and the former placement under General > Welcome.
Refresh the setup section and its screenshots after the in-game layout review.
