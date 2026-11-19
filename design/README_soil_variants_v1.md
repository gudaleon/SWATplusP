# Soil-property sensitivity of SWAT+ phosphorus export — Example 8 extension

**Across four topsoils spanning the Lake of the Woods basin's measured property ranges, every phosphorus branch ranks the soils in the same order, but the augmented branch's soluble export spans eightfold while the stock branches span three- to fivefold.**

## Design

The test asks what each phosphorus routine does with the soil properties it reads, on soils the Lake of the Woods programme actually has. The property ranges come from the programme's own SoilGrids extracts over the basin (2.11 million cells): topsoil pH median 5.4 (quartiles 5.2 and 6.0, range 4.0 to 7.8), clay median 18.3 percent (quartiles 15.4 and 21.7, maximum about 68), and soil organic carbon median 48 grams per kilogram in the top five centimetres (quartiles 34.3 and 58.3). Four topsoil variants were written into the first soil layer of every soil in the Ames test watershed (Ames, Iowa; twelve HRUs; the verified SWAT+ harness from the SLC soil-layer project, with its own climate and hydrology unchanged): a Shield median soil (bulk density 1.10, clay 18 percent, carbon 4.8 percent, pH 5.4), an Agassiz clay (bulk density 1.35, clay 45 percent, carbon 2.7 percent, calcium carbonate 8 percent, pH 6.5), an organic peat (bulk density 0.70, clay 10 percent, carbon 15 percent, pH 5.0), and a carbon-poor sand (bulk density 1.55, clay 8 percent, carbon 1.0 percent, pH 5.5). Deeper layers and the water-holding and conductivity properties were left at the shipped values, and the initial phosphorus status was held constant, so the comparison isolates the routines' response to the properties they read. Each variant ran under all three phosphorus branches of the augmented build (sol_p_model 0, 1 and 2) for 1975–1980. The driver is `soil_variant_test.py` in this folder, and the numbers are in `soil_variant_results_v1.csv`.

## Results

Mean annual soluble phosphorus in surface runoff (surqsolp, kilograms of phosphorus per hectare per year), as the unweighted mean over the twelve HRUs:

| Topsoil | Jones (0) | Vadas & White (1) | Augmented (2) |
|---|---|---|---|
| Ames soil as shipped | 0.025 | 0.012 | 0.137 |
| Shield median | 0.033 | 0.014 | 0.182 |
| Agassiz clay | 0.023 | 0.012 | 0.123 |
| Organic peat | 0.081 | 0.031 | 0.563 |
| Sand, low carbon | 0.015 | 0.008 | 0.069 |

Sediment-bound mineral phosphorus (sedminp) runs the other way in every row, as in the original branch comparison, and leaching and tile labile phosphorus are zero in all fifteen runs because this watershed configuration carries no tile signal.

## Reading

All three branches rank the soils identically, peat highest and sand lowest, so the direction of the soil effect is architecture-independent on this set. The magnitude is not. The augmented branch spans 0.069 to 0.563, a factor of about eight, and its ordering follows bulk density exactly, because with a fixed sorption capacity the same labile mass in less soil sits at a higher degree of saturation and therefore at a higher equilibrium concentration. The stock branches span a factor of about five (Jones) and about four (Vadas and White), moving through their initialisation and partition terms rather than through a saturation state. Two limits stand. First, the augmented branch's capacity is still a basin-wide constant in these runs, so its soil sensitivity arrives only through bulk density and water content; giving it a soil-derived capacity is the recorded refinement, and the Yang and Post fraction initialisation is the queued next round. Second, these are per-hectare behaviour differences between architectures on a test watershed, not validated Lake of the Woods loads.
