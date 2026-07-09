#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>
#include <stdio.h>

extern SEXP package_dependencies_scan(SEXP x);

static const R_CallMethodDef CallEntries[] = {
    {"package_dependencies_scan", (DL_FUNC) &package_dependencies_scan, 1},
    {NULL, NULL, 0}
};

void R_init_r2u(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
