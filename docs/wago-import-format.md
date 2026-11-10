# LUI import formats for Wago support

Prepared 10 November 2026. This is a format reference for a support request,
not a claim that Wago accepts LUI. The live Wago import form currently rejects
the layout-snippet format. No request or import has been submitted.

## Project

- Addon: LUI Core, maintained by Siku / FireSiku.
- Source: <https://github.com/FireSiku/LUI>
- Layout-snippet implementation: <https://github.com/FireSiku/LUI/pull/109>
- Scope: Retail and Warcraft Forever. The separately maintained Classic addon
  is outside this request.
- Selective layout snippets are planned for v2611 and are still being tested.

The official support request is at
<https://docs.google.com/forms/d/e/1FAIpQLSdYdCJuXGx29oAkmzvkgbEnGSlWzXFld_qpChJhfNq2VvBjPA/viewform>.
It asks for a contact and the addon's Wago Addons URL. The contact and any
existing Wago listing must be confirmed by the maintainers before submission.
Do not create a new addon listing on their behalf as part of a format request.

## Encoding

Both formats are a literal prefix followed by **raw AceSerializer-3.0** output.
There is no LibDeflate compression, base64 or EncodeForPrint layer. The body
normally begins with AceSerializer's `^1` marker and ends with `^^`.

Strip only the matching prefix and pass the body to AceSerializer:Deserialize.
Treat the result as settings data. Never evaluate it as Lua. The payload must
match the prefix's kind and format; do not guess unsupported future versions.

When exposing a decoded table as JSON, preserve Lua key types on export.
Numeric keys, numeric-looking string keys and boolean keys are valid LUI
settings keys. A normal JSON object and a blanket numeric-key conversion
cannot safely represent all such tables. The copied import string must remain
compatible with LUI's existing importer; an unchanged source string can be
preserved without reserialization.

## Layout snippets

Prefix: `!LUISnippet:1!`

The decoded table contains:

| Field | Meaning |
| --- | --- |
| `kind` | Exactly `LUI_SNIPPET` |
| `format` | Exactly numeric `1` |
| `name` | User-provided non-empty title, at most 100 bytes, no control characters |
| `client` | Exactly `Retail` or `Forever` |
| `addonVersion` | LUI version string, at most 100 bytes |
| `sections` | Non-empty map of named LUI sections to captured settings |

Allowed sections: Artwork, Bags, Chat, Colors, Experience Bars, Infotext,
Micromenu, Minimap, Mirror Bar, Tooltip, UI Elements and Unitframes.
Each captured section has a `profile` table and may have a `namespaces` map
of child settings with the same structure. It contains no account-wide data,
other profiles or external addon settings. Themes is deliberately excluded.

LUI validates a maximum of 2,000,000 bytes of input, 100,000 visited values and
depth 30. Values must be finite numbers, strings, booleans or tables. The
importer accepts only known sections and registered child namespaces. It
imports the selected sections into the current profile, preserves module
enable switches and keeps one backup of the previous selected settings.

Suggested Wago metadata: use `name` for the title, `client` for Retail/Forever,
and the contained sections for filters. Do not add a Wago ID or other fields
inside a section's captured storage; the importer rejects unknown scope keys.

## Full profiles

Prefix: `!LUIProfile:1!`

The decoded table contains `kind = LUI_PROFILE`, numeric `format = 1`,
`addonVersion`, `profileName`, `data`, and optional `resources`.
`data` has a `profile` table and optional nested `namespaces`. `resources`
carries any selected named LUI theme or unitframe-layout resources needed by
the profile. It is not an export of all account settings or other addons.

Full profiles do not currently contain a source-client field. Wago must ask
the uploader to choose Retail or Forever rather than infer it from the LUI
version or profile name. Import these through **Profile Import / Export**,
not through **Layout Snippets**.

## Requested behavior

The initial request is for manual website sharing: recognize the two formats,
show an LUI category, and let users copy a compatible string back into LUI.
Screenshots, descriptions, resolution, UI scale and required external addons
belong in the Wago post. Settings strings do not contain executable scripts.

Wago UI Packs use an additional profile-management API described by
<https://github.com/methodgg/Wago-Creator-UI/blob/main/WagoUI_Libraries/LibAddonProfiles/ImplementationGuide.lua>.
That API and automatic update handling are not implemented or requested by
this initial format-sharing preparation. Do not promise those capabilities.
