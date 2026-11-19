# SWAT+P — sorption core specification v1 (stage 3, frozen before implementation)

Method: Researcher-led AI research.
Status: specification, prepared 2026-11-19 under the branch plan `SWATPLUS_AUGMENTATION_BRANCH_v1.md`. Implementation is gated on the Example 4 (BioRT-Flux-PIHM) field test, per the branch plan: the core is field-tested there before it is implemented in SWAT+. This specification freezes the formulation and its tests in advance, so that no parameter of the core can be tuned to a result after the fact.

## The formulation

Per soil layer, the core carries three phosphorus pools in place of the stock routine's labile/active pair: solution phosphorus C (mg/L in the layer's water), a fast-sorbed pool M_f (mg/kg soil), and a slow pool M_s (mg/kg soil). The fast pool exchanges with solution toward a Langmuir equilibrium,

M_eq = S_max · K_L · C / (1 + K_L · C),

with the exchange written in the inverse form verified in Example 3 (Zhou et al. 2023, equation T4.13): the equilibrium concentration implied by the current fast pool is C_eq = M_f / (K_L · (S_max − M_f)), and the fast flux is k_f · (C − C_eq), converted between water and soil bases by the layer's water content, bulk density and thickness exactly as Example 3's stated interpretation 3 required. The slow pool exchanges with the fast pool by a first-order ageing transfer, k_s · M_f forward and k_s,rev · M_s back, with k_s,rev < k_s, so that freshly sorbed phosphorus is more available than aged phosphorus. S_max is the finite capacity whose absence in the stock routines is the audit's central structural finding: as M_f + M_s approaches S_max, C_eq rises without bound and retention collapses, which is the behaviour the repeated-loading test exists to exhibit.

## Parameter provenance

Every parameter enters with a named source, and none is calibrated in this branch. S_max and K_L are soil-derived: the starting values are the Langmuir parameters of Example 3's verified architecture (Q_max 683.5 mg/kg, K_L 0.2 L/mg, from Zhou et al.'s Table 6 for a bioretention medium), re-derived per soil from the same profile data stage 1 of the ladder uses, with the RZWQM2-P phosphorus sorption coefficient (Example 6, equation 77) as the cross-check estimator. The fast rate k_f starts from Example 3's adsorption rate (0.15 per 10 minutes, rescaled to a daily step and reported as rescaled). The slow rates k_s and k_s,rev start from the two-rate behaviour Example 3 exhibited and from Example 6's active-to-stable exchange rates (0.0006 forward, 0.00006 back per day), which are the Jones lineage's own slow numbers. Where the sources disagree, the spread is carried as the parameter's stated uncertainty and the fork is reported per branch, under the programme's explore-all-branches rule.

## Pre-registered pool-level tests

Each test runs on the core and on a transcription of the stock Jones pool equations, on identical inputs, and the stock transcription's expected failure is stated in advance as the control.

1. **Pulse relaxation.** A single fertiliser pulse into solution must relax toward equilibrium in two phases, fast exchange first and slow ageing second, producing a two-timescale decay curve. Control expectation: the stock routine equilibrates its labile and active pools by its fixed-ratio rule within the step structure it has, and cannot produce the slow tail.
2. **Repeated loading to capacity.** Identical daily loads over years must show the retained fraction declining as M_f + M_s approaches S_max, and the solution concentration rising correspondingly. Control expectation: with no capacity, the stock routine's retained fraction does not decline for this reason at any parameter values.
3. **Drawdown release.** After loading, solution phosphorus is drawn down (plant uptake or leaching) below C_eq, and the core must release from the fast pool at a rate governed by the disequilibrium, with legacy release from the slow pool following at k_s,rev. Control expectation: the stock routine releases only through its fixed equilibrium ratio, with no dependence on how saturated the soil has become.
4. **Conservation.** Total phosphorus across the three pools plus cumulative boundary fluxes closes to machine precision in every test, as in Examples 3 and 6.

## Freeze rule

Once Example 4's field test reports, this specification is either implemented as written or amended in a versioned revision that states what changed and why, before any augmented run is made. No augmented result enters the synthesis, or the paper, from an unfrozen build.
