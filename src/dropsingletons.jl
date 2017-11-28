
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
