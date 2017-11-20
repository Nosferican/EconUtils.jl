
## On Dates
Dates.Year(::Missings.Missing) = Missings.missing
Dates.Month(::Missings.Missing) = Missings.missing
Dates.Week(::Missings.Missing) = Missings.missing
Dates.Day(::Missings.Missing) = Missings.missing

## Allows for determining the step size for first difference.
function Base.step(obj::DataFrames.DataFrame;
                   PID::Symbol = names(obj)[1],
                   TID::Symbol = names(obj)[2])
    if typeof(obj[TID]) <: CategoricalArrays.AbstractCategoricalVector
        if eltype(get.(obj[TID])) <: Date
            Step = DataFrames.by(obj[[PID, TID]], PID) do subdf
                return DataFrames.DataFrame(step = step(get.(subdf[TID])))
            end
        else
            Step = DataFrames.by(obj[[PID, TID]], PID) do subdf
                return DataFrames.DataFrame(step = diff(get.(subdf[TID])))
            end
        end
    else
        Step = DataFrames.by(obj[[PID, TID]], PID) do subdf
            return DataFrames.DataFrame(step = diff(subdf[TID]))
        end
    end
    output = minimum(Step[:step])
    return output
end
function gaps(obj::DataFrames.DataFrame,
              Step::Union{Dates.Year,Dates.Month};
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    output = DataFrames.by(obj[[PID, TID]], PID) do subdf
        output = Dates.CompoundPeriod.(Dates.Year.(diff(Dates.year.(obj))) .+
                                       Dates.Month.(diff(Dates.month.(obj))) .+ Dates.Day.(diff(Dates.day.(obj))))
        output = vcat(false, first.(getfield.(output, :periods)) .== Step)
        return output
    end
    return output[:,2]
end
function gaps(obj::DataFrames.DataFrame,
              Step::Dates.Week;
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    obj = obj[[PID, TID]]
    if typeof(obj[TID]) <: CategoricalArrays.AbstractCategoricalVector
        obj[TID] = get.(obj[TID])
    end
    output = DataFrames.by(obj[[PID, TID]], PID) do subdf
        output = getfield.(diff(getfield.(subdf[TID], :instant)), :value)
        output = vcat(false, Dates.Week.(output ./ 7) .== Step)
        return output
    end
    return output[:,2]
end
function gaps(obj::DataFrames.DataFrame,
              Step::Dates.Day;
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    obj = obj[[PID, TID]]
    if typeof(obj[TID]) <: CategoricalArrays.AbstractCategoricalVector
        obj[TID] = get.(obj[TID])
    end
    output = DataFrames.by(obj[[PID, TID]], PID) do subdf
        output = vcat(Missings.missing,
                      getfield.(diff(getfield.(subdf[TID], :instant)), :value))
        output = vcat(false, Dates.Day.(output) .== Step)
        return output
    end
    return output[:,2]
end
function Base.step(obj::AbstractVector{T}) where T <: Base.Dates.Date
    hopeful = Dates.CompoundPeriod.(Dates.Year.(diff(Dates.year.(obj))) .+ Dates.Month.(diff(Dates.month.(obj))) .+ Dates.Day.(diff(Dates.day.(obj))))
    if all(length.(getfield.(hopeful, :periods)) .== 1)
        output = minimum(first.(getfield.(hopeful, :periods)))
    else
        hopeful = getfield.(diff(getfield.(obj, :instant)), :value)
        if all(hopeful .% 7 .== 0)
            output = Dates.Week(minimum(hopeful) / 7)
        else
            output = Dates.Day(minimum(hopeful))
        end
    end
    return output
end
function Base.step(obj::AbstractVector{T}) where T <: Real
    output = filter(elem -> elem ≥ 0, diff(obj))
    if !isempty(output)
        output = first(output)
    else
        output = 0
    end
    return output
end
## Makes all columns compatible with missing data
function promotetoallowmissing(obj::AbstractVector)
	TypeOf = eltype(obj)
	if isa(TypeOf, Union)
		TypeOf = TypeOf.b
	end
	return Vector{Union{Missings.Missing,TypeOf}}(obj)
end
function promotetoallowmissing(obj::CategoricalArrays.CategoricalVector)
	T = eltype(obj)
	if isa(T, Union)
		T = T.b
	end
	return CategoricalArrays.CategoricalVector{Union{Missings.Missing,T}}(obj)
end
function promotetoallowmissing!(obj::DataFrames.AbstractDataFrame)
	for col ∈ DataFrames.eachcol(obj)
		obj[col[1]] = promotetoallowmissing(col[2])
	end
	DataFrames.categorical!(obj, find(col -> col <: AbstractString, getfield.(eltype.(obj.columns), :b)))
	return
end

## Drop support for missing data
function dropsupportformissing(obj::AbstractVector)
	T = eltype(obj)
	if isa(T, Union)
		T = T.b
	end
	return Vector{T}(obj)
end
function dropsupportformissing!(obj::DataFrames.AbstractDataFrame)
	for col ∈ DataFrames.eachcol(obj)
		obj[col[1]] = dropsupportformissing(col[2])
	end
	DataFrames.categorical!(obj, find(col -> col <: AbstractString, (eltype.(obj.columns))))
	return
end
