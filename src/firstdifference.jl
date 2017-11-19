
"""
	firstdifference(obj::AbstractDataFrame, PID::Symbol, TID::Symbol;
		gap::Integer = 1)

	This function returns the first-difference transformation of the dataframe.
	It uses a panel ID to perform the transformation panel wise and a temporal
	ID which is used to determine the order. The gap determines if a valid
	observation may skip time periods. The output has missing values when an
	observation is not valid. The first observation for the temporal ID is kept
	as the original value.
"""
function firstdifference(obj::DataFrames.AbstractDataFrame, PID::Symbol, TID::Symbol; gap::Integer = 1)
	varlist = DataFrames.names(obj)
	promotetoallowmissing!(obj)
	sort!(obj, cols = [PID, TID])
	categorical = setdiff(DataFrames.names(obj)[broadcast(<:, typeof.(obj.columns), CategoricalArrays.AbstractCategoricalVector)], [PID])
	todiff = obj[:, union([PID, TID], setdiff(DataFrames.names(obj), categorical))]
	todiff = DataFrames.by(todiff, PID) do subdf
		if size(subdf, 1) == 1
			output = subdf[:,2:end]
			output[:] = Missings.missing
		else
			output = subdf[:,2:end]
			for col ∈ DataFrames.eachcol(output)
				output[2:end,col[1]] = diff(col[2])
			end
			output[1,:] = Missings.missing
		end
		return output
	end
	Temporal = copy(obj[TID])
	valid = todiff[TID] .== gap
	valid[ismissing.(valid)] = false
	todiff[TID] = ifelse.(valid, Temporal, Missings.missing)
	output = hcat(todiff, obj[categorical])
	output = output[.!ismissing.(output[TID]),:]
	output = output[vcat([PID, TID], setdiff(varlist, [PID, TID]))]
	return output
end
