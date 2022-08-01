## Start from r2u under Ubuntu 22.04 'jammy'
FROM eddelbuettel/r2u:22.04

## Use the DESCRIPTION file in current directory (or adjust)
COPY DESCRIPTION /tmp

## use 'dependencies=TRUE' argument to add Suggests
RUN install.r remotes && Rscript -e 'remotes::install_deps("/tmp")'
