# Barcelona Cycling Network Connectivity (LCC)


This repository computes a **cycling network connectivity indicator**
for Barcelona based on the **Largest Connected Component (LCC)** of the
cycling infrastructure network.

The indicator measures the **proportion of the cycling network that
belongs to the main connected component**, capturing the degree of
**network fragmentation**.

Cycling infrastructure data come from **BCN Open Data**.

# Indicator

Connectivity is defined as:

$$
Connectivity = \frac{\text{Length of cycling network in the largest connected component}}{\text{Total cycling network length}}
$$

Interpretation:

| Value   | Meaning                   |
|:--------|:--------------------------|
| ~1      | Highly connected network  |
| 0.6-0.8 | Moderate fragmentation    |
| \<0.5   | Highly fragmented network |

This indicator reflects the **continuity of the cycling network**, not
just the total amount of infrastructure.

# Data

Cycling infrastructure data are obtained from **BCN Open Data**.

Dataset: **Carrils bici de Barcelona**

The dataset represents the official cycling infrastructure network
maintained by the City of Barcelona.

# Workflow

1.  Load cycling infrastructure data
2.  Clean and prepare the network
3.  Convert the network to a graph
4.  Identify connected components
5.  Compute total network length
6.  Compute length of the largest connected component
7.  Calculate the connectivity indicator

# Repository structure

\`\`\`text . ├── data/ │ └── cycling_network_raw.gpkg ├── scripts/ │ ├──
01_load_data.R │ ├── 02_prepare_network.R │ └── 03_compute_lcc.R ├──
outputs/ │ ├── connectivity_indicator.csv │ └── lcc_map.gpkg └──
README.Rmd
