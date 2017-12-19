__precompile__(true)

module EconUtils
using Compat

using Missings, CategoricalArrays, DataFrames, StatsBase, StatsModels

include.((
	"utils.jl",
	"firstdifference.jl",
	"between.jl",
	"dropsingletons.jl",
	"within.jl",
	"EconFormula.jl",
	"modelframe.jl",
	"tsls.jl"
	))

end
