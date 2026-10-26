# Project Instructions

## Default to the Existing Form

Make the specific change requested and preserve everything around it. Treat the current file and its nearest comparable files as the authority for form, style, and structure; do not impose a new convention because it seems cleaner or more modern.

- Before editing, read the whole target file and inspect the closest existing example of the requested behavior.
- Preserve the existing organization, control flow, naming, comments, indentation, whitespace, line endings, and ordering wherever the change does not require otherwise.
- Make additions where a reader would expect to find them based on the surrounding code. Keep existing user-facing layouts, labels, plots, parameter groupings, and interaction patterns intact unless asked to change them.
- Do not reformat, reorder, rename, restructure, refactor, optimize, or clean up unrelated code. Avoid whole-file rewrites and broad formatting tools on existing files.
- Do not replace readable, spelled-out code with a shorter abstraction or generated/binary representation when the explicit form is useful for understanding, editing, or tracing the behavior.
- Preserve current inputs, outputs, defaults, file formats, and behavior unless the request explicitly changes them. Make new behavior additive and non-breaking where practical.

## Targeted-Change Workflow

1. Identify the exact requested outcome and the files or behavior it affects. Keep the scope there; do not infer additional work from nearby imperfections.
2. Read the target and the nearest in-project examples before editing. Match their established form, including legacy conventions that are inconsistent elsewhere.
3. Make the smallest complete change that fulfills the request. Keep existing logic and structure recognizable, and avoid unrelated cleanup in the same edit.
4. Check the diff to confirm every changed line is needed for the request and that no surrounding content was accidentally altered.
5. Run the narrowest relevant check or test. Do not regenerate or modify unrelated outputs. If validation is unavailable or fails for an unrelated reason, state that clearly.
6. Summarize what changed, where, and how it was checked. Call out any requested behavior that could not be verified.

## MATLAB and Exploratory Code

When working with MATLAB or Octave tools, favor clear, traceable code that helps a person follow and modify the signal flow or analysis. The code may serve as a testbench or learning aid; compactness and optimization are not goals unless specifically requested. Preserve the established script/function organization and expose meaningful steps and parameters in the same way nearby code does.

## Historical PLL Reference

For PLL design or analysis work, consult the original Mathcad worksheet PDF at `pll_synth/Mathcad - RFdude_pll38_PDFversion.pdf` when it is relevant to the request. Use it to understand the original analysis, assumptions, and intended calculations; preserve that traceability in the MATLAB/Octave implementation. Treat it as a historical reference, not as a blanket instruction to reproduce every feature or assume its calculations are error-free. Keep changes within the requested scope and clearly identify any intentional differences from the worksheet.

## Broader or Ambiguous Changes

If a request appears to require changing established structure, public behavior, or user-facing form beyond the explicitly requested scope, pause and ask before doing so. When multiple implementations would noticeably alter how the existing tool is organized or used, describe the choice briefly and get direction first.

## Session Continuity

When resuming work, read `DEVELOPMENT_HANDOFF.md` first. Update it at the end of a session with the checkpoint, what changed, what was validated, and next steps.
