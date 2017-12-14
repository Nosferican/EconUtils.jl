
## Allows for determining the step size for first difference.
function gaps(obj::DataFrame,
              Step::Base.Dates.DatePeriod;
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    obj = obj[[PID, TID]]
    T = typeof(Step)
    if typeof(obj[TID]) <: AbstractCategoricalVector
        obj[TID] = get.(obj[TID])
    end
    if (T <: Dates.Day) | (T <: Dates.Week)
        output = by(obj, PID) do subdf
            if size(subdf, 1) > 1
                output = vcat(false, diff(subdf[TID]) .== Step)
            else
                output = DataFrame(x1 = false)
            end
            return output
        end
    else
        output = by(obj, PID) do subdf
            if size(subdf, 1) > 1
                output = reduce(vcat, diff(map(ym -> [12 * ym[1] + ym[2]], Dates.yearmonth.(subdf[TID]))))
                output = vcat(false, Dates.Month.(output) .== Step)
            else
                output = DataFrame(x1 = false)
            end
            return output
        end
    end
    names!(output, vcat(names(output)[1], :Valid))
    return output
end
function gaps(obj::DataFrame,
              Step::Real;
              PID::Symbol = names(obj)[1],
              TID::Symbol = names(obj)[2])
    obj = obj[[PID, TID]]
    T = typeof(Step)
    if typeof(obj[TID]) <: AbstractCategoricalVector
        obj[TID] = get.(obj[TID])
    end
    output = by(obj, PID) do subdf
        if size(subdf, 1) > 1
            output = vcat(false, diff(subdf[TID]) .== Step)
        else
            output = DataFrame(x1 = false)
        end
        return output
    end
    names!(output, vcat(names(output)[1], :Valid))
    return output
end
function frequency(obj::AbstractVector)
    if length(obj) < 2
        return -1
    end
    output = minimum(diff(obj))
    return output
end
frequency(obj::AbstractCategoricalVector) = frequency(get.(obj))
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

## Drop support for missing data
dropsupportformissing(obj::AbstractVector) = obj
dropsupportformissing(obj::AbstractVector{T}) where T <: Union = Vector{eltype(obj).b}(obj)
function dropsupportformissing(obj::AbstractCategoricalVector)
	T = eltype(obj)
	if isa(T, Union)
		T = T.b
	end
	return CategoricalVector{T}(obj)
end
function dropsupportformissing!(obj::AbstractDataFrame)
	for col ∈ eachcol(obj)
		obj[col[1]] = dropsupportformissing(col[2])
	end
	categorical!(obj, find(col -> col <: AbstractString, (eltype.(obj.columns))))
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
groups(formula::Formula, data::AbstractDataFrame) =
       groups.(interact.(StatsModels.Terms(formula).terms, data))
groups(obj::AbstractVector) = map(val -> find(equalto(val), obj), unique(obj))
interact(ex::Expr, data::AbstractDataFrame) = interact(getindex.(data, ex.args[2:end]))
interact(name::Symbol, data::AbstractDataFrame) = getindex(data, name)
function interact(obj::AbstractVector{T}) where T <: AbstractCategoricalVector
    n = length(obj[1])
    obj = groups.(obj)
    mapper = Dict{Any,Int64}()
    output = Vector{Int64}(n)
    for idx ∈ eachindex(output)
        output[idx] = get!(mapper, map(each -> findfirst(idx .∈ each), obj), length(mapper))
    end
    return output
end
