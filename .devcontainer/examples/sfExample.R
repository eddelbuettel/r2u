options(bspm.version.check=FALSE)  # small speedup
install.packages(c("sf", "ggplot2"))

suppressMessages({
    library(sf)
    library(ggplot2)
})

# Use the North Carolina shapefile that comes bundled with sf
nc_loc <- system.file("shape/nc.shp", package="sf")
## Read the shapefile into R
nc <- st_read(nc_loc, quiet = TRUE)
nc

ggplot(nc) +
    geom_sf(aes(fill = AREA), alpha = 0.8, col = "white") +
    scale_fill_viridis_c(name = "Area") +
    ggtitle("Counties of North Carolina") +
    theme_minimal()
