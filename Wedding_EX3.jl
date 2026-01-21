#************************************************************************y
# WeddingPlanner Assignment 3, "Mathematical Programming Modelling" (42112)
using JuMP
using HiGHS
#************************************************************************y
#************************************************************************y
# PARAMETERS
include("WeddingData20.jl") # small dataset
println("Runing WeddingPlanner with $(G) guests, $(T) tables with capacity $(TableCap)")
#************************************************************************
#************************************************************************
# Model
wp = Model(HiGHS.Optimizer)
# 1 if guest g is sitting at table T
@variable(wp, x[g=1:G,t=1:T], Bin)
# excess males at table t
@variable(wp, m[t=1:T] >= 0)
# excess females at table t
@variable(wp, f[t=1:T] >= 0)
# Minimize the sum of males or females exceeding 2 at tables
@objective(wp, Min, sum( m[t] + f[t] for t=1:T))
# all guests has to sit at a table
@constraint(wp, [g=1:G],
sum( x[g,t] for t=1:T) == 1)
# dont exceed the number of persons at a table
@constraint(wp, [t=1:T],
sum( x[g,t] for g=1:G) <= TableCap)
# couples should sit at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; Couple[g1,g2]==1],
x[g1,t] == x[g2,t])
# if there are too many males at at table, penalty
@constraint(wp, [t=1:T],
sum( Male[g]*x[g,t] - Female[g]*x[g,t] for g=1:G) <=
m[t] + 2)
# if there are too many females at at table, penalty
@constraint(wp, [t=1:T],
sum( Female[g]*x[g,t] - Male[g]*x[g,t] for g=1:G) <=
f[t] + 2)
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
total_shared_int_table=0
print("Table $(t) : ")
for g1=1:G
sh_g1=0
if value(x[g1,t])>0.01
print(" $(g1) ")
end
end
println("")
println("Penalties: (Gender: $(value(m[t])+value(f[t])))")
end
else
println(" No solution")
end
println("--------------------------------------");
#************************************************************************y