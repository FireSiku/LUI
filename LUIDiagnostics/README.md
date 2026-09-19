# LUI Diagnostics 0.1.2-alerttrace — test version

An optional addon bundled beside LUI and LUIOptions. Open **LUI DEBUG** in the
LUI options, then **Open LUI DEBUG**. `/luidebug` and `/lui diagnostics` open the
same guided window. The existing `/lui debug` developer command is unchanged.

## Targeted action-bar investigation

This test build adds an explicit `/luidrag start` mode, used outside combat.
It starts a new diagnostic session and reloads the interface. It also enables
Blizzard's `taintLog=2` until `/luidrag stop` or the normal diagnostics stop.
The previous taintLog setting is retained and restored when stopping, unless
the setting has since been changed externally. Stop after reproducing the
problem; this native log is more verbose than normal diagnostics.

When dragging fails, use `/luidrag` **before reloading** to pin the current
state, then `/luidrag stop` outside combat to save and reload. Send both:

- `World of Warcraft/_retail_/Logs/taint.log`
- The `LUIDiagnostics.lua` SavedVariables file described below.

The trace reads all 96 standard action buttons, their visibility, grid and
selected Lua-field taint status, the PlayerSpells window/tab, unspent talent
flags and the microbutton's suggested tab/spell. Close-button texture and
ancestor protection are included to investigate the red close button.
Active HelpTip ownership and the action-bar highlight table's taint status
help verify the level-up/talent-alert correction in diagnostic version 0.1.2.
It never invokes Blizzard click/tab/update methods or hooks native controls.
Only changed samples are retained at half-second intervals (40 per session),
plus up to three pinned failure markers. Talent/action events and first error
occurrences add context. Short-lived transitions can fall between samples.
Taint ownership does not by itself establish the originating bug; inspect
Blizzard's propagation log alongside the snapshots. Existing log contents are
not deleted. Match timestamps to the new session.

## Recording and sharing

1. Open the window and click **Start diagnostics...**.
2. Read the explanation, then confirm **Start & reload UI** outside combat.
3. Play normally until the problem occurs. Recording continues through combat,
   UI reloads and logins on this account until explicitly stopped.
4. At a safe moment, choose **Stop diagnostics...**, then **Stop, save & reload UI**.
5. The sharing instructions open automatically. **Copy report** shows the latest
   session. Select all, press Ctrl+C (Cmd+C on Mac), and paste into Discord or a
   text file. Long reports are easier to share as an attachment. Keep the
   `END OF REPORT` marker.

The complete SavedVariables file contains up to three sessions:

`World of Warcraft/_retail_/WTF/Account/<account folder>/SavedVariables/LUIDiagnostics.lua`

WoW writes the latest data on a normal reload or logout. A crash/forced exit can
lose data not yet written. Share this one file, not LUI.lua, its .bak backup or
your entire WTF folder. Nothing is sent automatically. The Discord address in
the window is the one already present in LUI's localization files.

## What is recorded

- General Lua errors and their stacks through an installed, enabled !BugGrabber.
  Both current EventRegistry releases and older CallbackHandler releases are
  supported. BugGrabber and BugSack are not bundled or replaced by this addon.
- Native ADDON_ACTION_BLOCKED, ADDON_ACTION_FORBIDDEN and LUA_WARNING events,
  including repetitions that BugGrabber may suppress. These work without
  BugGrabber. The window states when general Lua error capture is unavailable.
- Time, combat status, instance type, a small fixed list of relevant window
  states, active LUI modules, WoW/LUI versions, and loaded addon versions.
- A bounded trail of event names before errors. No roster content is requested.

Error groups retain the context and preceding events from their **first**
recorded occurrence, plus the latest occurrence time and a repeat count. A
native event uses a matching BugGrabber stack when available; otherwise its
stack is explicitly labelled as the diagnostic event handler, which need not
be the original failing call. Addon attribution is not proof of the cause.

Only events observed after the recorder starts are enriched. Earlier load
errors can still be present in BugGrabber; this addon does not invent their
missing context. BugGrabber can throttle errors during a flood, so its Lua
error callbacks are not guaranteed to cover every occurrence.

## Bounds and separation

At most 3 sessions, 40 error groups and 60 recent events per session. Each new
error group retains up to 8 preceding events, 3,000 message characters and
10,000 stack characters (with truncation markers). Up to 5 new groups per second
receive a full snapshot. Repeated groups increment their count. Evictions,
throttled captures and internal capture failures are included in the report.

The report owns copies of scalar data. It does not save error locals, LUI
profiles, chat history, guild/friend rosters or raw Blizzard UI tables. Error
messages or stack text may themselves include names: inspect before sharing.
Forbidden frames and secret values are treated as unavailable/restricted.

`LUIDB.global.Diagnostics` holds only activation/return-screen flags. The
separate `LUIDiagnosticsDB` SavedVariable owns all diagnostic records.
The recorder is load-on-demand; when disabled it is loaded only when opening
the wizard or returning to the sharing screen, and has no capture listeners.
The fixed LUI options entry is not a toggleable module. Disabling or removing
the LUIDiagnostics addon in WoW's AddOns list prevents it from loading and the
launcher explains the problem.

## Implementation and verification

No global error-handler replacement, protected Blizzard UI hooks, tabard
getter probes or automatic Discord uploads. Ordinary diagnostics does not
change CVars. Only the explicit action-bar trace changes taintLog as above. The old
LUIAvatarCheck addon is a separate specialist tool; this addon does not reuse
its active tabard sampling.

Lua syntax and simulated behavior checks cover activation, reload persistence,
stop/save flow, both BugGrabber interfaces, native-event deduplication, absent
BugGrabber, history bounds, secret/forbidden values and combat confirmation
races. This package has **not** been run inside WoW; actual window rendering,
client load behavior and error capture must be checked in game before release.

Reference interfaces inspected:

- LUI core: https://github.com/FireSiku/LUI/blob/master/LUI.lua
- LUI packaging: https://github.com/FireSiku/LUI/blob/master/.pkgmeta
- Current BugGrabber: https://repos.wowace.com/wow/bug-grabber/trunk/BugGrabber.lua
- Legacy callback API: https://github.com/Beast-Masters-addons/BugGrabber/blob/master/BugGrabber.lua

## Changelog

0.1.0: Initial guided diagnostics window, separate load-on-demand recorder and
SavedVariables file, optional BugGrabber integration, bounded context snapshots,
combat-safe start/stop confirmations, automatic reload flow and copy/file export.
