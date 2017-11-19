
"""
	fixedeffects(obj::DataFrames.AbstractDataFrame)

	This functions takes a dataframe with the fixed effects and returns a list
	of dimensions with a list of fixed effects (observation identifiers). It
	also returns a list of singletons to drop from the model matrix and response
	vector. After dropping the singletons from the model matrix, one can use
	pass the fixedeffects to the within transformation.
"""
function fixedeffects(obj::DataFrames.AbstractDataFrame)
	groups = makegroups(obj)
	(m, singletons) = dropsingletons!(groups)
	remapper = makeremapper(m, singletons)
	remapping!(groups, remapper)
	output = groups, singletons
	return output
end

makegroups(obj::AbstractVector) =
	find.(map(val -> obj .== val, unique(obj)))
makegroups(obj::DataFrames.AbstractDataFrame) = makegroups.(obj.columns)
idsingletons(obj::AbstractVector) = filter(elem -> length(elem) == 1, obj)
idsingletons(obj::AbstractVector{T}) where T <: AbstractVector = first.(filter(elem -> length(elem) == 1, obj))
function dropsingletons!(obj::Vector{Vector{Vector{Int64}}})
	todrop = Vector{Int64}()
	m = sum(length.(first(obj)))
	while true
		tmp = reduce(union, idsingletons.(obj))
		if isempty(tmp)
			return m, todrop
		else
			for dimension ∈ obj
				for fixedeffect ∈ dimension
					filter!(elem -> elem ∉ tmp, fixedeffect)
				end
				filter!(!isempty, dimension)
			end
			append!(todrop, tmp)
		end
	end
end
function remapping!(obj::Vector{Vector{Vector{Int64}}},
	remapper::Dict{Int64,Int64})
	for dimension ∈ obj
		for fixedeffect ∈ dimension
			fixedeffect[:] = get.(remapper, fixedeffect, 0)
		end
	end
end
function makeremapper(m::Integer, singletons::Vector{Int64})
	mapper = Int.(hcat(setdiff(1:m, singletons), 1:(m - length(singletons))))
	output = Dict{Int64,Int64}()
	for i ∈ 1:size(mapper,1)
		output[mapper[i,1]] = mapper[i,2]
	end
	return output
end
