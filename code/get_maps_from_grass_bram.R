# Get variables ---------------------------------
env_vars <- c("skog", "lavskog", "myr", "ridges", "grasses", "heather_ridges", "lichen", "heather_lowland", "heathland", "meadows", "snowbed", "snow", "glacier", "dyrka")
env_vars <- paste0("norut_", env_vars, "_100@p_RenRein_norut")
env_vars
env_vars <- c(env_vars, "Norway_PCA_klima_axis1@g_BiogeographicalRegions_Norway_PCA_klima", "Norway_PCA_klima_axis2@g_BiogeographicalRegions_Norway_PCA_klima",
              "Norway_PCA_klima_axis3@u_bram.van.moorter", "Norway_PCA_klima_axis4@u_bram.van.moorter",
              "beitedyr_5000@u_bram.van.moorter", "beitedyr_10000@u_bram.van.moorter")

tmp <- data.frame(layer=c("dem_10m_nosefi_float_slope", "solar_radiation_10m_july"),mapset=c("g_Elevation_Fenoscandia", "g_EnergyResources_Fenoscandia"))
tmp <- apply(tmp, 1, paste0, collapse="@")
env_vars <- c(env_vars, tmp)

tmp <- data.frame(layer=c("houses_XXXX", "private_cabins_XXXX",  "pub_cabins_summer_high_XXXX", "pub_cabins_summer_low_XXXX", "pub_cabins_winter_high_XXXX", "pub_cabins_winter_low_XXXX", 
                          "powerlines_XXXX", "railway_XXXX", "roads_summer_high_XXXX", "roads_summer_low_XXXX", "roads_winter_high_XXXX", "roads_winter_low_XXXX", "trails_high_XXXX", 
                          "trails_low_XXXX", "skitracks_cal_high_XXXX", "skitracks_cal_low_XXXX", "skitracks_win_high_XXXX", "skitracks_win_low_XXXX"),
                  mapset=c(rep("p_prodchange_envpointsTT", 6), rep("p_prodchange_roadsTT", 6), rep("p_RenRein_trails2", 2), rep("p_prodchange_trailsTT", 4)))
tmp <- apply(tmp, 1, paste0, collapse="@")
tmp <- expand.grid(tmp, as.character(c(100, 250, 500, 1000, 2500, 5000, 10000)))
tmp <- apply(tmp, 1, function(x){sub("XXXX", x[2], x[1])})
env_vars <- c(env_vars, tmp)

tmp <- data.frame(layer=c("norut_dyrka_XXXX_100m", "norut_impediment_XXXX_100m", "norut_lav_XXXX_100m", "norut_lavskog_XXXX_100m", 
                          "norut_myr_XXXX_100m", "norut_open_XXXX_100m", "norut_skog_XXXX_100m"), 
                  mapset=rep("g_LandCover_Norway_NORUT_SAM_TT", 7))
tmp <- apply(tmp, 1, paste0, collapse="@")
tmp <- expand.grid(tmp, as.character(c(100, 250, 500, 1000, 2500, 5000, 10000)))
tmp <- apply(tmp, 1, function(x){sub("XXXX", x[2], x[1])})
env_vars <- c(env_vars, tmp)

tmp <- data.frame(layer=c("lakes_XXXX", "reservoirs_XXXX", "maxAverageAllYrs_XXXX_100m_2", "sprAverageAllYrs_XXXX_100m_2", "dem_tpi_XXXX_50m"), 
                  mapset=c(rep("p_prodchange_envpolyTT", 2), rep("g_LandCover_Fenoscndia_PHENOLOGY_SAM_TT", 2), "g_Elevation_Fenoscandia_TPI"))
tmp <- apply(tmp, 1, paste0, collapse="@")
tmp <- expand.grid(tmp, as.character(c(250, 500, 1000, 2500, 5000, 10000)))
tmp <- apply(tmp, 1, function(x){sub("XXXX", x[2], x[1])})
env_vars <- c(env_vars, tmp)

tmp <- data.frame(layer=c("snowDepth_avg_00_18_XXXX"), 
                  mapset=c("u_torkildtveraa"))
tmp <- apply(tmp, 1, paste0, collapse="@")
tmp <- expand.grid(tmp, as.character(c(1000, 2500, 5000, 10000)))
tmp <- apply(tmp, 1, function(x){sub("XXXX", x[2], x[1])})
env_vars <- c(env_vars, tmp)

length(env_vars)
