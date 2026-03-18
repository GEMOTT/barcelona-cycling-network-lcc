#| message: false
#| warning: false
#| include: false
#| paged-print: false
# Visualise connectivity by census tract over time

library(sf)
library(igraph)
library(dplyr)
library(ggplot2)
library(gifski)

years <- 2017:2025
buffer_dist <- 5
crs_use <- 25831

tracts <- st_read(
  "data/Revisió_connectivitat.gpkg",
  layer = "Seccions_censals",
  quiet = TRUE
)

tracts_m <- tracts |>
  st_transform(crs_use) |>
  select(MUNDISSEC)

results_city <- vector("list", length(years))
results_tract <- vector("list", length(years))
results_segments_map <- vector("list", length(years))
results_lcc_map <- vector("list", length(years))
results_tract_map <- vector("list", length(years))

for (i in seq_along(years)) {
  
  y <- years[i]
  
  segments <- st_read(
    paste0("data/", y, "_4T_CARRIL_BICI/", y, "_4T_CARRIL_BICI.shp"),
    quiet = TRUE
  ) |>
    st_transform(crs_use) |>
    st_cast("LINESTRING")
  
  buf <- st_buffer(segments, buffer_dist)
  touch <- st_intersects(buf)
  g <- graph_from_adj_list(touch, mode = "all")
  
  segments$component <- components(g)$membership
  segments$len <- as.numeric(st_length(segments))
  
  lcc_id <- segments |>
    st_drop_geometry() |>
    summarise(len = sum(len), .by = component) |>
    slice_max(len, n = 1, with_ties = FALSE) |>
    pull(component)
  
  segments$LCC <- segments$component == lcc_id
  segments$year <- y
  
  results_city[[i]] <- segments |>
    st_drop_geometry() |>
    summarise(
      total_len = sum(len),
      lcc_len = sum(len[LCC])
    ) |>
    mutate(
      connectivity = lcc_len / total_len,
      year = y
    )
  
  segments_tract <- st_intersection(
    segments |> select(LCC, year),
    tracts_m
  )
  
  segments_tract$len <- as.numeric(st_length(segments_tract))
  
  tract_year <- segments_tract |>
    st_drop_geometry() |>
    summarise(
      total_len = sum(len),
      lcc_len = sum(len[LCC]),
      .by = MUNDISSEC
    ) |>
    mutate(
      connectivity = lcc_len / total_len,
      year = y
    )
  
  results_tract[[i]] <- tract_year
  
  results_segments_map[[i]] <- segments |>
    select(year)
  
  results_lcc_map[[i]] <- segments |>
    filter(LCC) |>
    select(year)
  
  results_tract_map[[i]] <- tracts_m |>
    left_join(tract_year, by = "MUNDISSEC") |>
    mutate(year = y) |>
    select(MUNDISSEC, connectivity, year)
}

connectivity_city <- bind_rows(results_city)
connectivity_all_years <- bind_rows(results_tract)
segments_all_years <- bind_rows(results_segments_map)
lcc_all_years <- bind_rows(results_lcc_map)
tracts_all_years <- bind_rows(results_tract_map)

# one common bbox for both animations
bbox_common <- st_bbox(tracts_m)

dir.create("output", showWarnings = FALSE)
dir.create("output/lcc_frames", recursive = TRUE, showWarnings = FALSE)
dir.create("output/tract_frames", recursive = TRUE, showWarnings = FALSE)

for (y in years) {
  
  seg_y <- segments_all_years |>
    filter(year == y)
  
  lcc_y <- lcc_all_years |>
    filter(year == y)
  
  tract_y <- tracts_all_years |>
    filter(year == y)
  
  p_lcc <- ggplot() +
    geom_sf(
      data = seg_y,
      colour = "grey65",
      linewidth = 0.55,
      lineend = "round"
    ) +
    geom_sf(
      data = lcc_y,
      colour = "red",
      linewidth = 0.35,
      lineend = "round"
    ) +
    coord_sf(
      xlim = c(bbox_common["xmin"], bbox_common["xmax"]),
      ylim = c(bbox_common["ymin"], bbox_common["ymax"]),
      expand = FALSE
    ) +
    theme_void() +
    theme(
      plot.margin = margin(0, 0, 0, 0)
    ) +
    labs(title = paste("Largest connected component:", y))
  
  ggsave(
    filename = sprintf("output/lcc_frames/frame_%s.png", y),
    plot = p_lcc,
    width = 9,
    height = 7,
    dpi = 120,
    bg = "white"
  )
  
  p_tract <- ggplot(tract_y) +
    geom_sf(aes(fill = connectivity), colour = "grey85", linewidth = 0.05) +
    scale_fill_viridis_c(
      limits = c(0, 1),
      na.value = "white",
      breaks = c(0, 0.25, 0.5, 0.75, 1)
    ) +
    coord_sf(
      xlim = c(bbox_common["xmin"], bbox_common["xmax"]),
      ylim = c(bbox_common["ymin"], bbox_common["ymax"]),
      expand = FALSE
    ) +
    theme_void() +
    theme(
      plot.margin = margin(0, 0, 0, 0),
      legend.position = "right"
    ) +
    labs(
      title = paste("Cycling connectivity by census tract:", y),
      fill = "Connectivity"
    )
  
  ggsave(
    filename = sprintf("output/tract_frames/frame_%s.png", y),
    plot = p_tract,
    width = 9,
    height = 7,
    dpi = 120,
    bg = "white"
  )
}

lcc_pngs <- sort(list.files("output/lcc_frames", full.names = TRUE, pattern = "\\.png$"))
tract_pngs <- sort(list.files("output/tract_frames", full.names = TRUE, pattern = "\\.png$"))

gifski(
  png_files = lcc_pngs,
  gif_file = "output/lcc_2017_2025.gif",
  width = 900,
  height = 700,
  delay = 1
)

gifski(
  png_files = tract_pngs,
  gif_file = "output/tract_connectivity_2017_2025.gif",
  width = 900,
  height = 700,
  delay = 1
)