#' ---
#' title: "Exploring the existing GRASS GIS databases"
#' author: Bernardo Niebuhr
#' output: 
#'   html_document: default
#'   github_document: default
#' ---

# libraries
library(dplyr)
library(rgrass7)
library(NinaR)
library(stringr)
library(tibble)
library(readr)

source("code/functions.R")

# connect to my mapset
grassdir <- system("grass78 --config path", intern = T)
gisDB <- "Mounts/grass"
loc <- "ETRS_33N/"
ms <- "u_bernardo.brandao"

# initGRASS(gisBase = grassdir,
#           home = tempdir(), 
#           override = T,
#           gisDbase = gisDB,
#           location = loc, 
#           mapset = ms)

grassConnect(mapset = ms)

# check mapsets
sep <- " "
all_mapsets <- execGRASS("g.mapsets", flags = c("l"), intern = T) %>% 
  strsplit(sep) %>% 
  first()

# get mapsets for "rein"
mapset_patt_rein <- c("Rein", "rein") %>% 
  paste(collapse = "|")
mapsets_rein <- all_mapsets %>% 
  grep(pattern = mapset_patt_rein, value = T)

# get mapsets for "Prodchange"
mapset_patt_pc <- c("change") %>% 
  paste(collapse = "|")
mapsets_pc <- all_mapsets %>% 
  grep(pattern = mapset_patt_pc, value = T) %>% 
  grep(pattern = paste(mapsets_rein,collapse = "|"), invert = T, value = T)

all_relevant_mapsets <- c(mapsets_rein, mapsets_pc)

# list maps
execGRASS("g.list", parameters = list(type = "raster", mapset = mapsets_rein[1]), intern = T)

# test function
gr_g_list(parms = list(type = "raster"), mapset = mapsets_rein[1])

# all mapsets - raster
all_rasters <- sapply(all_relevant_mapsets, gr_g_list, flags = NULL, parms = list(type = "raster"), pre = "r@")
all_rasters

# all mapsets - vector
all_vectors <- sapply(all_relevant_mapsets, gr_g_list, flags = NULL, parms = list(type = "vector"), pre = "v@")
all_vectors

# all
all_maps <- Map(c, all_rasters, all_vectors)
all_maps

# empty mapsets
empty_mapsets <- names(all_maps)[sapply(all_maps, length) == 0]

non_empty_mapsets <- names(all_maps)[sapply(all_maps, length) != 0]


#--------------------
# create table to document things

# list used layers
source("code/get_maps_from_grass_bram.R")
head(env_vars)

layers <- strsplit(env_vars, split = "@") %>% 
  sapply(first)
mapsets <- strsplit(env_vars, split = "@") %>% 
  sapply(last)

metadata_struct <- read.csv("data/spatialdb_metadata_sweden_20211101.csv")
metadata_as_it_is <- metadata_struct[1:length(layers), 1:19]
metadata_as_it_is[] <- NA
colnames(metadata_as_it_is) <- gsub(".", "_", colnames(metadata_as_it_is), fixed = T) %>% 
  stringr::str_to_lower()

# set
metadata_as_it_is$layer_name <- layers
metadata_as_it_is$folder <- mapsets
metadata_as_it_is <- metadata_as_it_is %>% 
  dplyr::rename(old_folder = folder) %>% 
  tibble::add_column(folder = NA, .after = 3)

# DT::datatable(metadata_as_it_is, editable = TRUE)

# prepare metadata to be written
readr::write_csv(metadata_as_it_is, file = "data/spatialdb_metadata_oneimpact_20211122.csv")
