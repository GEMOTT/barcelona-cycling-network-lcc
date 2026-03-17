# 03_plot_results.R
# Plot city results and map tract results for one year

library(sf)
library(dplyr)
library(ggplot2)
library(leaflet)

# 1. Read saved outputs
connectivity_city <- readRDS("output/connectivity_city.rds")
connectivity_tract <- readRDS("output/connectivity_tract.rds")
tracts <- readRDS("output/tracts.rds")

# 2. Plot city-level connectivity over time
ggplot(connectivity_city, aes(year, connectivity)) +
  geom_line() +
  geom_point()

# 3. Choose one year to map
year_map <- 2025

# 4. Keep only results for that year
connectivity_year <- connectivity_tract |>
  filter(year == year_map)

print(head(connectivity_year))

# 5. Prepare tract geometry
tracts_map <- tracts |>
  st_transform(25831) |>
  select(MUNDISSEC)

print(head(tracts_map))

# 6. Join geometry and connectivity
tracts_map <- left_join(tracts_map, connectivity_year, by = "MUNDISSEC")

print(head(tracts_map))

# 7. Transform for leaflet
tracts_map <- st_transform(tracts_map, 4326)

# 8. Make palette
pal <- colorNumeric(
  palette = "YlOrRd",
  domain = tracts_map$connectivity,
  na.color = "transparent"
)

# 9. Make map
leaflet(data = tracts_map) |>
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
