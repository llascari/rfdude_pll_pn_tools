# Development handoff

Updated: 2026-11-01, setup GUI list/linear/logarithmic sweep selection.

## Current objective

Port the 2002 Mathcad PLL worksheet
(`pll_synth/Mathcad - RFdude_pll38_PDFversion.pdf`) to Octave-first,
MATLAB-compatible code in `pll_synth/`, adding features through small,
targeted changes that preserve the existing form and style (see `AGENTS.md`).
Current follow-up: a sweep-type dropdown in the setup GUI, retaining the
existing runner's numeric sweep vector and saved-data format. The shipped
ROS profile/fixed-filter demonstration remains unchanged.

## Repository checkpoint

- Branch `main`. The November 1 sweep-type selector, deferred GUI run,
  sweep plot suppression and sweep progress lines were committed and pushed to
  `origin/main` on user authorization (the commit after `dfe7985`; see
  `git log`). The ROS demonstration is committed in `ca8cf27`. The untracked
  user script `pll_synth/aa_run_user_config_XXXX_design.m` was preserved and
  deliberately left uncommitted. No normal setup state or result files were changed.
- Historical October 31 checkpoint: HEAD `e4ab61b` ("awesome progress"), following
  `4b545ab` ("generated test example") and `bb65e12`
  ("Add Octave-first PLL configurator and reloadable analysis viewer").
  The new PN-profile/example work below remains local and uncommitted.
- The October 26 work below was committed in `9a9497e`. The worktree was clean
  at the start of the October 31 review.
- October 31 commit scope: this handoff,
  `AGENTS.md`, `pll_synth/pll_synth.txt`, small additive changes in the existing PLL core,
  and new configurator, runner/generator/validation helpers, viewer and tests.
  User authorized committing and pushing this scope to `origin/main`.
  The user-created `pll_synth/aa_run_user_config_XXXX_design_TEST.m` is left
  local and untracked; last GUI state and generated results remain ignored.

## Completed October 26 (committed in `9a9497e`)

1. **`AGENTS.md`** (new): strict rules for targeted changes that preserve form
   and style, plus a pointer to the Mathcad PDF as a historical reference.
2. **Small-signal transient** (`bDoTransient`), in `rfdude_pll_oct_0p1.m` after
   the `PM_actual` calculation. Linear closed-loop frequency-step response using
   the actual loop filter, with a first-order Pade approximation of the PFD
   half-period delay. Computed exactly with a matrix exponential (~1 s; it was
   ~45 s with `ode45`, same results). Reports settling time within
   `transient_ftol_Hz`, plots, and saves `_transient`.
3. **Nonlinear transient** (`bDoTransientNonlinear`), directly after item 2.
   Edge-driven tri-state PFD and charge pump, actual C1/R2/C2/R3/C3 filter
   (exact matrix-exponential step, charge-conserving pulse averaging), VCO
   phase, optional VCO tuning range limits. Reports settling time and
   cycle-slip count, plots frequency and PFD phase error, overlays the
   small-signal curve when both are on, and saves `_transient_nl`.
4. Both blocks are tagged `%%NOTE (copilot assist)`, default **off**, and read
   their settings with `isfield`, so older input files still run unchanged.
   Settings are in `aa_RunPllDesign_XXXX.m`; usage, limitations and
   references are in `pll_synth/pll_synth.txt`.

References credited (in code comments and `pll_synth.txt`): Banerjee,
*PLL Performance, Simulation, and Design*; Best, *Phase-Locked Loops*, 6th ed.;
Gardner, *Phaselock Techniques*, 3rd ed.; Gardner, "Charge-Pump Phase-Lock
Loops," IEEE Trans. Commun., 1980; Perrott, DAC 2002 behavioral simulation.

## Validation (run 2026-10-26)

Default design from `aa_RunPllDesign_XXXX.m` (445 MHz, 100 kHz PFD, 2 kHz BW),
parameter-based noise (no data files), figures hidden.

| Environment | Check | Result |
| --- | --- | --- |
| Octave 11.3.0 | Both transients off | Runs as before; no transient code executed |
| Octave 11.3.0 | Small-signal, 5 kHz step | 0.2952 ms; matches old `ode45` to 6e-8 Hz |
| Octave 11.3.0 | Nonlinear, 5 kHz / 30 MHz / 100 MHz steps | 0 / 0 / 4 slips; 0.39 / 1.87 / 2.32 ms |
| Octave 11.3.0 | Nonlinear, 25 vs 400 steps per ref period | Within ~0.1%; default 100 is adequate |
| Octave 11.3.0 | Figure saving (JPG) | `_transient` and `_transient_nl` written |
| MATLAB R2025a | Both on, 100 MHz step | 2.0496 ms small-signal, 2.3211 ms nonlinear, 4 slips; identical to Octave |

Note: `pll_synth/demo1.m` and the `pn/` tools were not exercised.

## October 31: PLL run configurator, runner and viewer

Reviewed `pll_synth/aa_RunPllDesign_XXXX.m`, relevant core input/filter/output
handling, the historical PDF's input organization, and the neighboring
`rfdude_comms_tools` SCM/OFDM outer scripts and parameter-sweep functions.

The existing split is suitable: a readable outer script fills `pll_inputs_s`,
calls the existing analysis script, and computes integrated noise/EVM/residual
FM. The modem workbenches likewise expose single/sweep mode and parameter
values in the outer script, with separate per-point execution and aggregation.

Implemented under the user's direction:

- `bb_pll_setup_gui.m`: grouped native controls with persistent edits, file
  browsing, dependent-field enablement, single/sweep controls and final
  "Run the script"/"Enable data viewer after run" checkboxes. Generating without
  running is supported. Local `_pll_setup_last.mat` restores even unfinished
  entries, section, script name and checkboxes; "Reset everything" confirms
  before restoring defaults. The existing `_` output ignore rule covers state.
- `rfdude_pll_configuration.m` reads defaults from the human-created runner;
  `rfdude_pll_parse_value.m` accepts numeric literals/lists/ranges without
  executing expressions. `rfdude_pll_validate_configuration.m` validates
  dependencies, units/ranges, synthesis phase-delay limits and noise files.
- `rfdude_pll_generate_script.m` preserves explicit assignments, comments and
  parameter ordering in `aa_run_user_config_...m`. Generated scripts retain
  the original clc/close-all/clear startup and expose familiar single-pass
  output names, plus `PLL_DATA_s`. Tool paths are relative to the script.
  Follow-up: every editable setting now has a nearby explanation of units,
  dependencies and behavior, with fuller sweep/output/metric guidance.
  Existing inline comments are retained and the blanket file-metadata
  override note is corrected in generated scripts only.
- `rfdude_pll_run.m` executes the existing core in a fresh per-case workspace,
  synthesizes at each design target and applies the same component overrides.
  Bandwidth/phase margin/PFD frequency/charge-pump current/output frequency
  sweeps are supported; component tolerances are out of scope. Full overrides
  with bandwidth/phase-margin target sweeps are rejected as ineffective.
- Per-point exports live in `<basename>_cases/`; `<basename>_data.mat` is
  checkpointed before execution and after each point, retaining pending/failed
  status. `bOverwriteResults` defaults on; set it off to protect existing
  results. The dataset embeds settings, actual components, noise/source curves,
  metrics and enabled transient traces.
- `cc_pll_data_viewer.m` opens datasets independently or after a run, with
  phase-noise and transient surfaces/3-D contours, point selection/overlays,
  requested/achieved BW/PM, components, offset noise, integrated phase/EVM,
  residual FM, model-specific settling and cycle slips. 3-D surface/contour
  views enable interactive drag rotation; 2-D views disable rotation.
  Display-only transient resampling is limited to 1000 points; full traces
  remain stored.
- Core changes only isolate figure numbers via an optional input, honor
  existing pn_ylimits, and restrict noise MAT loading to pn_struct (preventing
  unrelated saved variables from corrupting the new run workspace), plus
  explicit file-only PDF/JPEG exports described below.
- All new MATLAB/Octave files and generated scripts carry a Copilot-generated,
  under-Lance-Lascari-direction header. Usage is in `pll_synth/pll_synth.txt`.

Fresh validation: Octave 11.3.0 (Qt) and MATLAB R2025a Update 1.

```sh
octave --no-init-file --no-site-file --no-gui --quiet --eval "addpath('pll_synth'); test_pll_run_tools();"
matlab -batch "addpath('pll_synth'); test_pll_run_tools();"
```

Tests cover numeric parsing/validation; direct-core numerical equivalence;
generated single/sweep scripts; fixed R3/C3 and varying C1 across 1/2/4 kHz
bandwidth targets; both transient vectors; distinct disabled/not-settled
statuses; automatic viewer launch; all 20 viewer modes; saved-data reopening
after removal of synthetic source files; existing-figure preservation; and
GUI navigation/unfinished-entry restoration using isolated temporary state.
The October 31 follow-up also verifies the overwrite-on default, a successful
rerun with overwrite enabled, protection when disabled, the default GUI
checkbox, and rotation guidance on each 3-D viewer mode.
No hardware or local measurement files were used. Existing residual-FM and
MATLAB complex-plot warnings remain visible; no claim of residual-FM accuracy.
The Octave QSocketNotifier startup message also remains.

Follow-up policy recorded in `AGENTS.md`: GNU Octave first; maintain and
perform MATLAB compatibility testing when it does not slow development.
MATLAB use is authorized on this computer. Focused or parallel checks are
preferred; record deferred compatibility coverage without blocking Octave.
The same regression commands above were freshly rerun after the generated
comment changes and passed in both runtimes. Additional assertions check
comment coverage for every editable setting, retained original comments,
Octave-first/Copilot headers and corrected file-input guidance.

Printer fix: all 12 core figure exports now pass an actual figure handle and
an explicit `-dpdf` or `-djpeg` driver instead of relying on MATLAB's print
argument/default-driver interpretation. Existing output names and switches
are retained; already-generated scripts use the corrected shared core.
The regression commands above were freshly rerun and passed in Octave and
MATLAB with both export flags enabled and both transient models enabled.
Tests verify all six expected PDFs by their `%PDF-` signatures and all six
JPEGs via image metadata. Earlier tests had disabled figure saving, so they
did not cover this behavior. No printer configuration or queued jobs changed.

Coverage limit: native save-file/overwrite/reset modal dialog clicks are not
automated in the regression suite. MATLAB batch disallows blocking dialogs;
an attempted display-enabled reset test produced a timer callback diagnostic
and was removed rather than counting it as reliable automated coverage.
The user reported clicking a button in the popped-up test GUI; that run used
isolated temporary setup state, not the normal last-inputs file, and is not
counted as an automated reset validation.
Normal local Octave startup previously reported unrelated PETSc-path/audio
package issues; no startup files or packages were changed.

## October 31 follow-up: overwrite default and interactive plots

`bOverwriteResults` now defaults to 1 in the shared configuration, so the GUI
and generated scripts start with overwriting enabled. Set it to 0 to preserve
existing datasets/case files and reject a conflicting run. Overwrite does not
delete surplus case files from a previous larger sweep.

The viewer now enables `rotate3d` for 3-D surface/contour plots and disables it
when returning to 2-D views. The status text and `pll_synth.txt` explain that
the plot can be dragged to rotate. Updated run-option comments and usage docs
match the new default.

The focused regression commands above were rerun after these changes and
passed in Octave 11.3.0 and MATLAB R2025a Update 1. They include a repeat run
to verify overwrite behavior and the explicit opt-out. Batch tests exercise
all viewer modes; physical mouse dragging remains an interactive GUI check.

## October 31 follow-up: locating saved viewer datasets

The viewer's no-argument picker now starts in `pll_synth/`, defaults to
`*_data.mat`, and offers folder selection by passing a directory. The viewer
reports that legacy core `<basename>.mat` and per-case `*_caseNNNN.mat` files
contain `pn_struct`, not a reloadable `pll_data_s` dataset. Usage guidance was
added to `pll_synth/pll_synth.txt`. The existing
`_rfd_pll_Design_XXXX_data.mat` opens successfully.

The Octave 11.3.0 and MATLAB R2025a Update 1 regression commands pass with a
test for the legacy-file diagnostic. Physical file-picker interaction is not
automated.

## October 31 follow-up: fixed 3D camera views

The viewer provides Top, Bottom, Front, Back, Left, Right, Iso and 2D
projection buttons for rendered 3D surfaces/contours. They are disabled for
views that do not render a multi-case surface. Mouse rotation remains enabled.
The regression suite checks availability for all viewer modes and invokes
front, 2D and isometric presets. One test explicitly returns to a 3D surface
before invoking camera buttons because the controls correctly disable on the
last (2D) viewer mode. The full regression command passed in Octave 11.3.0
and MATLAB R2025a Update 1.

## Public release context and license review (MIT approved; release in progress)

Inspected the public `rfdude_pn_pll_tools_0p001.zip` at
`https://www.rfdude.com/s/rfdude_pn_pll_tools_0p001.zip`: it is a 35-file
standalone `pll_synth/` plus `pn/` package, with old run/core scripts, PN
utilities, four shipped CSV measurement traces and minimal READMEs. Its README
calls the tools personally developed and shared with colleagues/employers at
the author's discretion. `rights.txt` says sharing is limited, that the author
was not ready to open-source, and leaves rights as TBD. Several core files and
PN utilities differ from the current versions; the current repository adds the
configurator, runner, reloadable viewer, tests, Mathcad reference, and project
handoff/instructions. The published archive is historical context, not an
open-source license grant.

Initial license recommendation, not yet approved or implemented: MIT is the
simplest fit for encouraging unrestricted use and forks; BSD-3-Clause is a
similar permissive alternative with an explicit no-endorsement clause; Apache
2.0 is worth considering if an explicit patent grant is important. Before a
repository-wide license is added, verify distribution rights for the legacy
worksheet/reference PDF, bundled measurement traces, and any code made during
paid work. Do not remove `AGENTS.md`, `DEVELOPMENT_HANDOFF.md`, Octave/MATLAB
compatibility guidance, or Copilot-origin notes/headers as part of release
cleanup. GitHub documents separate repository settings to disable both Issues
and Pull requests; no repository settings were changed.

Release decisions (user, 2026-10-31): MIT, `Copyright (c) 1999-2026 Lance
Lascari`, matching the public RFdudeSmithChartV2 pattern (MIT + scope note,
NOTICE.txt, README as-is statement, Issues disabled). The user confirmed sole
ownership of the code, Mathcad PDF and four shipped CSV traces (no employer or
client claim); all are included under MIT. The PDF itself states "Personal
work of Lance Lascari (not of his employer!)". Policy: provided as-is, no pull
requests or issue reports, forks and modifications encouraged; updates may
change anything, so users should keep copies of versions they depend on.

Implemented locally: `LICENSE`, `NOTICE.txt` (Copilot role, no support,
Mini-Circuits ROS-2100-119+ transcribed-value/trademark attribution; the
datasheet PDF is not shipped), README opening/copyright lines, and deletion of
superseded `rights.txt`. The user's README "curmudgeon" paragraph is unchanged.

Pre-release audit: full Git history has no credentials/tokens or local
absolute paths; CSV traces contain no instrument serial/host identity. The
Mathcad PDF contains the author's historical public email addresses. One old
commit's author email is `llascari@rfdude54.localdomain` (hostname only);
history rewrite was not recommended.

Remaining, each requiring explicit authorization: make the repository public
last, since its full history becomes permanently copyable. Optionally replace
or redirect the old rfdude.com ZIP, whose `rights.txt` still says the tools
are not open source.

Done 2026-10-31 with authorization: license commit `f35d9d8` pushed to
`origin/main`. GitHub Issues, Wiki, Projects, Discussions and pull requests
were disabled (`gh repo edit ...=false`; pull requests via
`gh api -X PATCH repos/llascari/rfdude_tools -F has_pull_requests=false`),
and the description updated to the MIT/as-is/fork-freely wording. Read-back
confirmed all features false; visibility remains **private**.

History cleanup (user-authorized, 2026-10-31): one January 2026 commit's
author/committer email exposed a hostname (`...@rfdude54.localdomain`); it
was rewritten to `lance@rfdude.com` with
`git filter-repo --refs <parent>..main --email-callback ...`. Limiting the
range kept the 124 earlier commit IDs, including both GitHub-signed
September 2025 commits; an unrestricted run strips signatures and changes
every ID. The 11 later commits were rewritten (IDs in this file updated);
trees, messages, dates and names were verified identical to a backup bundle,
then force-pushed. Annotated tag `v2026.10` marks the first public-release
snapshot.

GitHub kept the replaced commit retrievable by ID in the old repository, so
the cleaned history and tag were pushed to a fresh private repository,
`llascari/rfdude_pll_pn_tools` (same description and disabled features,
verified; the old commit is not found there). The project name in the files
remains `rfdude_tools`. The old private `llascari/rfdude_tools` is retained
for now and is to be deleted (never made public) once the user is satisfied.
**Other clones made before this must re-clone from
`git@github.com:llascari/rfdude_pll_pn_tools.git`** (or set `origin` to it,
then `git fetch && git reset --hard origin/main` after saving local work).

Made **public** 2026-10-31 with user authorization:
https://github.com/llascari/rfdude_pll_pn_tools. Verified anonymous access
to the repository, `LICENSE` and tag `v2026.10`; contribution features remain
disabled. GitHub's license detector reports "Other" because of the added
scope paragraph in `LICENSE`.

## October 31 follow-up: selection behavior in aggregate plots

Aggregate/summary views already plot all completed cases. The case list now
allows only one selection in those views for the details pane, and its label
explains that the plot shows all cases. Ctrl multi-selection remains available
only for individual noise overlays, transient overlays, and nonlinear PFD
phase-error plots where the selected cases change the plotted curves.
Regression coverage checks the selector mode across every viewer view and
verifies that multi-selection is reduced to one case on returning to an
aggregate plot.

## Continue here

Checkpoint: October 31, 2026. After the viewer camera presets, aggregate-view
selection behavior, published-archive inspection, and preliminary license
research, the user requested preservation and documentation of the `pn_struct`
format across repositories and over time. `pn/pnformat.md` is now the
canonical legacy-format specification and moving-forward guide;
`pn/pnformat.txt` remains as a compatibility pointer. The user approved a
separate version 1 `pn_profile_s` wrapper containing ordinary legacy points,
with exact selection and explicit interpolation, rejecting extrapolation.
Historical PLL loaders and GUI/file-only callers still use the exported
`pn_struct`. The programmatic runner now offers explicit opt-in profile
selection; see the completed demonstration checkpoint below.

`pn/ros2100_extraction_example.md` is the complete use case and reusable LLM
request. `pn/aa_generate_ros2100_example.m` contains the explicit extraction
rows: 20 nominal band-characterization points with four noise offsets each,
plus the separate 20-offset trace at 1725 MHz. The latter's Kvco is explicitly
derived between the neighboring 1666.4 and 1727 MHz rows, not measured.
`pn/validate_pn_profile.m` and `pn/select_pn_profile.m` implement the approved
contract: potentially different offset grids, log-offset interpolation in
dBc/Hz, then linear-power carrier interpolation and linear Kvco interpolation.
Conditions, source rows and derivation remain in point comments.

Fresh validation passed in Octave 11.3.0 and MATLAB R2025a Update 1:

```sh
octave --no-init-file --no-site-file --no-gui --quiet --eval "addpath('pn'); test_pn_profile();"
matlab -batch "addpath('pn'); test_pn_profile();"
```

The tests isolate generated fixtures and cover scalar fields, carriers/gains,
detailed noise values, derived gain, overwrite protection, legacy MAT loading,
existing add/multiply consumers, exact selection, different offset grids,
interpolation policy, rejected extrapolation and invalid input. Independent
comparison against the local PDF text matched all 140 band-table entries and
40 detailed-table entries, with a disputed 1403.0 MHz value checked visually
at higher magnification. A MATLAB-only initialization issue was corrected
before the final passing tests. Optional plotting and an actual PLL run were
not exercised; Octave's QSocketNotifier startup message remains.

The generator was also run normally in Octave, producing ignored local
`pn/datfiles_local/ROS_2100_119_profile.mat`. MATLAB loaded that file and
selected/exported 1800 MHz; Octave reopened that MATLAB v7 legacy export.
The temporary round-trip export was removed; the normal profile output remains.
The source PDFs remain in `~/Downloads`, not in the repository. Generated
data do not require those PDFs to load or regenerate from the script.

Plot/rerun follow-up: `plot_pn_array.m` now sets legend Interpreter to none,
matching neighboring plot tools. The ROS generator uses display-only carrier
labels in two columns, with saved point names unchanged. Repeated execution
replaces only its tagged plot; other figures remain untouched. Preserve the
user's enabled `bSaveData`, `bOverwriteData` and `bPlotData` settings. The
test suite normalizes settings only in its isolated generator copy. The full
focused profile tests and two plotting/saving runs in isolated folders passed
in Octave and MATLAB; all 21 entries and unrelated figures were checked, and
an Octave-rendered legend was visually inspected. No local MAT was overwritten
during these follow-up checks.

Tuning-plot follow-up: `bPlotData` also creates a separate tuning-sensitivity
versus carrier-frequency figure (MHz/V versus MHz), connecting the 20
tabulated values and marking the derived 1725 MHz gain separately. Its tagged
figure follows the same rerun replacement policy. Focused isolated checks
passed in Octave and MATLAB for exact plotted coordinates, derived marker,
replacement of both plots and preservation of an unrelated figure.

Google Search AI Overview selected a 122.88 MHz CVHD-950 variant, whereas
the supplied datasheet's noise table is specified at 100 MHz. Google AI Mode
returned an LMX2594 answer with unverifiable graph/trace claims and a wrong
Figure 16 page citation. Correction to the earlier handoff: local Figure 16
is on printed/PDF page 16, not page 14; Figure 7 is on page 14. Treat AI output
only as a lead to check against the PDF, not extracted data.
Earlier viewer changes passed `test_pll_run_tools()` in Octave 11.3.0 and
MATLAB R2025a Update 1.

Worktree changes are local and uncommitted; do not commit or push without
authorization. `pll_synth/aa_run_user_config_XXXX_design_TEST.m` contains a
local five-value bandwidth sweep (`[500 1000 2000 5000 10000]`) and updated
overwrite comments. Preserve that user edit. Earlier ignored setup state and
generated results remain machine-local.

Next: review the ROS example and its deliberate distinction between typical
characterization and the specified 1350-2100 MHz band. Apply the same extraction
workflow to CVHD-950 or LMX2594 if requested. Use the new opt-in programmatic
profile input when frequency-dependent characterization is wanted; do not
silently change existing file-input behavior. Resume GUI testing as useful.
Public release: MIT license committed/pushed and GitHub contribution features
disabled (see the release section above); published publicly as
`llascari/rfdude_pll_pn_tools`. Remaining: deletion of
the old private `rfdude_tools` repository. Retain all Copilot-origin
notes/headers and project/tooling documentation, especially Octave/MATLAB
compatibility guidance.

Other optional next steps (not requested):

1. Nonlinear model refinements: PFD reset delay / dead zone, charge-pump
   up/down mismatch and leakage, charge-pump output compliance limits.
2. Remaining Mathcad worksheet features not yet ported (see the PDF feature
   list, e.g. two-point modulation, reciprocal mixing / adjacent channel
   estimate, cascaded synthesizers, optional loop amplifier).
3. Optionally write transient results (settling time, slips) into the CSV
   report or `pn_struct` output; currently they are printed and plotted only.

## October 31: shipped ROS fixed-filter PLL demonstration

Implemented the user-approved five-carrier demonstration, retaining explicit
human-readable settings, units, derivations and Copilot-under-direction credit:

- Root `demo_2026.m` prints source/extraction notes, regenerates the ROS profile
  in its own output directory, shows both source plots, and pauses for a
  command-window keypress. Set `demo_pause_for_key=0` for unattended runs.
- `pll_synth/aa_demo_ROS_based_synthesizer_runPLL.m` designs all components
  at 1725 MHz for 5 kHz bandwidth and 55-degree phase margin, without full or
  third-pole overrides. It copies the exact center components into a full
  override for 1350/1537.5/1725/1912.5/2100 MHz. Noise/Kvco vary per carrier;
  the loop is not redesigned at each point. The center uses the detailed
  stored noise curve and its explicitly derived gain; four band points are
  modeled from neighboring characterization.
- `rfdude_pll_run.m` adds opt-in `run_options_s.vco_profile_s`, requiring VCO
  file mode and selecting at `fout_desired_Hz/mult`. Each case saves its
  selected scalar as `<case_basename>_vco.mat`; results embed unextended
  `vco_characterization` and `vco_selection_s`. The saved configuration
  embeds the full profile and `center_design_s` inputs/components/metrics.
  The existing core and GUI/file-only behavior are unchanged.
- The viewer now displays nested scalar settings recursively and summarizes
  profile-point arrays rather than dumping every curve. Per-case details
  include source/derivation and selection evidence. This fixes structured
  settings preventing viewer creation and saved-data reopening.
- The generator's optional `ros_example_options_s` accepts four output/plot
  switches only. The demo uses it without editing source rows or replacing
  the normal local ROS MAT. Root and standalone scripts keep unrelated plots.
- README, PLL usage, PN format and worked-example docs describe the complete
  workflow. The Mathcad filter-synthesis/PFD-delay reference was consulted;
  no core synthesis/transient equations were changed for this demonstration.

Fresh numerical demo results agree in Octave 11.3.0 and MATLAB R2025a Update 1:
center achieved **5027.83594 Hz**, **54.893859 degrees** (nearest log-grid
crossover, within one grid step of the 5 kHz target). The five achieved
bandwidths are **7037.22924, 5703.46556, 5027.83594, 4074.9119, 3036.33859 Hz**.
Tests verify five distinct selected gains and identical exact components.

Reproducible validation from the repository root:

```sh
octave --no-init-file --no-site-file --no-gui --quiet --eval "addpath(fullfile(pwd,'pll_synth'),fullfile(pwd,'pn')); test_demo_2026(); test_demo_2026(true); test_pll_run_tools(); test_pn_profile();"
matlab -batch "addpath(fullfile(pwd,'pll_synth'),fullfile(pwd,'pn')); test_demo_2026(); test_demo_2026(true); test_pll_run_tools(); test_pn_profile();"
```

Both commands freshly passed after the final script/viewer changes.

`test_demo_2026()` isolates copied scripts with shortened transients and
exports off, testing reruns, standalone in-memory generation, source-plot and
unrelated-figure preservation. `test_demo_2026(true)` retains all default PLL
settings, including 15 ms transients, 12501 small-signal samples, 100 nonlinear
steps/PFD, and verifies six JPEGs plus a CSV per carrier. Both check source
noise/gain and saved scalar equality, center target/grid resolution, exact
fixed components, viewer structured evidence/modes and saved-data reopening.
Existing PLL and PN-profile suites check unchanged legacy behavior.

All test output/state is temporary and cleaned up; no local measurements or
normal ROS output were overwritten. Demo outputs regenerate offline in ignored
`pll_synth/_demo_2026/`; the profile, center and sweep data are not committed.
Reopen from the root with:

```matlab
addpath('pll_synth');
cc_pll_data_viewer('pll_synth/_demo_2026/_ROS_based_synthesizer_data.mat');
```

Coverage limits: automated tests disable the physical keypress and hide their
windows. Physical pause/mouse interaction remains manual. The default
10 Hz-200 MHz analysis and 100 Hz-1 MHz integration preserve historical
endpoint holding outside the ROS 1 kHz-1 MHz noise evidence; comments and
printed notices identify that assumption. These are offline typical-data
models, not hardware lock/noise guarantees. Existing residual-FM,
MATLAB complex-plot and Octave startup warnings remain visible.

Everything in this follow-up is local and uncommitted/unpushed. No new commit,
push, public-release/license decision or GitHub settings change was authorized.
Next: run the interactive root demonstration, tweak its exposed settings as
desired, and address the separate release/license decision only if requested.

## November 1: setup GUI sweep types

- `bb_pll_setup_gui.m` adds List, Start / stop / step, and Log (points per
  octave) choices. Only the selected type's fields are shown; all raw entries
  persist across mode changes, navigation and reopening. Reset uses the same
  existing confirmed-reset path. Old state files restore their existing list.
- `rfdude_pll_sweep_values.m` resolves the selected inputs to the ordinary
  numeric `run_options_s.sweep_values` vector. Linear mode follows colon
  endpoint behavior. Log mode requires positive endpoints and positive integer
  intervals per octave, supports either direction, and always includes exact
  stop (a shorter last interval was explicitly approved). Finite/distinct
  values and the existing 100000-entry limit are checked explicitly.
- Runner, generated-script layout, analysis equations and dataset format are
  unchanged. Only the chosen sweep type is resolved during generation;
  unfinished entries for other types are retained without being parsed.
  Usage and reproducible test commands are in `pll_synth/pll_synth.txt`.

Freshly passed in Octave 11.3.0 (Qt) and MATLAB R2025a Update 1:

```sh
octave --no-init-file --no-site-file --no-gui --quiet --eval "addpath('pll_synth'); test_pll_setup_sweeps(); test_pll_run_tools();"
matlab -batch "addpath('pll_synth'); test_pll_setup_sweeps(); test_pll_run_tools();"
```

The Octave suites were run separately with these same selectors. The MATLAB
combined command passed; the final focused sweep suite was then rerun in both
runtimes after the last small GUI/test changes. New tests cover three runnable
generated sweeps, exact list/linear outputs, logarithmic ratios/endpoints,
descending/equal/near-equal endpoints, wide dynamic range, allocation limits,
invalid inputs, mode visibility/enabling, controls within panel bounds,
unfinished-entry persistence and legacy state restoration. Existing numerical,
export, viewer and GUI regression coverage also passed. All normal test output
and state were isolated in temporary folders and cleaned up.

Coverage limits: physical dropdown/file-picker/reset clicks are not automated.
Native-control screenshot capture was unsuccessful (blank frame), so visual
appearance is not claimed as verified; visibility and layout bounds are tested.
Existing residual-FM, MATLAB complex-plot and Octave startup warnings remain.
No hardware, local measurements or normal ignored setup/result files were used.

Next: reopen the normal setup GUI and manually try all three modes.
The untracked user-generated run script present at task start was not edited.
Older sections' uncommitted-status notes are historical; the current checkpoint
above reflects the actual Git history.

## November 1 follow-up: GUI "Run the script" freezes

User report: generating with "Run the script" checked often locked up Octave
(Linux force-quit prompts), while running the saved script from the prompt
was fine. Cause (likely): the whole analysis ran inside the Generate button
callback, starving GUI event processing for the new plot/viewer windows.
Fix in `bb_pll_setup_gui.m`: when called without an output (normal command
use), it `waitfor`s the window; Generate with Run checked closes the window and
records the script, which then runs via `evalin('base','run(...)')` outside any
callback, in the base workspace, like a typed command. Tradeoff: the prompt is
busy while the GUI is open. `fig=bb_pll_setup_gui(...)` keeps the old
non-blocking/in-callback behavior used by tests.

Verified in Octave 11.3.0 and MATLAB R2025a with a one-off isolated check that
temporarily replaced `uiputfile`/`waitfor` to click Generate with Run checked:
the callback returned with the window closed before any output existed, then
the deferred run completed and left `PLL_DATA_s` in the base workspace. Both
regression suites passed afterward. The real interactive freeze is not
reproduced in automation; confirm by manual use.

## November 1 follow-up: sweep hangs and `bSuppressSweepPlots`

User report: a generated 24-point log `BW_desired_Hz` sweep (100-5000 Hz,
both transients, 12501 points, JPG export, core plots hidden) eventually
crashed/hung from the GUI and the command line. Reproduced on a copy (viewer
off): Octave hung at 100% CPU with flat memory at point 1, and on rerun at
point 11, each time right after `_transient_nl.jpg` and before the VCO figure.
Single points pass in all plot/export combinations, so this is an intermittent
Octave Qt hidden-figure render/print hang, not a numerical fault.

Fix (user-endorsed "suppress graphs during sweeps"): optional core input
`pll_inputs_s.bCorePlots` (default 1) in `rfdude_pll_oct_0p1.m` guards every
figure and export block (the `if 1 %unhide...` blocks became
`if bCorePlots`); calculations stay outside the guards. New run option
`bSuppressSweepPlots` (configuration default true; validated only if present;
GUI checkbox enabled only for sweeps; generated comment) makes `run_case` set
`bCorePlots=0` for sweep points. Absent option = old behavior, so earlier
generated scripts are unchanged; the user's `aa_run_user_config_XXXX_design.m`
needs `run_options_s.bSuppressSweepPlots=1;` or regeneration.

Validated: the copied 24-point script with the option finished all 24 points
in 90 s (previously ~7-10 s/point when it did not hang), no JPGs. New
`test_pll_setup_sweeps` assertions: suppressed sweep creates no figures/JPGs,
plotted sweep creates 12 JPGs, and pn_struct/components/transient errors are
identical. `test_pll_setup_sweeps` and `test_pll_run_tools` passed in Octave
11.3.0 and MATLAB R2025a.

Parallel sweeps (asked, not implemented): Octave `parallel` 4.0.2 and the
MATLAB Parallel Computing Toolbox are installed here. It would restructure the
runner (fresh workspace per case, per-point checkpointing, file naming,
plots off in workers), so get direction first. User response: fine without it
"as long as there is some indication it is alive". `rfdude_pll_run.m` now
flushes the `PLL point k/N` start line (Octave `fflush(stdout)` + `drawnow`)
and prints `PLL point k/N <status> in X s` after each checkpoint. Both suites
re-passed in Octave and MATLAB. After an effort estimate (separate MATLAB
`parfeval`/Octave `parcellfun` paths, loss of per-point progress/checkpoints
with `parcellfun`, Octave GUI fork risk, little gain at ~90 s per 24 points),
the user chose to skip parallel sweeps.

## Portability and cautions

- `aa_RunPllDesign_XXXX.m` references `../pn/datfiles_local/*.mat` only when
  `bUseVCOFromFile`/`bUseTCXOFromFile` = 1 (both 0 by default). That folder is
  git-ignored and machine-local; copy it manually if needed on another machine.
- Generated outputs (`_*.mat`, `_*.jpg`, `_*_results.csv`) are written to the
  working directory and are git-ignored by `pll_synth/.gitignore`.
- Run from inside `pll_synth/` (the run script uses relative paths).
- The new configurator's last-state MAT is local-only and must be copied
  manually for continuity on another computer. Generated scripts use relative
  tool paths, but browsed absolute noise-file paths remain machine-specific.
  Saved datasets embed the curves needed for browsing without those files.

## Synchronization

The earlier configurator scope was authorized for commit/push to `origin/main`
and is recorded above; that is not authorization to commit/push this follow-up.
The PN-profile and ROS demonstration are now committed in the history above.
The November 1 sweep-selector, GUI deferred-run, sweep plot suppression and
progress changes were committed and pushed to `origin/main` on explicit user
authorization; that does not authorize later work. A local commit alone is not shared.
On another computer, fetch/pull only published changes and copy ignored local
state/data separately if wanted. Chat history does not transfer; this file
and `AGENTS.md` are the restart point.
