
"""
	within(obj::AbstractMatrix, groups::Vector{Vector{Vector{Int64}}})

	This function performs the within transformation given a model matrix and
	fixed effects using the method of alternating projections.
"""
function within(obj::AbstractMatrix, D::Vector{Vector{Vector{Int64}}})
	output = mapslices(col -> within(col, D), obj, 1)
	return output
end
function within(obj::AbstractVector, D::Vector{Vector{Vector{Int64}}})
	μ = mean(obj)
	current = copy(obj)
	output = copy(obj)
	er = Inf
	while er > 1e-8
		for dimension ∈ D
			current = copy(output)
			for group ∈ dimension
				output[group] .-= mean(current[group])
			end
		end
		er = norm(output - current)
	end
	output .+= μ
	return output
end
