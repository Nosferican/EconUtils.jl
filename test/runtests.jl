Pkg.rm("StatsModels")
Pkg.rm("StatsModels")
Pkg.rm("DataFrames")
Pkg.rm("DataFrames")
Pkg.rm("StatsBase")
Pkg.rm("StatsBase")
Pkg.clone("https://github.com/JuliaEconometrics/StatsBase.jl")
Pkg.clone("https://github.com/JuliaEconometrics/DataFrames.jl")
Pkg.clone("https://github.com/JuliaEconometrics/StatsModels.jl")

using EconUtils
using Test
using DataFrames

df = DataFrames(x = 1:5)

# write your own tests here
@test df == DataFrames(x = 1:5)
