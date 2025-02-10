
### Built From Source

- 2025-01-27  noble: mirt 
- 2025-01-30  noble,jammy,focal: MiscMetabar
- 2025-01-31  noble,jammy,focal: BCDAG
- 2025-02-01  noble,jammy,focal: BIEN
- 2025-02-03  noble: ProbBreed
- 2025-02-05  noble,jammy,focal: netmeta; focal: FIESTA, QuadratiK, ssif
- 2025-02-06  noble,jammy,focal: ClassComparison; noble: EpiNow2, rstanemacs
- 2025-02-07  noble,jammy,focal: convertid,Coxmox
- 2025-02-08  noble,jammy,focal: CIDER, MIC, pencal; only noble: paws.common, rayrender, vol2birdR; only focal: rayrender
- 2025-02-08  noble,jammy,focal: tidyHeatmap; only focal: paws.analytics
- 2025-02-10  NONE!!

### 2025-01-27

- focal: curl busted, error on loading that symbol 'curl_url_strerror' does
  not resolve; fixed by recompiling (with -s .2) 'curl' from source
  affected packages baRulho locuszoomr which updated today
  (discussed with Jeroen a day later, maybe they fixed binary by then)

# OLD below

## jammy builds

- sp: The upstream package r-cran-sp has an epoch in its version number blocking
  pinning so a one-off build with an epoch added to this version was made
  
- gastemp: The suggested package rstantools appears to be a build dependency
  so as a one-off it was added
