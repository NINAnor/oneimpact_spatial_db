library(dplyr)

# function to print maps (g.list) adding @mapsetname
gr_g_list <- function(flags = NULL, parms = NULL, mapset = NULL, pre = "", ...) {
  names <- execGRASS("g.list", flags = flags, parameters = c(parms, mapset = mapset), intern = T, ...)
  ifelse(names == "", "", paste0(pre, names, "@", mapset))
}

# function to benchmark different approaches for neighborhood analysis
# bna = benchmark  for neighborhood analysis
bna <- function(input_map_grass, input_map_r, size_m, size_pixels, unit = "s", quiet = TRUE, ...) {
  # flags
  flg <- if(quiet) c("overwrite", "quiet") else "overwrite"
  
  microbenchmark(
    "r.resamp.filter" = {
      execGRASS("r.resamp.filter",
                parameters = list(input = input_map_grass, output = paste0("rsp_filter_", input_map_grass, "_", size_m),
                                  filter = "bartlett", radius = size_m),
                flags = flg)
    },
    "r.neighbors" = {
      execGRASS("r.neighbors", 
                parameters = list(input = input_map_grass, output = paste0("neighbors_", input_map_grass, "_", size_m),
                                  method = "average", size = size_pixels),
                flags = c("c", flg))
    },
    "focal in terra" = {
      terra_focal <- terra::focal(input_map_r, w = size_pixels, fun = "mean")
      names(terra_focal) <- paste0("focal_", input_map_grass, "_", size_m)
    }, unit = unit, ...)#,
  # "focal in raster" = {
  #   terra_focal <- raster::focal(input_map_raster, w = size_pixels, fun = "mean")
  # })
}

# function to update the metadata
update_metadata <- function(md, 
                            maps, type_of_info, mapset_from, new_mapset, 
                            variables, institution = NA, description = NA, 
                            unit = NA, type_data = c("raster", "vector")[1],
                            original_range_values = NA, year_data = NA,
                            original_pixel_res = NA, final_pixel_res = NA,
                            extent = NA, primary_derived = NA, derived_form = NA,
                            website = NA, source = NA, obtained_through = NA, 
                            observations = NA) {
  
  # check if there are maps not present in the metadata table
  # add new rows for them
  if(!all(maps %in% md$layer_name)) {
    not_in_table <- setdiff(maps, md$layer_name)
    n_new <- length(not_in_table)
    tab_new <- md[1:n_new,] 
    tab_new[1:n_new] <- NA
    tab_new$layer_name <- not_in_table
    md <- dplyr::bind_rows(md, tab_new)
  }

  cont <- 1
  for(i in maps) {
    which_line <- which(md$layer_name == i)
    md$type_of_information[which_line] <- type_of_info
    md$old_folder[which_line] <- mapset_from
    md$folder[which_line] <- new_mapset
    md$variable[which_line] <- variables[cont]
    md$institution[which_line] <- institution
    md$description[which_line] <- description
    md$unit[which_line] <- unit
    md$type_of_spatial_data[which_line] <- type_data
    md$original_raster_range_values[which_line] <- original_range_values
    md$year_of_original_data[which_line] <- year_data
    md$original_pixel_resolution[which_line] <- original_pixel_res
    md$final_pixel_resolution[which_line] <- extent
    md$extent[which_line] <- extent
    md$primary_or_derived[which_line] <- primary_derived
    md$derived_from[which_line] <- derived_form
    md$website[which_line] <- website
    md$source[which_line] <- source
    md$obtained_through[which_line] <- obtained_through
    md$observations[which_line] <- observations
    
    cont <- cont+1
  }
  
  md %>% 
    dplyr::arrange(type_of_information, layer_name)
}
