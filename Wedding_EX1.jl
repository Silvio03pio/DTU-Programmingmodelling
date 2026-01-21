# Wedding assignment 1
#************************************************************************y
# WeddingPlanner Assignment 1, "Mathematical Programming Modelling" (42112)
using JuMP
using Gurobi
#************************************************************************y
#************************************************************************y
# PARAMETERS
include("WeddingData20.jl") # small dataset
println("Runing WeddingPlanner with $(G) guests, $(T) tables with capacity $(TableCap)")
#************************************************************************
#************************************************************************
# Model
wp =Model(Gurobi.Optimizer)

# 1 if guest g is sitting at table T
@variable(wp, x[g=1:G,t=1:T], Bin)

# Minimize dummy objective
@objective(wp, Min, 42 )

# all guests has to sit at a table
@constraint(wp, [g=1:G],sum( x[g,t] for t=1:T) == 1)

# dont exceed the number of persons at a table
@constraint(wp, [t=1:T],sum( x[g,t] for g=1:G) <= TableCap)

# couples should sit at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; Couple[g1,g2]==1],x[g1,t] == x[g2,t])

#************************************************************************
#************************************************************************
# solve
optimize!(wp)
println("Termination status: $(termination_status(wp))")
#************************************************************************
#************************************************************************
# Report results
println("-------------------------------------");
if termination_status(wp) == MOI.OPTIMAL
println("RESULTS:")
println("objective = $(objective_value(wp))")
for t = 1:T
print("Table $(t) : ")
for g1=1:G
sh_g1=0
if value(x[g1,t])>0.01
print(" $(g1) ")
end
end
println("")
println("")
end
else
println(" No solution")
end
println("--------------------------------------");
#************************************************************************y