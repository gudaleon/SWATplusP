# RZWQM2-P branch of SWAT+P (sol_p_model 4) — Example 8 extension

**The RZWQM2-P pool formulation now runs inside SWAT+ as the fifth switchable branch, and it behaves as the pre-registered expectation said it should: of all the augmented branches it sits closest to its lineage relative, the Jones routine, with dissolved export roughly twice the Jones values on every soil, the same soil ranking, and sediment-bound export slightly below Jones.**

## What was ported

The routine `nut_pminrl5` implements the pool exchanges of Sadhukhan and Qi (2018), section 4, equations 77 to 88, exactly as verified in Worked Example 6: the sorption ratio PSP estimated from clay, labile phosphorus and soil carbon; the labile–active imbalance relaxed by the day-count power-law factors, whose consecutive-day counters are held as branch state per HRU and layer; and the active–stable imbalance relaxed at 0.0006 per day toward stability and 0.00006 back. Before the watershed runs, a mirror check compared a transcription of the Fortran text against Example 6's own implementation on its equilibration case: the trajectories agree to zero difference at days 100, 1,000, 3,650 and 20,000, ending at Example 6's published pools (labile 13.02, active 29.40, stable 117.58 kg/ha) with the total conserved at exactly 160 kg/ha. The scope limits of the port design note hold: the formulation's macropore tile transport is not ported, because the host model has no macropore flux to attach it to, and its residue-class organic mineralization stays in Example 6; this branch changes pool dynamics only and exports through the host's stock partition. One basis ambiguity is on record in the amended design note: equation 77's labile term follows Example 6's reading (the pool in kg/ha), while the original regression and the host's Vadas and White branch use mg/kg; the difference is a registered discrepancy item and a stated sensitivity for a later round.

## Watershed results (Ames configuration, 1975–1980, HRU means, kg P/ha/yr)

| Topsoil | Dissolved, branch 4 | Sediment mineral, branch 4 | Dissolved, Jones (0) | Dissolved, branches 2 / 3 |
|---|---|---|---|---|
| Ames as shipped | 0.054 | 0.029 | 0.025 | 0.137 / 1.624 |
| Shield median | 0.071 | 0.037 | 0.033 | 0.182 / 1.653 |
| Agassiz clay | 0.050 | 0.027 | 0.023 | 0.123 / 1.513 |
| Organic peat | 0.198 | 0.080 | 0.081 | 0.563 / 2.472 |
| Sand, low carbon | 0.030 | 0.019 | 0.015 | 0.069 / 1.139 |

Read against the register, the branch completes the lineage contrast the paper needs. Two formulations descended from the same Jones (1984) pool structure, differing only in how the labile–active exchange is timed — fixed fractions in the stock routine, day-count power laws here — differ by about a factor of two in dissolved export while agreeing on the soil ranking and on the sediment-bound flux to within a fifth. That spread is smaller than the spread between pool architectures (the Langmuir capacity core) and far smaller than the spread a foreign pool architecture produces (the HYPE branch), which gives the paper an ordered result: within a lineage, exchange timing is a factor-of-two question; across architectures, the questions are order-of-magnitude ones. As with every branch comparison in this programme, these are behaviour differences between formulations on one small test watershed under demonstration parameters, not validations against field measurements.
