#' ---
#' title: 'Reorganazing and renaming spatial data from RenGIS for the Vindval project'
#' author: Bernardo Niebuhr
#' date: February 2020
#' ---

#---- settings

# clean workspace
rm(list = ls())

# load libraries
library(install.load)
install.load::install_load("tidyverse")
install.load::install_load("sf", "raster", "lwgeom")

# path where RenGIS data files are located
rengis_path <- "C:/Users/Public/Documents/RenGIS/"

# path where to save spatial layers
rein_main <- "02_vector/sam_reindeer_main/" # to save main GPS data
rein_ancillary <- "02_vector/sam_reindeer_ancillary/" # ancillary data
env <- "02_vector/sam_env/" # env data

# CRS to use
# crs.proj <- "+proj=utm +zone=33 +ellps=GRS80 +units=m +no_defs"
crs_to_use <- 3006

#---- load_data

#--- 
# Sweden limits data

# Sweden limits
sweden <- raster::getData("GADM", country = "SWE", level = 0) %>% 
  sf::st_as_sf() %>% 
  sf::st_transform(crs = crs_to_use)

# erase downloaded file
unlink("gadm36_SWE_0_sp.rds", force = TRUE)

# plot
ggplot() +
  geom_sf(data = sweden) +
  theme_minimal()

# export limit
out_name <- paste0(rein_ancillary, "limit_sweden_GADM")
sweden %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
sweden %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

# useful - buffer arround sweden
# NOT doing, it was taking too long
# CHECK: are there corrals outside Sweden?
# swe_buff <- sweden %>% 
#   sf::st_buffer(dist = 1000)

#---
# Sameby (herding district) limits

sameby_file <- "IRENMARK_DBO_sameby"
sameby <- paste0(rengis_path, "iRenMark/LstGIS.2018-02-19/Samebyarnas betesområden/", sameby_file, ".shp") %>% 
  sf::read_sf()

# plot
plot(sameby["NAMN"])

# Remove special characters
sameby <- sameby %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(rein_ancillary, "sameby_limits_", sameby_file)
sameby %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
sameby %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

# useful - sameby limits with no borders
sameby_buff50km <- sameby %>% 
  # as("Spatial") %>% 
  # sf::st_as_sfc() %>% 
  sf::st_make_valid() %>% 
  sf::st_buffer(dist = 50000) %>% 
  sf::st_union() %>% 
  sf::st_sf() %>% 
  sf::st_set_crs(st_crs(sweden)) %>% 
  sf::st_intersection(y = sweden) %>% 
  dplyr::mutate(limit = "sameby")

plot(sameby_buff50km)

sameby_buff50km <- sameby_buff50km %>% 
  dplyr::select(-c(1:2,4)) %>% 
  dplyr::mutate(limit = "sameby")

# export
out_name <- paste0(rein_ancillary, "sameby_limits_buff_50km")
sameby_buff50km %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
sameby_buff50km %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Administrative limits (old limits for Lapland etc.)

adm_file <- "IRENMARK_DBO_adm_grans"
adm_lim <- paste0(rengis_path, "iRenMark/LstGIS.2018-02-19/Samebyarnas betesområden/", adm_file, ".shp") %>% 
  sf::read_sf()

# plot
plot(adm_lim["OBJECTID"])

# Remove special characters
adm_lim <- adm_lim %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(rein_ancillary, "administrative_limits_", adm_file)
adm_lim %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
adm_lim %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# corrals
corrals_file <- "IRENMARK_DBO_anl"
corrals <- paste0(rengis_path, "iRenMark/LstGIS.2018-02-19/Samebyarnas markanvändningsredovisning/Stategiska områden/", corrals_file, ".shp") %>% 
  sf::read_sf()

# check valid positions - is there a better way of doing that?
corrals <- corrals %>% 
  sf::st_join(sameby_buff50km, join = st_intersects) %>% 
  dplyr::filter(!is.na(limit)) %>% 
  dplyr::select(1:ncol(corrals))
# 59 corrals REMOVED! 

# plot
plot(corrals["SAMEBY1"], pch = 20)

# Remove special characters
corrals <- corrals %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# check
for(i in sort(unique(corrals$BESKRIVNIN))) print(i)
for(i in sort(unique(corrals$SAMEBY1))) print(i)

# export
out_name <- paste0(rein_ancillary, "corrals_", corrals_file)
corrals %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
corrals %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Seasonal areas (arstidsland), defined by the Sami
folder <- "iRenMark/LstGIS.2018-02-19/Samebyarnas markanvändningsredovisning/Årstidsland/"
shapefiles <- list.files(paste0(rengis_path, folder), full.names = T) %>% 
  grep(pattern = ".shp$", value = T)

for(shp in shapefiles) {
  season <- shp %>% 
    sf::read_sf()
  season
  
  # plot
  plot(season[,1])
  
  # Remove special characters
  season <- season %>% 
    dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))
  
  # export
  out_name <- paste0(rein_ancillary, "seasonal_areas_",
                     stringr::str_split(shp, pattern = "/")[[1]] %>% 
                       dplyr::last() %>%
                       stringr::str_replace(".shp", ""))
  season %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
  season %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)
}

#---
# Migration routes, difficult passages, fences
folder <- "iRenMark/LstGIS.2018-02-19/Samebyarnas markanvändningsredovisning/Stategiska områden/"
patt <- c("led", "pass", "stg")
shapefiles <- list.files(paste0(rengis_path, folder), full.names = T) %>% 
  grep(pattern = ".shp$", value = T) %>% 
  grep(pattern = paste(patt, collapse = "|"), value = T)

names <- c("migration_routes", "hard_passages", "fences")

cont <- 1
for(shp in shapefiles) {
  shp_read <- shp %>% 
    sf::read_sf()
  shp_read
  
  # plot
  plot(shp_read[,1])
  
  # Remove special characters
  shp_read <- shp_read %>% 
    dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))
  
  # export
  out_name <- paste0(rein_ancillary, names[cont], "_",
                     stringr::str_split(shp, pattern = "/")[[1]] %>% 
                       dplyr::last() %>%
                       stringr::str_replace(".shp", ""))
  shp_read %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
  shp_read %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)
  
  cont <- cont + 1
}

#---
# Houses
year <- 2020
files_infrastructure <- list.files(paste0(rengis_path, "Omvärldsfaktorer ", year, "/Övrig infrastruktur/"), pattern = ".shp$",
                                   full.names = T)
files_infrastructure

houses_file <- files_infrastructure %>% 
  grep(pattern = "Hus", value = T)
houses <- houses_file %>% 
  sf::read_sf()

# check valid positions - is there a better way of doing that?
# houses <- houses %>% 
#   sf::st_join(sameby_out, join = st_intersects) %>% 
#   dplyr::filter(!is.na(limit)) %>% 
#   dplyr::select(1:ncol(houses))
# 12 houses REMOVED! 

# Remove special characters
houses <- houses %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
houses_out <- houses_file %>% 
  stringr::str_replace("_ek ", "_") %>% 
  stringr::str_split("/") %>% 
  last() %>% last() %>% 
  stringr::str_replace(".shp", "")
out_name <- paste0(env, "houses_", houses_out)
houses %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
houses %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

# houses_buffer <- houses %>% 
#   sf::st_buffer(dist = 100)

#---
# Buildings
files_infrastructure

buildings_file <- files_infrastructure %>% 
  grep(pattern = "Byggnader", value = T)
buildings <- buildings_file %>% 
  sf::read_sf()

# check valid positions - is there a better way of doing that?
# buildings <- buildings %>% 
#   sf::st_join(sameby.out, join = st_intersects) %>% 
#   dplyr::filter(!is.na(limit)) %>% 
#   dplyr::select(1:ncol(buildings))
# 12 buildings REMOVED! 

# Remove special characters
buildings <- buildings %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
buildings_out <- buildings_file %>% 
  stringr::str_replace("_ek ", "_") %>% 
  stringr::str_split("/") %>% 
  last() %>% last() %>% 
  stringr::str_replace(".shp", "")
out_name <- paste0(env, "buildings_", buildings_out)
buildings %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
buildings %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Villages/Urban areas
files_infrastructure

urban_file <- files_infrastructure %>% 
  grep(pattern = "Bebyggelse", value = T)
urban <- urban_file %>% 
  sf::read_sf()

# check valid positions - is there a better way of doing that?
# urban <- urban %>% 
#   sf::st_join(sameby.out, join = st_intersects) %>% 
#   dplyr::filter(!is.na(limit)) %>% 
#   dplyr::select(1:ncol(urban))
# 12 urban REMOVED! 

# plot
plot(urban[1])

# Remove special characters
urban <- urban %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
urban_out <- urban_file %>% 
  stringr::str_split("/") %>% 
  last() %>% last() %>% 
  stringr::str_replace(".shp", "") %>% 
  iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT') %>% 
  paste0(., "_", year)
out_name <- paste0(env, "urban_", urban_out)
urban %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
urban %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Wind power - wind turbines
year <- 2020
folder <- paste0("Omvärldsfaktorer ", year, "/Vindkraft/")

wind_files <- list.files(paste0(rengis_path, folder), pattern = ".shp$")

shapefile <- wind_files %>% 
  grep(pattern = "Vindkraft", value = T) %>% 
  stringr::str_replace(".shp", "")
wind_turbines <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()

# plot
plot(wind_turbines[1])

# Remove special characters
wind_turbines <- wind_turbines %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT')) %>% 
  dplyr::mutate_at(1:(ncol(.)-1), as.character)

# # Remove special characters
# wind.turbines <- wind.turbines %>% 
#   dplyr::mutate_if(is.character, function(x) {
#     from <- unlist(stringi::stri_enc_detect(x))
#     format.from <- unname(from[attr(from, "names") == "Encoding1"])
#     unname(mapply(iconv, x, from = format.from, MoreArgs = list(to = "ASCII//TRANSLIT")))
#   }
#   )

newsf_wind <- sf::st_zm(wind_turbines, drop = T, what = 'ZM')

# export
out_name <- paste0(env, "wind_turbines_", shapefile, "_", year)
newsf_wind %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
newsf_wind %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

# only wind turbines in operation
wind_turbines_operation <- newsf_wind %>% 
  dplyr::filter(Status == "Uppfort")

# export
out_name <- out_name %>% 
  stringr::str_replace("turbines", "turbines_operation")
wind_turbines_operation %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
wind_turbines_operation %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Wind power - areas of national interest for wind power
wind_files

shapefile <- wind_files %>% 
  grep(pattern = "Riksintresse", value = T) %>% 
  stringr::str_replace(".shp", "")
wind_interest_areas <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
wind_interest_areas

# plot
plot(wind_interest_areas[1])

# Remove special characters
wind_interest_areas <- wind_interest_areas %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

newsf <- sf::st_zm(wind_interest_areas, drop = T, what = 'ZM')

# export
out_name <- paste0(env, "wind_interest_areas_", stringr::str_replace_all(shapefile, pattern = " ", "_"), "_", year)
newsf %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
newsf %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Public roads
year <- 2020
folder <- paste0("Omvärldsfaktorer ", year, "/Övrig infrastruktur/")

other_infra <- list.files(paste0(rengis_path, folder), pattern = ".shp$")

shapefile <- other_infra %>% 
  grep(pattern = "Allmänna vägar", value = T) %>% 
  stringr::str_replace(".shp", "")
public_roads <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
public_roads

# plot
plot(public_roads[,1])

# Remove special characters
public_roads <- public_roads %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "public_roads_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     stringr::str_replace_all(pattern = "ä", "a"))
public_roads %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
public_roads %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Private (small) roads
other_infra

shapefile <- other_infra %>% 
  grep(pattern = "Övriga vägar", value = T) %>% 
  stringr::str_replace(".shp", "")
private_roads <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
private_roads

# plot
plot(private_roads[,1])

# Remove special characters
# private_roads <- private_roads %>% 
#   dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "private_roads_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'))
private_roads %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
private_roads %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Railways
other_infra

shapefile <- other_infra %>% 
  grep(pattern = "Järnvägar", value = T) %>% 
  stringr::str_replace(".shp", "")
railways <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
railways

# plot
plot(railways[,1])

# Remove special characters
# railways <- railways %>% 
#   dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "railways_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'))
railways %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
railways %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Power lines
other_infra

shapefile <- other_infra %>% 
  grep(pattern = "Kraftledningar", value = T) %>% 
  stringr::str_replace(".shp", "")
pl <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
pl

# plot
plot(pl[,1])

# Remove special characters
pl <- pl %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "power_lines_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'))
pl %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
pl %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Snow mobile trails
other_infra

shapefile <- other_infra %>% 
  grep(pattern = "Skoterleder", value = T) %>% 
  stringr::str_replace(".shp", "")
snowmobile_trails <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
snowmobile_trails

# plot
plot(snowmobile_trails[,1])

# Remove special characters
snowmobile_trails <- snowmobile_trails %>% 
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "snow_mobile_trails_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'))
snowmobile_trails %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
snowmobile_trails %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Trails
other_infra

shapefile <- other_infra %>% 
  grep(pattern = "Stigar", value = T) %>% 
  stringr::str_replace(".shp", "")
trails <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
trails

# plot
plot(trails[,1])

# Remove special characters
# trails <- trails %>% 
#   dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "trails_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'))
trails %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
trails %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Mining
year <- 2020
folder <- paste0("Omvärldsfaktorer ", year, "/Gruvor/")

mining_files <- list.files(paste0(rengis_path, folder), pattern = ".shp$")

shapefile <- mining_files %>% 
  grep(pattern = "Beviljade bearbetningskoncessioner", value = T) %>% 
  stringr::str_replace(".shp", "")
mining_areas <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
mining_areas

# plot
plot(mining_areas[,1])

# Remove special characters
mining_areas <- mining_areas %>%
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "mining_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'), "_", year)
mining_areas %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
mining_areas %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Mining signature
mining_files

shapefile <- mining_files %>% 
  grep(pattern = "Beviljade markkoncessioner", value = T) %>% 
  stringr::str_replace(".shp", "")
mining_signature <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
mining_signature

# plot
plot(mining_signature[,1])

# Remove special characters
mining_signature <- mining_signature %>%
  dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "mining_signature_", stringr::str_replace_all(shapefile, pattern = " ", "_") %>% 
                     iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT'), "_", year)
mining_signature %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
mining_signature %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Agriculture - JBV
year <- 2020
folder <- paste0("Omvärldsfaktorer ", year, "/Jordbruk/")

agri_files <- list.files(paste0(rengis_path, folder), pattern = ".shp$")

shapefile <- agri_files %>% 
  grep(pattern = "JBV", value = T) %>% 
  stringr::str_replace(".shp", "")
agri_jbv <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
agri_jbv

# plot
plot(agri_jbv[,1])

# Remove special characters
# agri_jbv <- agri_jbv %>%
#   dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

newsf <- sf::st_zm(agri_jbv, drop = T, what = 'ZM')

# export
out_name <- paste0(env, "agriculture_", stringr::str_split(shapefile, " ") %>% 
                     first() %>% first() %>% 
                     paste0(., "_JBV"))
newsf %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
newsf %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)

#---
# Agriculture - SMD
agri_files

shapefile <- agri_files %>% 
  grep(pattern = "SMD", value = T) %>% 
  stringr::str_replace(".shp", "")
agri_smd <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
agri_smd

# plot
plot(agri_smd[,1])

# Remove special characters
# agri_smd <- agri_smd %>%
#   dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "agriculture_", stringr::str_split(shapefile, " ") %>% 
                     first() %>% first() %>% 
                     paste0(., "_SMD"))
agri_smd %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
agri_smd %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)


#---
# Forestry - clear cuts
year <- 2020
folder <- paste0("Omvärldsfaktorer ", year, "/Skogsbruk/")

forestry_files <- list.files(paste0(rengis_path, folder), pattern = ".shp$")

shapefile <- forestry_files %>% 
  grep(pattern = "Utf", value = T) %>% 
  stringr::str_replace(".shp", "")
clear_cuts <- paste0(rengis_path, folder, shapefile, ".shp") %>% 
  sf::read_sf()
clear_cuts

# plot
plot(clear_cuts[,1])

# add year column
clear_cuts <- clear_cuts %>% 
  dplyr::mutate(year = lubridate::year(Avvdatum)) %>% 
  print(width = Inf)

# Remove special characters
# clear_cuts <- clear_cuts %>%
#   dplyr::mutate_if(is.character, function(x) iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT'))

# export
out_name <- paste0(env, "clear_cuts_", stringr::str_replace(shapefile, pattern = fixed("("), "") %>% 
                     stringr::str_replace(fixed(")"), "") %>%
                     stringr::str_replace_all(" ", "_")) %>% 
  iconv(from = 'UTF-8', to = 'ASCII//TRANSLIT')
clear_cuts %>% sf::st_write(paste0(out_name, ".shp"), delete_dsn = T)
clear_cuts %>% sf::st_write(paste0(out_name, ".gpkg"), delete_dsn = T)
