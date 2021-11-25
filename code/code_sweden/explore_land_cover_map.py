#---------------------------------------
# Title: explore land cover map to simplify classes
# Author: Bernardo Niebuhr
# 2020-10-09
#---------------------------------------

python

# import modules
import os
import grass.script as grass
from grass.pygrass.modules.shortcuts import general as g
from grass.pygrass.modules.shortcuts import vector as v
from grass.pygrass.modules.shortcuts import raster as r

# make sure extensions used are installed
#g.extension(extension = "r.fill.gaps")

#---------------------------------------
# Setup

# root folder
root_dir = r"D:\bernardo\00_academico\07_projetos\05_reindeer\05_env_data/"
os.chdir(root_dir)

#---------------------------------------
# Test for Mittadalen reindeer herding district

landscape_dir = r"03_raster/p_sam_landscape/landcover_nmd_ungeneralized/"

# mapset
g.mapset(mapset = "explore_land_cover", flags = "c")

# region
g.region(vector = "availability_general_mittadalen@sam_reindeer_ancillary", res = 10, flags = "ap")

# mask
r.mask(vector = "availability_general_mittadalen@sam_reindeer_ancillary")

# cut land cover map
g.region(vector = "availability_general_mittadalen@sam_reindeer_ancillary", 
    align = "landcover_ungeneralized_nmd1_10m_2018@p_sam_landscape", flags = "ap")

landcover_map_nmd = "landcover_ungeneralized_nmd1_10m_2018@p_sam_landscape"
r.mapcalc(expression = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore = "+landcover_map_nmd,
    overwrite = True)

landcover_map_smd = "landcover_smd_25m_2004@p_sam_landscape"
r.mapcalc(expression = "landcover_smd_mittadalen_explore = landcover_smd_25m_2004@p_sam_landscape",
    overwrite = True)

agriculture_jvb = "agriculture_JBV_2015_rast@p_sam_landscape"
agriculture_smd = "agriculture_SMD_2004_rast@p_sam_landscape"
urban = "urban_lm_2020_rast@p_sam_transport_urban"

# categories
r.category(map = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore", separator = "comma", 
    rules = landscape_dir+"nmd_classes_eng_original.csv")

# report
r.report(map = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore", 
    units = ["k", "p"], flags = "n", output = landscape_dir+"report_land_cover_mittadalen_winter_nmd_orig.txt") #sort = "desc") 

# export
r.out_gdal(input = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore", 
    output = landscape_dir+"landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore.tif",
    createopt = "TFW=YES,COMPRESS=DEFLATE")

#---
# reclassify 6 classes 
r.reclass(input = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore", 
    output = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass", 
    rules = landscape_dir+"nmd_classes_eng_rules_reclassify_v2.txt", overwrite = True)

# fill most gaps
#r.fill_gaps(input = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass",
#    output = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_fill",
#    distance = 11,
#    mode = "mode", flags = "p")

# colors
#r.colors(map = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_fill", 
#    raster = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore")

r.colors(map = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass", 
    raster = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_explore")

# add SMD for some classes

# new classes
# 201, rocks or tundra (from SMD)
# 202, heath (from SMD)


input_nmd = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass"
input_smd = "landcover_smd_mittadalen_explore"
# replace tundra from NMD (41) by rocks/tundra from SMD (59)  
exp = "map_landcover_aux1 = if("+input_nmd+" == 41 && "+input_smd+" == 59, 201, "+input_nmd+")"
r.mapcalc(exp, overwrite = True)
# replace other open land from NMD (42) by heath from SMD (52)  
exp2 = "map_landcover_aux2 = if(map_landcover_aux1 == 42 && "+input_smd+" == 52, 202, map_landcover_aux1)"
r.mapcalc(exp2, overwrite = True)
# clasify ski slopes (17) and urban areas as anthropogenic
exp3 = "map_landcover_aux3 = if(!isnull("+urban+") || "+input_smd+" == 17, 51, map_landcover_aux2)"
r.mapcalc(exp3, overwrite = True)
# merge what remains as 41 and 42 as 41 = other open lands
exp4 = "map_landcover_aux4 = if(map_landcover_aux3 == 42, 41, map_landcover_aux3)"
r.mapcalc(exp4, overwrite = True)
# in other open lands (41), if there is agriculture SMD or JBM, consider as arable lands (2)
exp5 = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_nmd_smd = if(map_landcover_aux4 == 41 && \
(!isnull("+agriculture_jvb+") || !isnull("+agriculture_smd+")), 3, map_landcover_aux4)"
r.mapcalc(exp5, overwrite = True)

# classes
r.category(map = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_nmd_smd",
    rules = landscape_dir+"nmd_classes_eng_reclassified.csv", separator = "comma")

# report
r.report(map = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_nmd_smd", 
    units = ["k", "p"], flags = "n", output = landscape_dir+"report_land_cover_mittadalen_winter_reclass.txt",
    overwrite = True) #sort = "desc") 

# export
r.out_gdal(input = "landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_nmd_smd", 
    output = landscape_dir+"landcover_ungeneralized_nmd1_10m_2018_mittadalen_reclass_nmd_smd.tif",
    createopt = "TFW=YES,COMPRESS=DEFLATE", overwrite = True)

