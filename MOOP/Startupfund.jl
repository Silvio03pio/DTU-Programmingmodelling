# MOOP startup fund Assignement 1.1
using JuMP
using Gurobi
using MultiObjectiveAlgorithms

EX = Model()

#Data & indexes
J = 1:9
c = [ 29, 35, 24, 52, 53, 41, 43, 68, 28] #profit
a = [17, 25, 19, 25, 28, 23, 29, 31, 18]   #cost
budget = 100
SDG = [8, 6, 8, 3, 4, 5, 3, 2, 7]

#variables
@variable(EX, x[j in J], Bin) #invece di metterla come integer la metto come continua cosi poss ottenere risultati frazionari

# 1 Objective: maximize profit
@expression(EX, profit, sum(x[j]*c[j] for j in J))

# 2 Objective: maximize SDG
@expression(EX, SDG, sum(x[j]*SDG[j] for j in J))

#Define combined BI-Objective
@objective(EX, Max, [profit, SDG])

#constraint
@constraint(EX, maximum_capacity[1:1], sum(x[j]*a[j] for j in J) <= budget)
#@constraint(EX, x[1] + x[5] <= 1)
#@constraint(EX, x[6] <= x[2] + x[3])
#@constraint(EX, x[9] <= x[2] + x[3])


#************************************************************************
# Solve
# Set MIP solver
set_optimizer(EX, ()->MultiObjectiveAlgorithms.Optimizer(Gurobi.Optimizer))
set_silent(EX)
# Set MO solver
set_attribute(EX, MultiObjectiveAlgorithms.Algorithm(),
MultiObjectiveAlgorithms.EpsilonConstraint())
optimize!(EX)
#solution_summary(EX)
#********************************************************************


#************************************************************************
# Solution
if result_count(EX)>=1
println("No Pareto optimal points: ",result_count(EX))
for j in 1:result_count(EX)
y = objective_value(EX; result = j)
println("Profit: \$ ",round.(Int,y[1]), " SDG: ",round.(Int,y[2]))
end
else
println("No solutions found")
end
#*******************************************************************


# Assignement 1.3 Lexicographic proft-SDG solution
println("#### Assignement 1.3 ####")
set_optimizer(EX, Gurobi.Optimizer)
set_silent(EX)

# Primo obiettivo: profitto
@objective(EX, Max, profit)
optimize!(EX)

profit_star = objective_value(EX)  # valore ottimo del profitto


tol = 1e-6
#@constraint(EX, profit_fix, profit >= profit_star - tol)
#@constraint(EX, profit_fix2, profit <= profit_star + tol)

# Ora ottimizza SDG tenendo bloccato grazie ai contraints profit al suo punto piu alto.
@objective(EX, Max, SDG)   # qui SDG è la tua expression
optimize!(EX)

println("Lexicographic solution (Profit -> SDG)")
println("Profit*: ", value(profit), "  SDG: ", value(SDG))




# Assignement 1.4 Pareto profit-SDG solution
println("#### Assignement 1.4 ####")

# IMPORTANT: ensure your SDG data vector is NOT called SDG if you also have an expression named SDG.
sdg_w = [8, 6, 8, 3, 4, 5, 3, 2, 7]
@expression(EX, sdg_score, sum(x[j]*sdg_w[j] for j in J))

# 1) Re-set the multiobjective objective (needed if you changed objective earlier)
@objective(EX, Max, [profit, sdg_score])

# 2) Set MO optimizer
set_optimizer(EX, () -> MultiObjectiveAlgorithms.Optimizer(Gurobi.Optimizer))
set_silent(EX)

# 3) Choose algorithm
set_attribute(EX, MultiObjectiveAlgorithms.Algorithm(),
              MultiObjectiveAlgorithms.EpsilonConstraint())

# 4) Solve
optimize!(EX)

# 5) Read Pareto points
k = result_count(EX)
println("No Pareto optimal points: ", k)

for r in 1:k
    y   = objective_value(EX; result = r)  # y[1]=profit, y[2]=sdg_score
    x_r = value.(x; result = r)            # x values for that Pareto point

    println("Point ", r,
            " | Profit: ", round(Int, y[1]),
            " | SDG: ", round(Int, y[2]),
            " | x: ", round.(Int, x_r))
end

using PrettyTables

k = result_count(EX)
J = 1:9

# Costruisco una matrice k x (2+9) con: Profit, SDG, x1..x9
data = Array{Int}(undef, k, 2 + length(J))

for r in 1:k
    y = objective_value(EX; result = r)
    xr = value.(x; result = r)

    data[r, 1] = round(Int, y[1])                 # Profit Obj
    data[r, 2] = round(Int, y[2])                 # SDG Obj
    data[r, 3:end] = round.(Int, xr)              # x1..x9
end

# (Opzionale) ordina come nella tua tabella: Profit crescente, SDG decrescente
ord = sortperm(collect(1:k), by = i -> (data[i,1], -data[i,2]))
data = data[ord, :]

# Intestazioni colonne
col_labels = vcat(["Profit Obj", "SDG Obj"], ["x$i" for i in J])

# Stampa tabella
pretty_table(
    data;
    header = col_labels,
    tf = PrettyTables.tf_markdown,
    alignment = :c
)



println("\nTable 8.2: Profit-SDG Pareto front")


