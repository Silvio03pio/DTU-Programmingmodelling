#************************************************************************y
# WeddingPlanner Assignment 2, "Mathematical Programming Modelling" (42112)
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
wp =Model(HiGHS.Optimizer)
# 1 if guest g is sitting at table T
@variable(wp, x[g=1:G,t=1:T], Bin)
# 1 if guest g1 and guest g2 are both sitting at table T, symmetric
@variable(wp, 0 <= y[g1=1:G,g2=1:G,t=1:T] <= ( g1 < g2 ? 1 : 0) )
# Maximize the total amount of shared interests
@objective(wp, Max, sum( SharedInterests[g1,g2]*y[g1,g2,t]
for t=1:T, g1=1:G, g2=1:G if g1<g2) )
# all guests has to sit at a table
@constraint(wp, [g=1:G],
sum( x[g,t] for t=1:T) == 1)
# dont exceed the number of persons at a table
@constraint(wp, [t=1:T],
sum( x[g,t] for g=1:G) <= TableCap)
# couples should sit at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; Couple[g1,g2]==1],
x[g1,t] == x[g2,t])

# limit y, can only become 1 if g1 and g2 are at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; g1<g2],
y[g1,g2,t] <= x[g1,t])
# limit y, can only become 1 if g1 and g2 are at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; g1<g2],
y[g1,g2,t] <= x[g2,t])
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
print( " $(g1) ")
for g2=1:G
if value(y[g1,g2,t])>0.01
sh_g1+=SharedInterests[g1,g2]
end
end
total_shared_int_table+=sh_g1
end
end
println("")
println("Penalties: (Shared interests: $( total_shared_int_table))")
end
else
println(" No solution")
end
println("--------------------------------------");
#************************************************************************y