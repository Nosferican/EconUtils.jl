
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
function firstdifference(obj::DataFrames.AbstractDataFrame,
						 PID::Symbol,
						 TID::Symbol)
	varlist = DataFrames.names(obj)
	obj = copy(obj)
	promotetoallowmissing!(obj)
	sort!(obj, cols = [PID, TID])
	DataFrames.categorical!(obj)
	Step = step(obj, PID = PID, TID = TID)
	categorical = setdiff(DataFrames.names(obj)[broadcast(<:,
						typeof.(obj.columns),
						CategoricalArrays.AbstractCategoricalVector)],
						[PID, TID])
	todiff = obj[:, union([PID],
					setdiff(DataFrames.names(obj), union([TID], categorical)))]
	todiff = DataFrames.by(todiff, PID) do subdf
		if size(subdf, 1) == 1
			output = DataFrames.DataFrame()
		else
			output = subdf[:,2:end]
			for col ∈ DataFrames.eachcol(output)
				output[:,col[1]] = vcat(Missings.missing, diff(col[2]))
			end
		end
		return output
	end
	output = hcat(obj[[PID, TID]], todiff, obj[categorical])
	output = output[gaps(obj, Step, PID = PID, TID = TID),:]
	output = output[varlist]
	return output
end
