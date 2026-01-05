#COMPACT VERSION OF L1_EX2.jl
using JuMP
using  HiGHS
m = Model(HiGHS.Optimizer)

#data & indexes, y=production, x=storage
months = 1:12
d = [15, 30, 25, 55, 75, 115, 190, 210, 105, 65, 20, 20]  # demand per month (L)
storage_cost = 1.0  # €/L/month

#variables
@variable(m, 0 <= Y[n in months] <= 120)   # production
@variable(m, 0 <= X[n in months] <= 200)   # end-of-month storage

#objective
@objective(m, Min, sum(storage_cost * X[n] for n in months))

#constraints
@constraint(m, balance[n in months], X[n] == (n > 1 ? X[n-1] : 0) + Y[n] - d[n])  # initial storage is zero

# optimize
optimize!(m)    
println("\n===== RESULTS =====")
println("Objective value: ", objective_value(m))
println("-------------------")
for n in months
    println("Month ", n, ": Production = ", round(value(Y[n]), digits=6),
            ", End-of-month storage = ", round(value(X[n]), digits=6))
end
