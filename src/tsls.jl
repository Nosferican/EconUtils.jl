
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
	R = qrfact(instrumented)[:R]
	LI = abs.(diag(R)) .> sqrt(eps())
	if any(LI)
		instrumented = instrumented[:,LI]
		for col ∈ sort(find(.!LinearIndependent), rev = true)
			R = QRupdate.qrdelcol(R, col)
		end
	end
	@assert size(instrumented, 2) ≥ (n_exogenous + n_endogenous) "Not sufficient instruments."
	mm = hcat(exogenous, instrumented * inv(cholfact!(R.'R)) * instrumented.'endogenous)
	R = qrfact(mm)[:R]
	LI = abs.(diag(R)) .> sqrt(eps())
	if any(LI)
		mm = mm[:,LI]
		for col ∈ sort(find(.!LinearIndependent), rev = true)
			R = QRupdate.qrdelcol(R, col)
		end
	end
	A = R.'R
	return mm, A, LI
end
