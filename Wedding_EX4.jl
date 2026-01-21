# WeddingPlanner Assignment 4, "Mathematical Programming Modelling" (42112)
using JuMP
using Gurobi

# PARAMETERS
include("WeddingData20.jl") # small dataset
println("Runing WeddingPlanner with $(G) guests, $(T) tables with capacity $(TableCap)")

# Model
wp =Model(Gurobi.Optimizer)

# 1) Variable, 1 if guest g is sitting at table T
@variable(wp, x[g=1:G,t=1:T], Bin)
# 2) Variable, 1 if guest g1 and guest g2 are both sitting at table T, symmetric
@variable(wp, 0 <= y[g1=1:G,g2=1:G,t=1:T] <= ( g1 < g2 ? 1 : 0) )
# 3) Variable, guest g is missing known people
@variable(wp, k[g=1:G] >= 0)

# Minimize the number of people at tables where they know less than 3
@objective(wp, Min,sum( k[g] for g=1:G))

# all guests has to sit at a table
@constraint(wp, [g=1:G], sum( x[g,t] for t=1:T) == 1)

# 1) constraint, dont exceed the number of persons at a table
@constraint(wp, [t=1:T], sum( x[g,t] for g=1:G) <= TableCap)

# 2) constraint, couples should sit at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; Couple[g1,g2]==1], x[g1,t] == x[g2,t])

# 3) constraint, limit y, can only become 1 if g1 and g2 are at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; g1<g2], y[g1,g2,t] <= x[g1,t])

# 4) constraint, limit y, can only become 1 if g1 and g2 are at the same table
@constraint(wp, [g1=1:G,g2=1:G,t=1:T; g1<g2], y[g1,g2,t] <= x[g2,t])

# 5) constraint, if a person sits at a table, penalty if not enough known people
@constraint(wp, [g=1:G,t=1:T], k[g] - 3*x[g,t] + sum( Know[g,g1]*(y[g,g1,t]+y[g1,g,t]) for g1=1:G) >= 0)

# solve
optimize!(wp)
println("Termination status: $(termination_status(wp))")

# Report results
println("-------------------------------------");
if termination_status(wp) == MOI.OPTIMAL
    println("RESULTS:")
    println("objective = $(objective_value(wp))")
    for t = 1:T 
        total_not_know_at_table=0
        print("Table $(t) : ")
        for g1=1:G
            sh_g1=0
            if value(x[g1,t])>0.01
                total_not_know_at_table+=value(k[g1])
                print(" $(g1) ")
            end
        end
    println("")
    println("Penalties: (Missing known: $(total_not_know_at_table))")
    end
else
    println(" No solution")
end
println("--------------------------------------");
