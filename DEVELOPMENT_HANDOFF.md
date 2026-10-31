# Development handoff

Updated: 2026-10-31, end-of-session checkpoint for continued user testing.

## Current objective

Port the 2002 Mathcad PLL worksheet
(`pll_synth/Mathcad - RFdude_pll38_PDFversion.pdf`) to Octave-first,
MATLAB-compatible code in `pll_synth/`, adding features through small,
targeted changes that preserve the existing form and style (see `AGENTS.md`).

## Repository checkpoint

- Branch `main`; October 31 tooling is being committed as
  "Add Octave-first PLL configurator and reloadable analysis viewer",
  following `d6d872a` (October 26 transient implementation).
- The October 26 work below was committed in `d6d872a`. The worktree was clean
  at the start of the October 31 review.
- October 31 commit scope: this handoff,
  `AGENTS.md`, `pll_synth/pll_synth.txt`, small additive changes in the existing PLL core,
  and new configurator, runner/generator/validation helpers, viewer and tests.
  User authorized committing and pushing this scope to `origin/main`.
  The user-created `pll_synth/aa_run_user_config_XXXX_design_TEST.m` is left
  local and untracked; last GUI state and generated results remain ignored.

## Completed October 26 (committed in `d6d872a`)

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

## Public release context and license review (decision pending)

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

Checkpoint: October 31, 2026. The user paused after the viewer camera presets,
aggregate-view selection behavior, published-archive inspection, and
preliminary license research. Fixed camera buttons and selection behavior
passed `test_pll_run_tools()` in Octave 11.3.0 and MATLAB R2025a Update 1.
Earlier in this session, the dataset-picker change also passed both suites
and opened the existing `_rfd_pll_Design_XXXX_data.mat` dataset successfully.

Worktree changes are local and uncommitted; do not commit or push without
authorization. `pll_synth/aa_run_user_config_XXXX_design_TEST.m` contains a
local five-value bandwidth sweep (`[500 1000 2000 5000 10000]`) and updated
overwrite comments. Preserve that user edit. Earlier ignored setup state and
generated results remain machine-local.

Next: resume interactive GUI testing as useful, then ask the user to decide
whether to pursue open-source release and which license to use. No license
file or GitHub feature settings have been changed. Before applying a license,
resolve provenance/distribution rights for the historical PDF/worksheet,
shipped measurement traces, and code developed for paid work. Retain all
Copilot-origin notes/headers and project/tooling documentation, especially
Octave/MATLAB compatibility guidance. The published ZIP inspection and
preliminary MIT/BSD-3-Clause/Apache-2.0 comparison are documented above.

Other optional next steps (not requested):

1. Nonlinear model refinements: PFD reset delay / dead zone, charge-pump
   up/down mismatch and leakage, charge-pump output compliance limits.
2. Remaining Mathcad worksheet features not yet ported (see the PDF feature
   list, e.g. two-point modulation, reciprocal mixing / adjacent channel
   estimate, cascaded synthesizers, optional loop amplifier).
3. Optionally write transient results (settling time, slips) into the CSV
   report or `pn_struct` output; currently they are printed and plotted only.

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

The user authorized an end-of-session commit and push to `origin/main`.
Verify push success in the Git result; a local commit alone is not shared.
On another computer, fetch/pull `main` to receive the tooling and this handoff;
copy local state/data separately if wanted. Chat history does not transfer;
this file and `AGENTS.md` are the restart point.
