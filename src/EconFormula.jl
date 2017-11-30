
"""
	EconFormula(formula::Formula)

	EconFormula is a struct which is composed of various formulas used in
	the construction of a regression model for econometrics.

	It parses a formula with the following syntax:
		response ~ exogenous + (endogenous ~ instruments) ~ absorb

	Returns a struct which holds
		representation::String
		exogenous::Formula
		endogenous::Formula
		instruments::Formula
		absorb::Formula
		clusters::Formula
"""
struct EconFormula
	representation::String
	exogenous::Formula
	endogenous::Formula
	instruments::Formula
	absorb::Formula
	clusters::Formula
	function EconFormula(formula::Formula)
		Representation, Exogenous, Endogenous, Instruments, Absorb, Cluster = formulaparser(formula)
		new(Representation, Exogenous, Endogenous, Instruments, Absorb, Cluster)
	end
end
endoinst(obj::Any) = nothing
function endoinst(obj::Expr)
	if (obj.head == :call) & (obj.args[1] == :(~))
		return (obj.args[2], obj.args[3])
	end
end
absorb(obj::Any) = nothing
function absorb(obj::Expr)
	if (obj.head == :(=)) & (obj.args[1] == :absorb)
		return obj.args[2]
	end
end
cluster(obj::Any) = nothing
function cluster(obj::Expr)
	if (obj.head == :(=)) & (obj.args[1] == :cluster)
		return obj.args[2]
	end
end
function formulaparser(formula::Formula)
	formula = copy(formula)
	Representation = copy(formula)
	response = formula.lhs
	formula = formula.rhs
	if isa(formula, Symbol)
		Representation = string(formula)
		Exogenous = Formula(response, exogenous)
		Endogenous = Formula(response, 0)
		Instruments = Formula(response, 0)
		Absorb = Formula(response, 0)
		Cluster = Formula(response, 0)
	else
		EndoInst = endoinst.(formula.args)
		Absorb = absorb.(formula.args)
		Cluster = cluster.(formula.args)
		Representation.rhs.args =
			Representation.rhs.args[(EndoInst .== nothing) .&
			(Absorb .== nothing)]
		Representation = string(Representation)
		formula.args = formula.args[(EndoInst .== nothing) .&
			(Absorb .== nothing) .& (EndoInst .== nothing)]
		if (formula.args[1] == :(+)) & (length(formula.args) == 2)
			Exogenous = Formula(response, formula.args[2])
		else
			Exogenous = Formula(response, formula)
		end
		filter!(elem -> elem != nothing, EndoInst)
		filter!(elem -> elem != nothing, Absorb)
		filter!(elem -> elem != nothing, Cluster)
		if isempty(EndoInst)
			Endogenous = Formula(response, 0)
			Instruments = Formula(response, 0)
		else
			EndoInst = EndoInst[1]
			Endogenous = Formula(response, EndoInst[1])
			Instruments = Formula(response, EndoInst[2])
		end
		if isempty(Absorb)
			Absorb = Formula(response, 0)
		else
			Absorb = Formula(response, Absorb[1])
		end
		if isempty(Cluster)
			Cluster = Formula(response, 0)
		else
			Cluster = Formula(response, Cluster[1])
		end
	end
	return (Representation, Exogenous, Endogenous, Instruments, Absorb, Cluster)
end
