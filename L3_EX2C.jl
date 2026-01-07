# startup fund
using JuMP
using HiGHS

EX = Model(HiGHS.Optimizer)
set_silent(EX)

#Data & indexes
J = 1:9
c = [ 29, 35, 24, 52, 53, 41, 43, 68, 28] #profit
a = [17, 25, 19, 25, 28, 23, 29, 31, 18]   #cost
budget = 100

#variables
@variable(EX, x[j in J], Bin) #invece di metterla come integer la metto come continua cosi poss ottenere risultati frazionari


#FO 
@objective(EX, Max, sum(x[j]*c[j] for j in J))

#constraint
@constraint(EX, maximum_capacity[1:1], sum(x[j]*a[j] for j in J) <= budget)
#@constraint(EX, x[1] + x[5] <= 1)
#@constraint(EX, x[6] <= x[2] + x[3])
#@constraint(EX, x[9] <= x[2] + x[3])


# optimize
optimize!(EX)    
println("\n===== RESULTS =====")
println("Objective value: ", objective_value(EX))
println("Primal status: ", primal_status(EX))