# Getting Started

## Installation

During the Beta test stage the package can be installed using:
```julia
Pkg.clone("https://github.com/JuliaEconometrics/EconUtils.jl.git")
```

Once it is released you it may be installed using:
```julia
Pkg.add("EconUtils")
```

Once installed it can be loaded using as any other Julian package
```julia
using EconUtils
```

## A Dataset

This package assumes tabular data which is enabled in Julia through the `DataFrames` package. For example

```@example Tutorial
using DataFrames
using RDatasets # Not required for actual usage, but it provides some data sets
df = dataset("plm", "Crime") # Loads the Crime data set from the R {plm} package
pool!(df, [:Region, :SMSA]) # String variables must be coded as categorical
```
