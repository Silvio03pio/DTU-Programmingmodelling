using JuMP, Gurobi

EX = Model(Gurobi.Optimizer)
set_silent(EX)


# Assicurati che F, D, DayVisitCost, FamilySize siano definiti e coerenti:
# F = 1:1000 
# D = 1:20
# DayVisitCost è nF x nD, FamilySize è lungo nF

@variable(EX, y[f in F, d in D], Bin)

@objective(EX, Min, sum(DayVisitCost[f,d] * y[f,d] for f in F, d in D))

@constraint(EX, assign_once[f in F], sum(y[f,d] for d in D) == 1)

@constraint(EX, day_capacity[d in D],
    125 <= sum(FamilySize[f] * y[f,d] for f in F) <= 300
)

optimize!(EX)

println("Objective value: ", objective_value(EX))
println("Primal status: ", primal_status(EX))
println("Termination status: ", termination_status(EX))
