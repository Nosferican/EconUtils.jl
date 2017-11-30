
"""
	fixedeffects(obj::AbstractDataFrame)

	This functions takes a dataframe with the fixed effects and returns a list
	of dimensions with a list of fixed effects (observation identifiers). It
	also returns a list of singletons to drop from the model matrix and response
	vector. After dropping the singletons from the model matrix, one can use
	pass the fixedeffects to the within transformation.
"""
function fixedeffects(obj::AbstractDataFrame)
	Groups = groups(obj)
	(m, singletons) = dropsingletons!(Groups)
	remapper = makeremapper(m, singletons)
	remapping!(Groups, remapper)
	output = Groups, singletons
	return output
end

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
