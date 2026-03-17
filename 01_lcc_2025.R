# 01_connectivity_one_year.R
# Calculate cycling connectivity by census tract for one year

library(sf)
library(igraph)
library(dplyr)
library(leaflet)

# 1. Read data
cycle <- st_read(
  "data/2025_4T_CARRIL_BICI/2025_4T_CARRIL_BICI.shp",
  quiet = TRUE
)

tracts <- st_read(
  "data/Revisió_connectivitat.gpkg",
  layer = "Seccions_censals",
  quiet = TRUE
)

# 2. Prepare data
segments <- cycle |>
  st_transform(25831) |>
  st_cast("LINESTRING")

tracts_m <- tracts |>
  st_transform(25831) |>
  select(MUNDISSEC)

# 3. Build graph of connected cycling segments
buf <- st_buffer(segments, 15)
touch <- st_intersects(buf)
g <- graph_from_adj_list(touch, mode = "all")

# 4. Find connected components
segments$component <- components(g)$membership
segments$len <- as.numeric(st_length(segments))

lcc_id <- segments |>
  st_drop_geometry() |>
  summarise(len = sum(len), .by = component) |>
  slice_max(len, n = 1) |>
  pull(component)

segments$LCC <- segments$component == lcc_id

# 5. Calculate city-level connectivity
connectivity_city <- segments |>
  st_drop_geometry() |>
  summarise(
    total_len = sum(len),
    lcc_len = sum(len[LCC])
  ) |>
  mutate(connectivity = lcc_len / total_len)

connectivity_city

# 6. Calculate connectivity by census tract
segments_tract <- st_intersection(segments, tracts_m)
segments_tract$len <- as.numeric(st_length(segments_tract))

connectivity_tract <- segments_tract |>
  st_drop_geometry() |>
  summarise(
    total_len = sum(len),
    lcc_len = sum(len[LCC]),
    .by = MUNDISSEC
  ) |>
  mutate(connectivity = lcc_len / total_len)

connectivity_tract

# 7. Join results back to tract geometry
tracts_connectivity <- tracts_m |>
  left_join(connectivity_tract, by = "MUNDISSEC")

# 8. Make a simple map
tracts_ll <- st_transform(tracts_connectivity, 4326)

pal <- colorNumeric(
  "YlOrRd",
  domain = tracts_ll$connectivity,
  na.color = "transparent"
)

leaflet(tracts_ll) |>
  addProviderTiles(providers$CartoDB.Positron) |>
  addPolygons(
    fillColor = ~pal(connectivity),
    fillOpacity = 0.7,
    color = "grey40",
    weight = 0.5,
    popup = ~paste0(
      "Census tract: ", MUNDISSEC,
      "<br>Connectivity: ", round(connectivity, 3)
    )
  ) |>
  addLegend(
    pal = pal,
    values = ~connectivity,
    position = "bottomright",
    title = "Connectivity",
    opacity = 0.7
  )