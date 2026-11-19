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

The source of record for the augmented code, with its port designs, build scripts and test
results, is held in the private repository `gudaleon/SWATplus_P_Core`, under
`worked_examples/08_swatplus_augmentation/swatplus_aug/` (the full augmented source tree:
660 Fortran files). The branch was built on the official SWAT+ source and is tested on a
common test watershed, where the six formulations span more than an order of magnitude in
dissolved phosphorus export while agreeing on how the soils rank.

SWAT+P is the modelling engine of the Lake of the Woods watershed programme: the model of
the Canadian tributaries of Lake of the Woods (40,680 km²) is built in SWAT+P, with its
initial soil phosphorus pools set from the Yang and Post (2011) fractionation data.
