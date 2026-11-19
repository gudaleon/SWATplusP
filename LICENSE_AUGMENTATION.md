# Rights in the SWAT+P augmentation

© 2026 Alex Neumann. All rights in the augmentation components are reserved to the
extent stated below.

## What the augmentation is

SWAT+P is an augmentation of the SWAT+ watershed model. The augmentation components are
the original work of the author:

- `model/src/nut_pminrl3.f90` — the two-rate Langmuir sorption core;
- `model/src/nut_pminrl4.f90` — the HYPE Freundlich formulation;
- `model/src/nut_pminrl5.f90` — the RZWQM2-P sorption-ratio exchange formulation;
- `model/src/nut_pminrl6.f90` — the equilibrium speciation formulation;
- `model/src/aug_p_module.f90` — the shared data module of the library;
- the macropore tile drainage bypass code in `model/src/nut_solp.f90`;
- the port designs in `design/` and the test results in `results/`.

## Status of this disclosure

These components are disclosed in this repository on 19 November 2026, in advance of the
publication of record (manuscript in preparation), so that the work carries a dated,
public record of its authorship. They are published for inspection and verification.

Authorship and priority are asserted. Anyone who uses these components, in software or
in a publication, is asked to cite this repository and the publication of record when it
appears, and to obtain the author's written permission before redistributing the
augmentation components as a standalone product.

## The underlying model

The underlying SWAT+ code in this repository is the work of the SWAT+ developers and is
distributed under the GNU Lesser General Public License, version 2.1 (see `model/LICENSE`),
which continues to govern that code. Nothing in this notice changes the licence of the
underlying model.

## Citation

Neumann, A. (2026). SWAT+P: an augmented SWAT+ carrying a switchable soil phosphorus
subroutine library and a macropore tile drainage bypass. GitHub repository:
https://github.com/gudaleon/SWATplusP. Manuscript in preparation.
