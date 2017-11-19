
"""
	modelframe(formula::EconFormula, data::DataFrames.AbstractDataFrame)

	This formula is akin to ModelFrame for Formula, but rather than being a
	struct it returns
		data::DataFrame
		varlist::Vector{String}
		response::Vector{T}
		exogenous::Matrix{T}
		endogenous::Matrix{T}
		instruments::Matrix{T}
		absorb::Vector{Vector{Vector{Int64}}}
		clusters::Vector{Vector{Vector{Int64}}}
"""
function modelframe(formula::EconFormula,
	data::DataFrames.AbstractDataFrame; contrasts::Dict = Dict())
	response = formula.exogenous.lhs
	exogenous = StatsModels.Terms(formula.exogenous)
	endogenous = StatsModels.Terms(formula.endogenous)
	instruments = StatsModels.Terms(formula.instruments)
	vars = Symbol.(reduce(union, getfield.((exogenous, endogenous, instruments), :eterms)))
	df = data[vars]
	DataFrames.dropmissing!(df)
	mf = StatsModels.ModelFrame(exogenous, df, contrasts = contrasts)
	y = Vector{Float64}(mf.df[response])
	varlist = StatsBase.coefnames(mf)
	X = StatsModels.ModelMatrix(mf).m
	if length(endogenous.eterms) > 1
		mf = StatsModels.ModelFrame(endogenous, df)
		append!(varlist, StatsBase.coefnames(mf)[2:end])
		mm = StatsModels.ModelMatrix(mf)
		if unique(mm.assign) ≠ mm.assign
			@assert false "Endogenous variables must not be categorical variables with more than two levels."
		end
		z = mm.m[:,2:end]
		mf = StatsModels.ModelFrame(instruments, df)
		Z = StatsModels.ModelMatrix(mf).m[:,2:end]
	else
		z = zeros(length(y),0)
		Z = zeros(length(y),0)
	end
	D = Vector{Vector{Vector{Int64}}}()
	G = Vector{Vector{Vector{Int64}}}()
	return df, varlist, y, X, z, Z, D, G
end
