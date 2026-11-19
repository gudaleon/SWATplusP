# SWAT+P

**SWAT+P** is the name of the augmented SWAT+ watershed model developed in this programme.

SWAT+ carries two soil phosphorus routines, and neither allows the soil a finite capacity to
hold phosphorus. SWAT+P augments the model with a library of six switchable formulations of
the soil phosphorus subroutine, selected by a single control code:

0. the stock Jones (1984) routine;
1. the stock Vadas and White (2010) routine;
2. a two-rate Langmuir sorption core with a finite capacity, after Zhou et al. (2023);
3. the Freundlich formulation of the HYPE model (SMHI, version 5.36.0);
4. the sorption-ratio exchange formulation of RZWQM2-P (Sadhukhan and Qi 2018);
5. an equilibrium speciation formulation governed by hydroxyapatite, computed with the
   thermodynamics of PHREEQC (phreeqc.dat).

SWAT+P also carries a switchable macropore tile drainage bypass, because the stock tile
routine transports dissolved phosphorus only and has no macropore pathway.

This repository holds the full augmented source tree: 660 Fortran files under `model/src/`,
including `aug_p_module.f90` and `nut_pminrl.f90` through `nut_pminrl6.f90`, the port
designs under `design/`, and the test watershed and factorial results under `model/refdata/` and
`results/`. The branch was built on the official SWAT+ source (whose own readme is kept as
`README_SWATplus_stock.md`) and is tested on a common test watershed, where the six
formulations span more than an order of magnitude in dissolved phosphorus export while
agreeing on how the soils rank. The wider development archive of the programme is held in
the private repository `gudaleon/SWATplus_P_Core`.

SWAT+P is the modelling engine of the Lake of the Woods watershed programme: the model of
the Canadian tributaries of Lake of the Woods (40,680 km²) is built in SWAT+P, with its
initial soil phosphorus pools set from the Yang and Post (2011) fractionation data.

## Rights and citation

© 2026 Alex Neumann. The augmentation components of SWAT+P are the author's original
work, disclosed here in advance of the publication of record; see
`LICENSE_AUGMENTATION.md` for the rights statement and the citation. The underlying SWAT+
code remains under its own licence (the GNU Lesser General Public License v2.1, in
`LICENSE`).
