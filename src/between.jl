
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
    DataFrames.categorical!(output)
    output = output[union([variable], names(output))]
    sort!(output, cols = [variable])
    varlist = names(output)
    output = DataFrames.by(output, variable) do subdf
        DataFrames.DataFrame(DataFrames.colwise(between, subdf[:,2:end]))
    end
    DataFrames.names!(output, varlist)
    incompatible = Vector{Symbol}()
    for name ∈ names(output[:,2:end])
        if typeof(obj[name]) <: CategoricalArrays.AbstractCategoricalVector
            lvls = CategoricalArrays.levels(obj[name])
            if (length(lvls) == 2) & (sort(unique(output[name])) == (0,1))
                output[name] = ifelse.(output[name] .== 0, first(lvls), last(lvls))
            elseif length(lvls) > 2
                if all(output[name] .== true)
                    output[name] = obj[collect(values(sort(StatsBase.indexmap(obj[variable])))), name]
                else
                    push!(incompatible, name)
                end
            end
        elseif eltype(obj[name]) <: Dates.TimeType
            if all(output[name] .== true)
                output[name] = obj[collect(values(sort(StatsBase.indexmap(obj[variable])))), name]
            else
                push!(incompatible, name)
            end
        end
    end
    output = output[setdiff(names(output), incompatible)]
	return output
end
between(obj::AbstractVector) = mean(obj)
between(obj::AbstractVector{T}) where T <: Dates.TimeType = length(unique(obj)) == 1
function between(obj::CategoricalArrays.AbstractCategoricalVector)
    lvls = CategoricalArrays.levels(obj)
    if length(lvls) == 1
        output = first(lvls)
    elseif length(lvls) == 2
        output = mean(obj .== last(lvls))
    else
        output = length(unique(obj)) == 1
    end
    return output
end
