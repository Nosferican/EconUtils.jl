
"""
	between(obj::DataFrames.AbstractDataFrame, variable::Symbol)

	This function returns the between transformation of the dataframe.
	It uses a variable to perform the transformation. Categorical variables
	that have two values are aggregated by the mean taking the last level
	as `true`. Categorical variables a different number of levels are
	suppressed.
"""
function between(obj::DataFrames.AbstractDataFrame, variable::Symbol)
	output = DataFrames.dropmissing(obj)
	dropsupportformissing!(output)
	categorical = setdiff(DataFrames.names(output)[broadcast(<:, typeof.(output.columns), CategoricalArrays.AbstractCategoricalVector)], [variable])
	output = output[:, setdiff(DataFrames.names(output), filter(idx -> length(CategoricalArrays.levels(output[idx])) != 2, categorical))]
	varlist = DataFrames.names(output)
	output = DataFrames.aggregate(output, variable, between)
	DataFrames.names!(output, varlist)
	return output
end
between(obj::AbstractVector) = mean(obj)
between(obj::CategoricalArrays.AbstractCategoricalVector) =
	mean(obj .== CategoricalArrays.levels(obj)[2])
function between(obj::DataFrames.AbstractDataFrame)
	output = obj[1,2:end]
	for idx ∈ names(obj)[2:end]
		output[idx] = between(obj[idx])
	end
	return output
end
