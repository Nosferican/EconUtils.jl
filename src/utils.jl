
## Allows for determining the step size for first difference.
function gaps(obj::DataFrames.DataFrame,
              Step::Base.Dates.DatePeriod;
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    obj = obj[[PID, TID]]
    T = typeof(Step)
    if typeof(obj[TID]) <: CategoricalArrays.AbstractCategoricalVector
        obj[TID] = get.(obj[TID])
    end
    if (T <: Dates.Day) | (T <: Dates.Week)
        output = DataFrames.by(obj, PID) do subdf
            if size(subdf, 1) > 1
                output = vcat(false, diff(subdf[TID]) .== Step)
            else
                output = DataFrames.DataFrame(x1 = false)
            end
            return output
        end
    else
        output = DataFrames.by(obj, PID) do subdf
            if size(subdf, 1) > 1
                output = reduce(vcat, diff(map(ym -> [12 * ym[1] + ym[2]], Dates.yearmonth.(subdf[TID]))))
                output = vcat(false, Dates.Month.(output) .== Step)
            else
                output = DataFrames.DataFrame(x1 = false)
            end
            return output
        end
    end
    DataFrames.names!(output, vcat(names(output)[1], :Valid))
    return output
end
function gaps(obj::DataFrames.DataFrame,
              Step::Real;
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    obj = obj[[PID, TID]]
    T = typeof(Step)
    if typeof(obj[TID]) <: CategoricalArrays.AbstractCategoricalVector
        obj[TID] = get.(obj[TID])
    end
    output = DataFrames.by(obj, PID) do subdf
        if size(subdf, 1) > 1
            output = vcat(false, diff(subdf[TID]) .== Step)
        else
            output = DataFrames.DataFrame(x1 = false)
        end
        return output
    end
    DataFrames.names!(output, vcat(names(output)[1], :Valid))
    return output
end
function frequency(obj::AbstractVector)
    if length(obj) < 2
        return -1
    end
    output = minimum(diff(obj))
    return output
end
frequency(obj::CategoricalArrays.AbstractCategoricalVector) = frequency(get.(obj))
function frequency(obj::AbstractVector{T}) where T <: Dates.Date
    if length(obj) < 2
        return -1
    end
    FirstDifference = diff(obj)
    FormalFirstDifference = Dates.canonicalize.(Dates.CompoundPeriod.(FirstDifference))
    if all(length.(getfield.(FormalFirstDifference, :periods)) .== 1)
        output = Dates.CompoundPeriod(minimum(FirstDifference))
        output = Dates.canonicalize(output)
    else
        output = diff(map(ymd -> [12 * ymd[1] + ymd[2], ymd[3]], Dates.yearmonthday.(obj)))
        if all(getindex.(output, 2) .== 0)
            output = minimum(reduce(vcat, first.(output)))
            output = Dates.canonicalize(Dates.CompoundPeriod(Dates.Month(output)))
        else
            output = Dates.CompoundPeriod(minimum(FirstDifference))
        end
    end
    return Dates.Period(first(output.periods))
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
dropsupportformissing(obj::AbstractVector) = obj
dropsupportformissing(obj::AbstractVector{T}) where T <: Union = Vector{eltype(obj).b}(obj)
function dropsupportformissing(obj::CategoricalArrays.AbstractCategoricalVector)
	T = eltype(obj)
	if isa(T, Union)
		T = T.b
	end
	return CategoricalArrays.CategoricalVector{T}(obj)
end
function dropsupportformissing!(obj::DataFrames.AbstractDataFrame)
	for col ∈ DataFrames.eachcol(obj)
		obj[col[1]] = dropsupportformissing(col[2])
	end
	DataFrames.categorical!(obj, find(col -> col <: AbstractString, (eltype.(obj.columns))))
	return
end

## Linear Independent
function linearindependent(obj::AbstractMatrix{T}) where T <: Real
    cf = cholfact!(Hermitian(obj.'obj), Val(true), tol = -one(eltype(obj)))
    r = cf.rank
    p = size(obj, 2)
    if r < p
        LI = sort!(cf.piv[1:r])
        obj = obj[:, LI]
    else
        LI = eachindex(cf.piv)
    end
    return obj, LI
end

## Make groups
makegroups(obj::AbstractVector) =
	find.(map(val -> obj .== val, unique(obj)))
makegroups(obj::DataFrames.AbstractDataFrame) = makegroups.(obj.columns)
function makegroups(formula::StatsModels.Formula, data::DataFrames.AbstractDataFrame)
    formula = StatsModels.Terms(formula.absorb).eterms[2:end]
    if isempty(formula)
        output = Vector{Vector{Vector{Int64}}}()
    else
        output = makegroups(data[formula])
    end
    return output
end
