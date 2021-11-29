---
title: "Update PostGIS database"
author: ""
date: "`r format(Sys.time(), '%d %B, %Y')`"
output: 
  NinaR::jensAnalysis:
  highlight: tango
  fig_caption: yes
  toc: yes
---
  
  
```{r load_packages, message = F, warning = F}
# Load packages
require(dplyr)
require(rgrass7)
require(NinaR)

require(sp)
require(raster)
require(terra)
require(rgdal)
require(sf)

require(RPostgres)
require(rpostgis)
```


```{r setup, include=FALSE}
# This is optional
# I choose the 'styler' package for tidying the code to preserve indentations
# I set the cutoff for code tidying to 60, but this doesn't currently work with styler.
# Set tidy = True to get the knitr default
# I want all figures as png and pdf in high quality in a subfolder called figure

knitr::opts_chunk$set(
  eval = FALSE, # do not run anything
  echo = TRUE,
  tidy = "styler",
  dev = c("png", "pdf"),
  dpi = 600,
  fig.path = "figure/"
)

options(
  xtable.comment = F,
  xtable.include.rownames = F,
  nina.logo.y.pos = 0.15
)
palette(ninaPalette())
```


```{r, include = F, eval = F}
# This connects to the gisdatabase with a DBI connection named `con`.
# Use for example dbGetQuery(con, "SELECT * FROM ....") to query the database
source("~/.pgpass")

postgreSQLConnect2 <- function (username = "postgjest", password = "gjestpost", host = "gisdata-db.nina.no", 
                                dbname = "gisdata", ...) 
{
  tmp <- RPostgres::dbConnect(RPostgres::Postgres(), host = host, 
                              dbname = dbname, user = username, password = password, 
                              ...)
  assign("con", tmp, .GlobalEnv)
}

postgreSQLConnect2(
  host = "gisdata-db.nina.no",
  dbname = "gisdata",
  username = pg_username,
  password = pg_password
)

# str_con <- paste0("PG:host=gisdata-db.nina.no user=", pg_username, " password=", pg_password, " dbname=gisdata")

rm(pg_username, pg_password)
```