
"""
	EconFormula(formula::StatsModels.Formula)

	EconFormula is a struct which is composed of various formulas used in
	the construction of a regression model for econometrics.

	It parses a formula with the following syntax:
		response ~ exogenous + (endogenous ~ instruments) ~ absorb

	Returns a struct which holds
		representation::String
		exogenous::StatsModels.Formula
		endogenous::StatsModels.Formula
		instruments::StatsModels.Formula
		absorb::StatsModels.Formula
		clusters::StatsModels.Formula
"""
struct EconFormula
	representation::String
	exogenous::StatsModels.Formula
	endogenous::StatsModels.Formula
	instruments::StatsModels.Formula
	absorb::StatsModels.Formula
	clusters::StatsModels.Formula
	function EconFormula(formula::StatsModels.Formula)
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
function formulaparser(formula::StatsModels.Formula)
	formula = copy(formula)
	Representation = copy(formula)
	response = formula.lhs
	formula = formula.rhs
	if isa(formula, Symbol)
		Representation = string(formula)
		Exogenous = StatsModels.Formula(response, exogenous)
		Endogenous = StatsModels.Formula(response, 0)
		Instruments = StatsModels.Formula(response, 0)
		Absorb = StatsModels.Formula(response, 0)
		Cluster = StatsModels.Formula(response, 0)
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
		if formula.args[1] == :(+)
			Exogenous = StatsModels.Formula(response, formula.args[2])
		else
			Exogenous = StatsModels.Formula(response, formula)
		end
		filter!(elem -> elem != nothing, EndoInst)
		filter!(elem -> elem != nothing, Absorb)
		filter!(elem -> elem != nothing, Cluster)
		if isempty(EndoInst)
			Endogenous = StatsModels.Formula(response, 0)
			Instruments = StatsModels.Formula(response, 0)
		else
			EndoInst = EndoInst[1]
			Endogenous = StatsModels.Formula(response, EndoInst[1])
			Instruments = StatsModels.Formula(response, EndoInst[2])
		end
		if isempty(Absorb)
			Absorb = StatsModels.Formula(response, 0)
		else
			Absorb = StatsModels.Formula(response, Absorb[1])
		end
		if isempty(Cluster)
			Cluster = StatsModels.Formula(response, 0)
		else
			Cluster = StatsModels.Formula(response, Cluster[1])
		end
	end
	return (Representation, Exogenous, Endogenous, Instruments, Absorb, Cluster)
end
