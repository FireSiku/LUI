# Selective layout sharing

The first implementation is under **Profiles > Layout Snippets**, alongside the
existing full-profile import/export. The guide and screenshots will be updated
after in-game review.

The full-profile page and snippet sharing/import pages explain that processing
large settings can briefly freeze the game. Users should wait for processing to
finish. Include this notice in the guide update and community explanation too.

## Player workflow

1. On **Share**, give the snippet a name, confirm the name with Enter, select
   LUI sections and generate the string. Copy the complete `!LUISnippet:1!` string.
2. Share the string in a text attachment or preset post. A future gallery can
   pair strings with screenshots and client/resolution information; this change
   does not create a website or upload anything from the game.
3. On **Import**, paste the string, click **Accept** below the text box, then
   click **Read Snippet**. Inspect its name, LUI version and source client.
   Choose which contained sections to import. Clicking Read before Accept
   reads the previously confirmed text and can clear an unconfirmed paste.
4. **Apply to Current Profile** names the target profile and affected sections
   before confirmation, then reloads the interface outside combat.
5. **Restore > Undo Last Snippet Import** restores the previous settings for the
   affected sections. It reloads outside combat and leaves other sections alone.

Each selected section includes its saved settings and positions. This version
does not split individual unitframes, colors, fonts and positions into separate
subsections. Existing full-profile strings continue to use **Profile Import /
Export** and their own named-profile workflow.

### Sharing destinations

On 10 November 2026, Wago's live import form rejected a valid synthetic LUI
snippet with **Invalid import**. Nothing was submitted or published. Do not
recommend Wago's general snippets search as an established LUI upload route.
Native recognition needs support from Wago's maintainers. Their official
[import-string request form](https://docs.google.com/forms/d/e/1FAIpQLSdYdCJuXGx29oAkmzvkgbEnGSlWzXFld_qpChJhfNq2VvBjPA/viewform)
accepts addon format details and an example string. See
[the LUI format reference](wago-import-format.md) for that preparation.
Dedicated browsing, UI Packs and automatic companion updates are separate
capabilities and are not implemented by the snippet feature.

A Discord forum post with a screenshot and the complete string as a `.txt`
attachment can use the same workflow. A curated guide page can link to such
presets later. Plater's executable scripts/mods are a different feature from
the settings-only sharing implemented here.

## Included and retained data

Supported sections: Artwork, Bags, Chat, Colors, Experience Bars, Infotext,
Micromenu, Minimap, Mirror Bar, Tooltip, UI Elements and Unitframes. Registered
child namespaces travel with their parent section. Module enable switches and
child-module switches retain the recipient's values.

The import replaces only checked sections of the active profile; it never
creates or switches profiles. Other profiles, root LUI settings, account-wide
records and external addon profiles are excluded. Different characters using
the same LUI profile continue to share its settings.

One account-wide recovery slot, `LUIDB.global.LayoutSnippetBackup`, stores the
previous selected sections and their profile name. A subsequent import replaces
that slot. Restore is available only while that same profile is active.

**Colors** shares the common palette. Elements using a shared class color can
therefore change even when their module is not selected. Individual colors are
part of their own module's snippet. **Themes** is deliberately excluded: loading
a theme can recolor several otherwise unselected modules. Artwork exports its
saved colors without changing the recipient's global theme library.

Strings contain data serialized by the already bundled AceSerializer, never
Lua source to evaluate. Import validates the format, known sections, registered
namespaces, finite scalar data, depth (30), value count (100,000) and text size
(2 MB). All selected writes are prepared before any profile is changed. The
live AceDB tables are updated in place so logout cleanup cannot retain a stale
cached profile. Cross-client snippets identify their source; missing child
components reject the import before writing.

## In-game review

On 10 November 2026, Pahn confirmed the basic Unitframes round-trip on Forever
in a separate test profile: export, change player-frame width, import the
snippet to recover the exported width, then Undo to recover the changed width.
The import and Undo both completed their automatic reloads successfully.
An additional Unitframes-only import retained the enlarged LUI chat font and
the enabled Chat module; the settings also survived logout and login.
For this check, change font size in **Chat > General Settings > Font**.
Blizzard's chat-tab font-size menu does not update LUI's saved font setting.
The remaining cases below still need their own in-game checks.

- Export Unitframes from a configured source profile. Import only Unitframes
  into a different existing profile; check its chat, artwork and bags afterward.
- Reload and relog, then check the imported settings again. Test Undo and verify
  that unrelated changes made after import remain.
- Repeat imports and check that the profile list does not grow.
- Try a Chat snippet with child modules disabled and confirm their switches stay
  disabled. Try individual Artwork colors and a shared Colors palette separately.
- Check confirmation races, combat blocking and Retail/Forever source labels.
- External frame anchors, media availability and screen/UI scale can differ;
  review the visual result before sharing a preset as ready to use.

Local checks use the test package's unmodified AceDB and AceSerializer with the
real LUI option callbacks, including shutdown cleanup and reopening storage.
Actual in-game rendering and compatibility still need the review above.
