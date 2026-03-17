# 02_connectivity_all_years.R
# Repeat the same calculation for all years

library(sf)
library(igraph)
library(dplyr)

# 1. Read census tracts once
tracts <- st_read(
  "data/Revisió_connectivitat.gpkg",
  layer = "Seccions_censals",
  quiet = TRUE
)

tracts_m <- tracts |>
  st_transform(25831) |>
  select(MUNDISSEC)

# 2. Function for one year
get_connectivity_year <- function(year, tracts_m) {
  
  cycle <- st_read(
    paste0("data/", year, "_4T_CARRIL_BICI/", year, "_4T_CARRIL_BICI.shp"),
    quiet = TRUE
  )
  
  segments <- cycle |>
    st_transform(25831) |>
    st_cast("LINESTRING")
  
  buf <- st_buffer(segments, 15)
  touch <- st_intersects(buf)
  g <- graph_from_adj_list(touch, mode = "all")
  
  segments$component <- components(g)$membership
  segments$len <- as.numeric(st_length(segments))
  
  lcc_id <- segments |>
    st_drop_geometry() |>
    summarise(len = sum(len), .by = component) |>
    slice_max(len, n = 1) |>
    pull(component)
  
  segments$LCC <- segments$component == lcc_id
  
  city_result <- segments |>
    st_drop_geometry() |>
    summarise(
      total_len = sum(len),
      lcc_len = sum(len[LCC])
    ) |>
    mutate(
      connectivity = lcc_len / total_len,
      year = year
    )
  
  segments_tract <- st_intersection(segments, tracts_m)
  segments_tract$len <- as.numeric(st_length(segments_tract))
  
  tract_result <- segments_tract |>
    st_drop_geometry() |>
    summarise(
      total_len = sum(len),
      lcc_len = sum(len[LCC]),
      .by = MUNDISSEC
    ) |>
    mutate(
      connectivity = lcc_len / total_len,
      year = year
    )
  
  list(city = city_result, tract = tract_result)
}

# 3. Run all years
years <- 2017:2025

results <- lapply(years, get_connectivity_year, tracts_m = tracts_m)

connectivity_city <- bind_rows(lapply(results, `[[`, "city"))
connectivity_tract <- bind_rows(lapply(results, `[[`, "tract"))

dir.create("output", showWarnings = FALSE)

saveRDS(connectivity_city, "output/connectivity_city.rds")
saveRDS(connectivity_tract, "output/connectivity_tract.rds")
saveRDS(tracts, "output/tracts.rds")
