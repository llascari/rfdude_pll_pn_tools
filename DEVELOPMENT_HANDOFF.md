# Development handoff

Updated: 2026-10-26, end of session.

## Current objective

Port the 2002 Mathcad PLL worksheet
(`pll_synth/Mathcad - RFdude_pll38_PDFversion.pdf`) to Octave-first,
MATLAB-compatible code in `pll_synth/`, adding features through small,
targeted changes that preserve the existing form and style (see `AGENTS.md`).

## Repository checkpoint

- Branch `main`; last commit `2010c49` ("added mathcad ref"), matching `origin/main`.
- The work below is **uncommitted** and waiting for your review, commit and push.
  The assistant did not stage, commit, or push anything.
- Files changed: `AGENTS.md`, `pll_synth/aa_RunPllDesign_XXXX.m`,
  `pll_synth/pll_synth.txt`, `pll_synth/rfdude_pll_oct_0p1.m`, plus this file (new).

## Completed this session (uncommitted)

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

## Continue here

Nothing is in progress. Optional next steps that came up (not requested yet):

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

## Synchronization

Changes exist only in this worktree. Commit and push with your normal VS Code
workflow; pulling `main` elsewhere will pick them up. Chat history does not
transfer; this file and `AGENTS.md` are the restart point.
