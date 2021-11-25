import grass.script as gscript
from grass.pygrass.modules.shortcuts import general as g
from grass.pygrass.modules.shortcuts import vector as v
from grass.pygrass.modules.shortcuts import raster as r

'''
Mapsets and maps:

  p_RenRein_norut: 
    land use from norut
    question: snow, snow_100 - what is the difference? resolution 30 and 100?
    
  g_BiogeographicalRegions_Norway_PCA_klima: 
	  climate PCAs 1 and 2 (why not 3 and 4)?
	  
  u_bram.van.moorter: 
    beitedyr5000 (grazing animals, mostly sheep);
    climate PCAs 3 and 4
    NOT USED digestible_biomass_summ_wint
    NOT USED several layers of distance to the nearest feature and density at 
  		  different scales for different infrastructure
  		  
  p_prodchange_envpointsTT:
    density of point infrastructure (houses, private cabins, public cabins - high,low,summer,winter)
    
  p_prodchange_roadsTT:
    density of line infrastructure (power lines, railways, roads - high,low,summer,winter)
    
  p_RenRein_trails2:
    density of line infrastructure (trails - high,low)
    
  p_prodchange_trailsTT:
    density of line infrastructure (skitracks - calving,winter,high,low)
    
  g_LandCover_Norway_NORUT_SAM_TT:
    density of land cover types
    
  p_prodchange_envpolyTT:
    density of polygons (lakes, reservoirs)
    
  g_LandCover_Fenoscndia_PHENOLOGY_SAM_TT: ????????
    maxAverageAllYrs_XXXX_100m_2, sprAverageAllYrs_XXXX_100m_2
  
  g_Elevation_Fenoscandia_TPI:
    density of TPI
    
  u_torkildtveraa:
    snow depth average
'''

'''
Questions:
- in Bram's script, not using elevation? (only TPI, slope)
'''

# list mapsets be theme
land_use_mapsets = ["p_RenRein_norut", "g_LandCover_Norway_NORUT_SAM_TT", "p_prodchange_envpolyTT"]
landscape_mapsets = ["g_Elevation_Fenoscandia", "g_LandCover_Fenoscndia_PHENOLOGY_SAM_TT", "g_Elevation_Fenoscandia_TPI"]
climate_mapsets = ["g_BiogeographicalRegions_Norway_PCA_klima", "u_bram.van.moorter",
"g_EnergyResources_Fenoscandia", "u_torkildtveraa"]
infrastructure_mapsets = ["p_prodchange_envpointsTT", "p_prodchange_roadsTT", "p_RenRein_trails2", 
"p_prodchange_trailsTT", ]

all_relevant_mapsets = land_use_mapsets + landscape_mapsets + climate_mapsets + infrastructure_mapsets

# access to mapsets
g.mapsets(mapset = all_relevant_mapsets)


# create new mapsets
