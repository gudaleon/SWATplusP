# Yang and Post initialisation round — Example 8 extension

**Given the basin's measured labile phosphorus, the Jones and augmented branches construct an initial pool profile whose total lands close to the measured Yang and Post total by an accident of their ratio rules, while the Vadas and White branch constructs roughly twice the measured mineral phosphorus, because its stable-pool coefficient inflates the deep pools.**

## Design

The stock initialisation accepts one phosphorus number, the surface labile concentration in nutrients.sol, and derives the remaining pools. This round solved that number for each of the four Lake of the Woods soil variants so that the profile labile mass equals the Yang and Post basin labile fraction, 30 grams per square metre or 300 kilograms per hectare, distributed down the profile with the model's own depth coefficient. The solved surface concentrations are 33.6 to 35.2 milligrams per kilogram, against the stock default of 5. The active pool then follows each branch's rule (the fixed sorption ratio 0.40 under branches 0 and 2; the clay-and-carbon estimator under branch 1), the stable pool follows as four times the active pool under branches 0 and 2 or through the White et al. (2009) coefficient under branch 1, and the organic pools are computed from soil carbon at a fixed 100-to-1 carbon-to-phosphorus ratio, as the code prescribes. The driver is `yang_test.py`; the constructed profiles are in `yang_initial_pools_v1.csv` and the exports in `yang_results_v1.csv`.

## The constructed profile against the measured fractions (kg/ha)

| Pool | Yang & Post measured | Branches 0 and 2 construct | Branch 1 constructs |
|---|---|---|---|
| Labile | 300 | 300 (set) | 300 (set) |
| Active / secondary mineral | 500 | 450 | 734–820 |
| Stable / apatite + occluded | 1,720 | 1,800 | 5,839–6,019 |
| Organic | 1,730 | 1,507–1,954 | 1,507–1,954 |
| Total | 4,250 | ≈4,240 | ≈8,760 |

The closeness of the branches 0 and 2 total to the measured total is a coincidence of two independent ratio rules landing near the measured fractions on these carbon-rich soils, and it is reported as a coincidence, not as a validation. The branch 1 divergence is structural: its stable-pool coefficient, fitted on the Sharpley (2004) data the code cites, scales with the active plus labile concentrations raised to a negative power, and at these labile levels it multiplies the deep mineral stock to about three and a half times the measured apatite-plus-occluded fraction.

## Exports under the Yang initialisation (surqsolp, kg/ha/yr)

| Topsoil | Jones (0) | Vadas & White (1) | Augmented (2) |
|---|---|---|---|
| Shield median | 0.060 | 0.046 | 0.212 |
| Agassiz clay | 0.047 | 0.041 | 0.145 |
| Organic peat | 0.121 | 0.063 | 0.609 |
| Sand, low carbon | 0.036 | 0.036 | 0.087 |

Raising the labile stock from the default profile (about 44 kg/ha) to the measured 300 kg/ha raises soluble export in every branch and preserves the soil ranking of the first round. Branch 1's sediment-bound mineral export rises most (to 0.31 kg/ha/yr on the peat), because its inflated mineral pools feed the erosion pathway. The standing limits apply: per-hectare behaviour on a test watershed, not validated basin loads, and the initialisation itself remains a one-number interface that no measured fractionation can fully enter — the finding this round was built to quantify.
