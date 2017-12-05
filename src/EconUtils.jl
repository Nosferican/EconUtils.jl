__precompile__(true)

module EconUtils

using Missings, CategoricalArrays, DataFrames, StatsModels
using StatsBase: coefnames, model_response, indexmap
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
