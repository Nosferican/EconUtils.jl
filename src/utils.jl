
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
