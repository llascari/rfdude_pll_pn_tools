# rfdude_pll_pn_tools
Lance Lascari's personally developed RF/PLL/phase-noise tools, free under the [MIT License](LICENSE)
Reorganized 2025

**Free, unsupported software, provided as-is.** Pull requests and issue reports
are not accepted. You are encouraged to fork it and modify it as you see fit.
I update this repository periodically and may change or remove anything, so
keep your own copy of any version you depend on.

The tools here were translated from old Mathcad work into Octave first /Matlab as a secondary priority as a completely manual exercise.   Fall of 2026 this curmudgeon started seeing the light when it comes to LLM's and has started letting GitHub Copilot add enhancements and tooling around the core work which remains mostly intact.    
Copyright (c) 1999-2026 Lance Lascari. MIT licensed; see [LICENSE](LICENSE) and
[NOTICE.txt](NOTICE.txt) for scope, Copilot credit, and datasheet-data attribution.

## Datasheet-to-PLL demonstration

From the repository root in a graphical GNU Octave or MATLAB session, run:

```matlab
demo_2026
```

The [demo](demo_2026.m) explains the Mini-Circuits ROS-2100-119+ extraction
and shows phase-noise and tuning-sensitivity plots. Press a key in the command
window to continue. The [readable PLL example](pll_synth/aa_demo_ROS_based_synthesizer_runPLL.m)
designs a 5 kHz loop at 1725 MHz, freezes all five filter components, and
analyzes 1350, 1537.5, 1725, 1912.5 and 2100 MHz with frequency-selected ROS
noise and Kvco. The existing results viewer opens to compare noise,
achieved bandwidth/phase margin and both transient models.

No PDF download, LLM service, or local measurement files are needed to run.
See the [extraction evidence and reusable LLM request](pn/ros2100_extraction_example.md).
Editable switches and units are explained beside the settings; Copilot
generation credit is retained. Reruns overwrite only demo outputs in ignored
`pll_synth/_demo_2026/`, without closing unrelated plots. Reopen saved results:

```matlab
addpath('pll_synth');
cc_pll_data_viewer('pll_synth/_demo_2026/_ROS_based_synthesizer_data.mat');
```

This is typical-data modeling, not a hardware guarantee. ROS noise evidence
spans 1 kHz-1 MHz offsets; the historical analysis holds endpoint noise
outside that range, including below the default 100 Hz integration limit.
