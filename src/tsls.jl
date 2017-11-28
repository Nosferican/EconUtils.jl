
"""
	tsls(exogenous::AbstractMatrix, instruments::AbstractMatrix,
		endogenous::AbstractMatrix)

	This functions creates the model matrix for 2SLS using a matrix of exogenous
	variables, additional instruments, and the endogenous variables. It verifies
	that the equation is identifiable (enough instruments). It returns the
	linearly independent version of the model matrix, the Gram matrix of it,
	and an indicator of which variables were linearly independent (which were
	not dropped).
"""
function tsls(exogenous::AbstractMatrix, instruments::AbstractMatrix, endogenous::AbstractMatrix)
	n_exogenous = size(exogenous, 2)
	n_endogenous = size(endogenous, 2)
	instrumented = hcat(exogenous, instruments)
	instrumented, LI = linearindependent(instrumented)
	@assert size(instrumented, 2) ≥ (n_exogenous + n_endogenous) "Not sufficient instruments."
	mm = hcat(exogenous, instrumented * inv(cholfact!(Hermitian(instrumented.'instrumented))) * instrumented.'endogenous)
	mm, LI = linearindependent(mm)
	return mm, Hermitian(mm.'mm), LI
end
