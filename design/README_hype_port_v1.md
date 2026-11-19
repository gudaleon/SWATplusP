# HYPE branch of SWAT+P (sol_p_model 3) — Example 8 extension

**The HYPE phosphorus routine now runs inside SWAT+ as the fourth switchable branch, and its first coupled run produced exactly the class of discrepancy that only running can expose: every equation is a faithful transcription, yet the branch exports an order of magnitude more dissolved phosphorus than any other branch, because HYPE's mineralization rate was calibrated against HYPE's own pool sizes and becomes a large one-way flux when applied to SWAT+'s much larger active pool.**

## What was ported

The routine `nut_pminrl4` implements the formulation of the port design note from the HYPE 5.36.0 source: first-order pool transformations (humus phosphorus degrading to the fast pool at 2.2e-5 per day, humus phosphorus dissolving to a dissolved organic pool at 1.5e-5 per day, fast-pool mineralization to solution at 0.02 per day, independent of nitrogen) scaled by HYPE's own temperature factor (Q10 of 2 about 20 °C, ramped to zero at 0 °C) and moisture factor (compiled constants Satact 0.6, Thetalow 8, Thetaupp 12, Thetapow 1), and a kinetic Freundlich exchange (Kfr 1000 L/kg, exponent 0.5, exchange rate 0.065 per day) between solution phosphorus and the sorbed pool, whose content is tracked explicitly because the kinetic step makes today's split depend on yesterday's. The pool mapping of record holds: HYPE's particulate pool is the SWAT+ labile pool, its fast pool is the active pool, its humus pool is the stable humus phosphorus pool, the stable mineral pool is outside the port, and dissolved organic phosphorus is branch state, exported through the same concentration fences in the solution-phosphorus routine and reported within the dissolved export. Before any watershed run, a Python transcription of the core passed the four pre-registered pool tests: kinetic relaxation after a pulse, retention continuing past the Langmuir branch's capacity under sustained loading (the Freundlich form has no ceiling), drawdown release governed by the Freundlich equilibrium, and conservation to 5e-16 relative drift over a year.

## Watershed results (Ames configuration, 1975–1980, HRU means, kg P/ha/yr)

| Topsoil | Dissolved export, branch 3 | Sediment mineral P, branch 3 | Dissolved export, branches 0 / 1 / 2 |
|---|---|---|---|
| Ames as shipped | 1.624 | 0.002 | 0.025 / 0.012 / 0.137 |
| Shield median | 1.653 | 0.002 | 0.033 / 0.014 / 0.182 |
| Agassiz clay | 1.513 | 0.002 | 0.023 / 0.012 / 0.123 |
| Organic peat | 2.472 | 0.003 | 0.081 / 0.031 / 0.563 |
| Sand, low carbon | 1.139 | 0.002 | 0.015 / 0.008 / 0.069 |

The soil ranking is preserved (peat highest, sand lowest), and the branch conserves mass at pool level, but two coupled behaviours stand out. Dissolved export is roughly ten times the augmented Langmuir branch and sixty times the Jones branch. The cause is identified, and it is architectural rather than a coding error: in HYPE's own pool architecture the fast pool is a small throughput store (its demo initialises it at 5 kg/km²) fed by a very large humus pool (up to 500,000 kg/km²), so a mineralization rate of two percent per day moves a modest flux; mapped onto SWAT+'s active pool, which is a major store in its own right, the same rate drains a large stock into the labile pool, whence the concentration fences export it. Sediment-bound mineral phosphorus collapses to about 0.002 kg/ha/yr in the same runs, because the erosion routine reads the labile pool that the dissolved export is draining. Parameters travel with the pool architecture they were calibrated in, not with the equations alone; that is this round's finding, and it is stated as a behaviour of the coupled system under demonstration parameters, not as a judgement on HYPE, whose own calibrated application balances these pools with its own inputs and initialisation.

## Standing limits

The port's parameters are basin-wide constants from the HYPE demonstration file, not calibrated values; per-soil Freundlich coefficients remain the recorded refinement, shared with the Langmuir branch's per-soil capacity decision. Dissolved organic phosphorus is produced only from the humus pool in this version (the fast-pool dissolution rate is absent from the demonstration file and is carried as zero), it is not written to restart files, and its export is reported within the dissolved total rather than in a separate column. As with every branch comparison in this programme, the differences are behaviour differences between architectures on one small test watershed, not validations against field measurements.
