
## This file is based on (closely follows) the vignette
## 'https://chanzuckerberg.github.io/cellxgene-census/r/articles/comp_bio_data_integration.html'
## and uses packages `tiledb`, `tiledbsoma` and `cellxgene.census` to access Census data
##
## Please consult with the original vignette (and the cellxgene.census package) for details.
##
## Note that the code here must be run in the 8gb ram instance of codespaces

if (!requireNamespace("Seurat", quietly = TRUE)) install.packages("Seurat")

if (!requireNamespace("cellxgene.census", quietly = TRUE)) {
    # if cellxgene.census is not installed yet, install it along with tiledb* packages
    options(bspm.version.check=FALSE)  # prefer binaries
    pkgs <- c("tiledbsoma", "cellxgene.census")
    repos <- c("https://chanzuckerberg.r-universe.dev/bin/linux/jammy/4.3",
               "https://cloud.r-project.org")
    install.packages(pkgs, repos=repos)
}

## load packages
suppressMessages({
    library(cellxgene.census)  # also loads tiledb, tiledbsoma and more
    library(Seurat)            # also loads patchwork and more
})

## Open the Census and query for Tabula Muris Senis data from the liver
census <- cellxgene.census::open_soma()

census_datasets <- census$get("census_info")$get("datasets")
census_datasets <- census_datasets$read(value_filter = "collection_name == 'Tabula Muris Senis'")
census_datasets <- as.data.frame(census_datasets$concat())

## Print rows with liver data
census_datasets[grep("Liver", census_datasets$dataset_title), ]

## Select ids 
tabula_muris_liver_ids <- c("4546e757-34d0-4d17-be06-538318925fcd", "6202a243-b713-4e12-9ced-c387f8483dea")
## Query for a Seurat object with the selected cells
## Important: This *will fail* on the default 4gb instance, select the larger instance and it will work
seurat_obj <- cellxgene.census::get_seurat(census, organism = "Mus musculus", obs_value_filter = "dataset_id %in% tabula_muris_liver_ids")

## Tabulate assay to show cell count
table(seurat_obj$assay)

## Normalize gene length by assay and merge back in
smart_seq_gene_lengths <- seurat_obj[["RNA"]]@meta.features$feature_length
seurat_obj.list <- SplitObject(seurat_obj, split.by = "assay")
seurat_obj.list[["Smart-seq2"]][["RNA"]]@counts <- seurat_obj.list[["Smart-seq2"]][["RNA"]]@counts / smart_seq_gene_lengths
seurat_obj <- merge(seurat_obj.list[[1]], seurat_obj.list[[2]])

## Use Seurat:  data normalization and variable gene selection
seurat_obj <- SCTransform(seurat_obj)
seurat_obj <- FindVariableFeatures(seurat_obj, selection.method = "vst", nfeatures = 2000)

## Perform PCA and UMAP
seurat_obj <- RunPCA(seurat_obj, features = VariableFeatures(object = seurat_obj))
seurat_obj <- RunUMAP(seurat_obj, dims = 1:10)

## Plot by assay and cell type
p1 <- DimPlot(seurat_obj, reduction = "umap", group.by = "assay")
p2 <- DimPlot(seurat_obj, reduction = "umap", group.by = "cell_type")
## And show them side by side
p1 + p2
