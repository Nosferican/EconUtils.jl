
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
function firstdifference(obj::AbstractDataFrame,
						 PID::Symbol,
						 TID::Symbol)
	varlist = names(obj)
	obj = copy(obj)
	allowmissing!(obj)
	sort!(obj, cols = [PID, TID])
	categorical!(obj)
	Step = by(obj, PID) do subdf
        frequency(subdf[TID])
    end
	Step = filter(elem -> elem ≥ zero(typeof(elem)), Step[:x1])
	@assert !isempty(Step) "No positive step."
	Step = minimum(Step)
	Gaps = gaps(obj, Step, PID = PID, TID = TID)
	Gaps = Gaps[:Valid]
	categorical = setdiff(names(obj)[broadcast(<:,
						typeof.(obj.columns),
						AbstractCategoricalVector)],
						[PID, TID])
	todiff = obj[:, union([PID],
					setdiff(names(obj), union([TID], categorical)))]
	todiff = by(todiff, PID) do subdf
		if size(subdf, 1) == 1
			output = subdf[:,2:end]
		else
			output = subdf[:,2:end]
			for (name, col) ∈ eachcol(output)
				output[:,name] = vcat(missing, diff(col))
			end
		end
		return output
	end
	output = hcat(obj[[PID, TID]], todiff, obj[categorical])
	output = output[Gaps,varlist]
	return output
end
