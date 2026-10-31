# `pn_struct` phase-noise data format

Documented baseline: 2026-10-31.

## Legacy single-operating-frequency format

The established format represents one phase-noise curve for a representative
operating frequency, such as a VCO, reference, or synthesizer. Existing MAT
files store the structure in a variable named `pn_struct`, and other analysis
frameworks use these field names. Preserve their meanings when extending the
format.

```matlab
pn_struct.fc = 1e6;
pn_struct.f = [1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6 1e7 1e8];
pn_struct.n = [-60 -58 -68 -82 -93 -101 -109 -114 -124 -129 -149 -149];
pn_struct.kvco = 10;
pn_struct.comment = 'misc data';
pn_struct.name = 'filename_suitable_string';
pn_struct.clock = clock;
```

| Field | Meaning | Units / convention |
| --- | --- | --- |
| `fc` | Representative carrier or operating frequency for this characterization | Hz |
| `f` | Phase-noise offset frequencies from `fc` | Hz; current PLL file input expects an increasing row vector |
| `n` | Phase noise corresponding element-by-element to `f` | dBc/Hz; current analysis treats this as SSB phase noise |
| `kvco` | Representative tuning sensitivity | Hz/V |
| `comment` | Free-form notes about the data | Text |
| `name` | Human-readable/source identifier; historically often suitable for a filename | Text |
| `clock` | Creation time captured by the Octave/MATLAB `clock` function | `[year month day hour minute seconds]` |

For current log-frequency interpolation and integration workflows, `f` values
must be positive, ordered, and paired one-to-one with the values in `n`.
Consumers may impose additional shape requirements: the PLL file input, for
example, expects matching increasing row vectors. `build_pn_struct` assigns
the fields but does not validate these conventions.

Some derived phase-noise combinations set `fc` and `kvco` to zero because
those quantities are not meaningful for the result. Do not interpret those
zeros as a physical carrier frequency or tuning sensitivity.

## Version 1 operating-frequency profile

Keep `pn_struct` as one ordinary scalar characterization. The additive
`pn_profile_s` wrapper represents multiple operating frequencies:

| Field | Required meaning |
| --- | --- |
| `schema_version` | Numeric scalar `1`; reject unknown versions |
| `points` | Nonempty row array of legacy single-frequency structures, sorted by strictly increasing, unique `fc` |
| `representative_index` | Integer index of the stored default representative point |
| `source` | Nonempty character row identifying the source document/revision and evidence |

Every point has the seven legacy fields, scalar positive `fc`, finite scalar
`kvco` in Hz/V, and at least two positive strictly increasing row-vector
offsets with matching finite real row-vector noise values. `comment` and
`name` are character rows (`name` nonempty); `clock` is a finite six-element
row. Document conditions and any derivations in each point's `comment`.
Different points may have different offset grids. `fc` remains a carrier
frequency, never an offset grid or tuning voltage.

`validate_pn_profile` enforces this wrapper's requirements; the legacy
constructor and consumers remain unchanged. `select_pn_profile(profile,fc)`
returns an exact stored point, including its original clock and notes. It
errors for missing carrier points. Explicit
`select_pn_profile(profile,fc,'interpolate')` permits these modeled operations:

1. Use the two adjacent carrier points; interpolate Kvco linearly versus
   carrier frequency. An exact match still returns the stored point unchanged.
2. Use the sorted union of their offsets within their shared offset range.
   Evaluate each curve linearly in dBc/Hz versus `log10(offset_Hz)`.
3. Interpolate those noise values in linear power versus carrier frequency,
   then convert back to dBc/Hz. This is a modeling choice, not measured data.
4. Reject carrier extrapolation, disjoint/touching-only offset ranges, and
   invalid input. Never extend offsets beyond either bracketing curve.

The optional second output, `selection_s`, reports `mode`, source-point
`indices`, interpolation `weights`, and `offset_range_Hz`. Modeled output
notes identify both inputs and the interpolation policy.

Save the selected scalar as the MAT variable `pn_struct` alongside
`pn_profile_s`. Old consumers continue to use `pn_struct`; they do not
automatically evaluate the profile at their requested frequency. Export a
newly selected scalar for them when needed. `representative_index` always
identifies a stored default, even if the scalar export is interpolated.

The programmatic PLL runner now supports an explicit opt-in:
`run_options_s.vco_profile_s=pn_profile_s`, with
`pll_inputs_s.bUseVCOFromFile=1`. It selects at
`fout_desired_Hz/mult` for each case using the interpolation policy above,
exports a scalar source, and embeds selection evidence in the saved dataset.
The historical core and GUI/file-only workflows still use `pn_struct`;
merely including a profile in a MAT file does not enable profile selection.
See the [shipped PLL example](../pll_synth/aa_demo_ROS_based_synthesizer_runPLL.m).

The complete [ROS-2100 worked example](ros2100_extraction_example.md) shows
extraction, provenance, explicit derivation, generation, selection, MAT
compatibility and reproducible Octave/MATLAB checks.

## Moving forward

1. **Keep old data usable.** Retain the legacy field names and meanings, and
   preserve the existing single-frequency workflow for MAT files and
   downstream analysis frameworks. Before adding fields or changing a saved
   representation, verify how actual legacy consumers handle the change.
2. **Keep profiles distinct and versioned.** Use the version 1 wrapper above
   instead of overloading legacy fields. Any later incompatible change needs
   an explicit schema version and migration/consumer policy.
3. **Prove compatibility and interpretation.** Keep representative legacy MAT
   files as regression fixtures. Test existing constructors and consumers on
   those files in Octave, then run MATLAB compatibility checks. The ROS example
   and `test_pn_profile` generate isolated fixtures without local measurements.
4. **Make datasheet extraction reviewable.** Give the LLM the source PDF and
   the instructions below. Review its evidence table against the PDF before
   generating or saving any data. Do not have the LLM silently fill gaps or
   create a new profile schema.

### Reusable LLM instructions

> Extract oscillator phase-noise and tuning-sensitivity data from the supplied
> datasheet. Use the supplied document as the authority; do not invent, infer
> without labeling, or silently fill in missing values.
>
> 1. Identify the manufacturer, exact device/model, document revision/date,
>    and the PDF page and printed page number (if different). For every value,
>    cite its table/figure and page.
> 2. Identify what is characterized: reference/VCXO, standalone VCO, or
>    integrated PLL/synthesizer. Record the phase-noise source and state:
>    free-running/core-VCO, reference, or closed-loop output. Never label
>    closed-loop synthesizer output noise as intrinsic VCO noise.
> 3. Keep operating/carrier frequency separate from phase-noise offset
>    frequency. Record relevant conditions shown by the source, including
>    supply, control/tuning voltage, output frequency, reference, loop
>    bandwidth, and measurement/operating mode. Ignore temperature as a data
>    axis. If the best plot shows multiple temperature traces, use the nominal
>    room-temperature trace only when it is clearly identified; otherwise
>    select one representative trace and state that its temperature is
>    unknown. Mark other unstated conditions as "not specified."
> 4. Find the phase-noise plot that best matches the requested noise source
>    and operating point, and use it to capture the curve over its useful
>    offset-frequency range. Prefer a core/free-running VCO plot when that is
>    the requested source; do not substitute a closed-loop output plot.
>    Include useful offsets across the plotted range, especially log-spaced
>    points and visible slope changes. Use matching table values as exact
>    points or cross-checks. Preserve units, typical or min/max status, and
>    SSB/DSB convention. For graph-read values, account for linear or
>    logarithmic axes, label them as estimates, and state realistic reading
>    uncertainty based on graph resolution. Do not imply more precision than
>    the graph supports or extrapolate beyond the data.
> 5. Extract tuning sensitivity/Kvco and its units and operating point. If it
>    is given in ppm/V, convert to Hz/V only using the corresponding
>    operating frequency and show the calculation:
>    `Hz/V = operating_frequency_Hz * ppm_per_V / 1e6`. Preserve the source
>    value and label the conversion. Do not treat supply pushing as tuning
>    sensitivity.
> 6. Verify each cited page and table/figure against the supplied PDF; a
>    search result or generated citation is not evidence by itself. Return
>    two evidence tables: (a) phase noise with operating frequency, offset
>    frequency, value, units, source type (table or graph estimate),
>    conditions, and page/table/figure; (b) tuning sensitivity with operating
>    frequency, source value/units, converted Hz/V if justified, conditions,
>    and page/table/figure. Follow these with assumptions, ambiguities,
>    missing information, and any values that need human graph review.
> 7. After checking the evidence, provide a readable Octave-first,
>    MATLAB-compatible generation script using the legacy fields and version 1
>    wrapper above. Keep numeric rows explicit and cite their source near the
>    assignments. Preserve distinct datasets at their actual carrier
>    frequencies; do not assume a detailed curve at one carrier applies at
>    others. Label derived Kvco and interpolation as modeled, show the method,
>    and do not substitute zero for an unknown gain. If required values cannot
>    be sourced or derived with an explicitly approved method, explain the
>    blocker rather than exporting a misleading structure. Save a selected
>    legacy pn_struct alongside the profile in MATLAB v7 MAT format. Include
>    run instructions and tests for exact selection, interpolation,
>    extrapolation rejection, and legacy load compatibility.

### Example documents for exercising the instructions

- `CVHD-950.pdf` (Crystek VCXO): a representative reference oscillator.
  Compare the tabulated phase-noise points with its curve, and capture the
  stated tuning sensitivity and its conditions. The example illustrates
  converting ppm/V to Hz/V only at the corresponding nominal frequency.
- `lmx2594.pdf` (Texas Instruments LMX2594): an integrated PLL/synthesizer.
  Separate core-VCO noise from closed-loop output noise. In this datasheet,
  Figure 16 is titled "VCO Phase Noise Over Temperature" and shows
  `fVCO = 8 GHz` with narrow loop bandwidth (`<100 Hz`); Figure 7 is titled
  "Closed-Loop Phase Noise at 8 GHz." Ignore the temperature sweep and use
  only a clearly identified nominal trace from Figure 16; otherwise mark the
  representative trace's temperature unknown. The VCO-characteristics table
  also lists core-VCO phase-noise points for VCO1 at 8 GHz, and the Kvco table
  gives a value at 8 GHz. Verify each figure/table and its exact page and
  conditions rather than relying on a figure number or search summary alone.
- `ROS-2100-119+.pdf` (Mini-Circuits standalone VCO): use the model-specific
  specification table for tabulated phase-noise offsets and tuning
  sensitivity, then use its tuning-voltage and phase-noise plots only when
  the requested frequency-dependent detail is supported by those plots.

Use the worked example's [generator](aa_generate_ros2100_example.m),
[selector](select_pn_profile.m), [validator](validate_pn_profile.m), and
[tests](test_pn_profile.m) as the executable reference for another device.
Do not change the schema for each new datasheet.

The legacy format was documented on 2026-10-31 by Lance Lascari / RFdude.com
LLC. The moving-forward goals were recorded at that time.
