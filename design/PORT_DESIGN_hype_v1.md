# Port design — HYPE phosphorus routines as SWAT+ sol_p_model 3 (v1)

**The HYPE soil phosphorus routine ports into SWAT+P as a fourth switch value, with its kinetic Freundlich sorption and its nitrogen-independent phosphorus mineralization intact, under the pool mappings and stated limitations below.**

## What is being ported

From the HYPE 5.36.0 source audit (Example 5, file npc_soil_proc.f90): five soil phosphorus pools per layer — dissolved SRP and dissolved organic phosphorus (DOP) in soil water, and the solid pools fastP, humusP and partP. First-order transformations, each scaled by HYPE's own temperature factor and soil-moisture factor: humusP degrades to fastP (parameter degradhp, 0 to 2.2e-5 per day across the demo's classes), fastP mineralizes to SRP (minfPpar), fastP dissolves to DOP (pardisfP), and humusP dissolves to DOP (dissolhp, 1.5e-6 to 2.2e-5 per day). Sorption is a kinetic Freundlich exchange between dissolved SRP and partP: the equilibrium solid concentration is Kfr times C to the power nfr, solved by Newton-Raphson on the layer's total exchangeable phosphorus, and the pool moves toward that equilibrium by the fraction (1 − exp(−kadsdes)) per day, in both directions. The demo's parameters are freuc (Kfr) 450 to 2500 litres per kilogram across eight soil types, freuexp (nfr) 0.5 throughout, and freurate (kadsdes) 0.04 to 0.085 per day. Particulate export draws on partP and humusP of the top layer.

## Pool mapping (decisions of record)

1. **partP is the SWAT+ labile pool.** In both models this pool is the exchangeable sorbed stock and the erosion source: SWAT+ already takes its sediment mineral phosphorus from the labile pool, so HYPE's double duty for partP survives the mapping without a structural change.
2. **fastP is the SWAT+ active pool.** HYPE's fastP is the slowly cycling mineral pool that feeds mineralization, which is the active pool's role in the stock routines.
3. **The stable mineral pool is outside the port.** HYPE has no stable mineral pool. Under this branch the stable pool neither receives nor releases, the same stated limitation the Langmuir port carries.
4. **humusP is the SWAT+ stable humus phosphorus pool**, and its degradation flux lands in the active pool, matching decision 2.
5. **DOP is branch-local state.** SWAT+ has no dissolved organic phosphorus pool in soil water. The branch holds DOP per HRU and layer in its own module array, persistent across days within a run, produced from fastP and humusP at HYPE's dissolution rates, mineralized to SRP, and exported with soil water through the same concentration-times-flux fences the augmented branch already uses in nut_solp. It is not written to restart files; that limitation is stated, not hidden.
6. **The equilibrium concentration is published exactly as the Langmuir branch publishes it**, so nut_solp's branch fences serve both new branches and the stock partition code is untouched.

## Parameters for the first port

Basin-wide constants taken from the HYPE demo's mid-range, because the Ames harness has no HYPE soil-class map: Kfr 1000 litres per kilogram, nfr 0.5, kadsdes 0.065 per day, degradhp 2.2e-5 per day, dissolhp 2.2e-5 per day, with minfPpar and pardisfP read from the same demo parameter file at implementation. Deriving Kfr per soil from clay content is the recorded refinement, parallel to the Langmuir branch's per-soil capacity refinement, and the two refinements should be decided together so the branches stay comparable.

## Choice points for Alex

- **C1, DOP treatment.** The design above carries DOP as real branch state with its own export. The cheaper alternative folds DOP production straight into the labile pool and loses the dissolved-organic export pathway. The recommendation is the full state, because the dissolved-organic pathway is one of the architectural differences the paper exists to compare.
- **C2, environmental factors.** The port carries HYPE's own temperature and moisture factor functions rather than substituting SWAT+'s nutrient factors, so the branch is HYPE's routine and not a hybrid. The cost is two small functions ported alongside.

## Tests the port must pass before any watershed run

The four pool-level tests of the frozen sorption-core specification, restated for the Freundlich form: pulse relaxation at the kinetic rate kadsdes; no capacity ceiling (the Freundlich equilibrium grows without bound, so the loading test must show retention continuing where the Langmuir branch saturates — this contrast is a designed result of the test-bed, not a defect); drawdown release governed by the Freundlich equilibrium concentration; and conservation to machine precision. The stock branches and the Langmuir branch on the same soils are the controls, and the Ames soil-variant set is the first watershed comparison.
