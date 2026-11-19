# Speciation branch of SWAT+P (sol_p_model 5) — Example 8 extension

**The speciation branch is built, its mathematics passed the pre-registered PHREEQC gate with room to spare, and its watershed behaviour is the first in the register to break the soil ranking every other branch agrees on, because its dissolved export is governed by soil pH acting through mineral solubility rather than by bulk density or carbon.**

## The gate

Before any Fortran was written, a standalone solver carrying phreeqc.dat's own constants — the protonation steps, the calcium and magnesium ion pairs, carbonate and sulfate pairing of the free cations, the database's activity-coefficient conventions, and van't Hoff temperature corrections — was required to reproduce Worked Example 1's PHREEQC results on the same water at pH 5, 6, 7 and 8. It reproduced every phosphorus fraction of five percent or more within half a percentage point (the criterion allowed one and a half), and the hydroxyapatite saturation index within 0.01 log units at all four pH values: −12.31 against −12.32, −5.44 against −5.45, +0.64 against +0.64, and +5.20 against +5.20. Iron and aluminium phosphate species were excluded from the solver's set, on Example 1's own evidence that they carry under a tenth of a percent of the phosphorus in that database.

## The branch

The routine `nut_pminrl6` computes, per layer per day, the dissolved phosphorus concentration at hydroxyapatite equilibrium for the layer's own pH from the soil file, with the full speciation of the gate, and relaxes the layer's tracked dissolved mass toward that concentration at a stated rate of 0.1 per day, precipitating the excess into the stable pool as the calcium-phosphate store or dissolving that store when the water is undersaturated. Exports leave through the same concentration fences as branches 2 and 3, and the export routine debits the tracked dissolved mass alongside the labile pool, so the seams close. Version 1 scope, stated: the water composition is the gate's water in every layer, so the branch isolates the pH axis; per-layer element state from the model's salt module is the recorded version 2 coupling, and iron and aluminium phases remain outside the branch.

## Watershed results (Ames configuration, 1975–1980, HRU means, kg P/ha/yr)

| Topsoil (layer pH) | Dissolved, branch 5 | Dissolved, Jones (0) | Dissolved, branches 2 / 3 / 4 |
|---|---|---|---|
| Ames as shipped | 0.340 | 0.025 | 0.137 / 1.624 / 0.054 |
| Shield median (5.4) | 0.271 | 0.033 | 0.182 / 1.653 / 0.071 |
| Agassiz clay (6.5) | 0.445 | 0.023 | 0.123 / 1.513 / 0.050 |
| Organic peat (5.0) | 0.286 | 0.081 | 0.563 / 2.472 / 0.198 |
| Sand, low carbon (5.5) | 0.351 | 0.015 | 0.069 / 1.139 / 0.030 |

Sediment-bound mineral phosphorus export is effectively zero under this branch on four of the five soils (0.005 on the Agassiz clay), because precipitation moves phosphorus into the stable pool, which the erosion routine does not draw on.

The ranking result is the finding. Every earlier branch orders the soils peat, shield, Agassiz, sand; this branch orders them Agassiz, sand, Ames, peat, shield, which is close to the reverse, and the ordering follows the layer pH rather than the bulk density that ordered the Langmuir branch or the carbon that ordered the stock branches. The mechanism consistent with the branch's own equations is that hydroxyapatite solubility rises steeply as pH falls, so the acidic soils are assigned the highest equilibrium concentrations, but sustaining those concentrations dissolves the finite calcium-phosphate store, after which the branch becomes supply-limited and its exports fall; the near-neutral Agassiz soil, assigned a moderate concentration, sustains it for the whole run. That mechanism is stated as the branch's internal explanation, not as a field claim: the default landscape outputs carry fluxes rather than pool trajectories, so the store's depletion path is inferred from the equations and the export pattern, and confirming it directly is registered as a test-bed task. As with every branch comparison in this programme, these are behaviour differences between formulations on one small test watershed, not validations against field measurements.
