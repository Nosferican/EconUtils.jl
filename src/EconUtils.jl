__precompile__(true)

module EconUtils

import Missings
import CategoricalArrays
import DataFrames
import StatsBase
import StatsModels

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
