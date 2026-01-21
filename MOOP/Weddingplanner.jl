# MOOP WeddingPlanner 
using JuMP, Gurobi, MultiObjectiveAlgorithms

wp = Model(() -> MultiObjectiveAlgorithms.Optimizer(Gurobi.Optimizer))

# PARAMETERS
include("WeddingData74.jl") # small dataset
println("Runing WeddingPlanner with $(G) guests, $(T) tables with capacity $(TableCap)")


# 1) Variable, 1 if guest g is sitting at table T
@variable(wp, x[g=1:G,t=1:T], Bin)
# 2) Variable, 1 if guest g1 and guest g2 are both sitting at table T, symmetric
@variable(wp, 0 <= y[g1=1:G,g2=1:G,t=1:T] <= ( g1 < g2 ? 1 : 0) )
# 3) Variable, guest g is missing known people
@variable(wp, k[g=1:G] >= 0)
# 4) Variable, excess males at table t
@variable(wp, m[t=1:T] >= 0)
# 5) Varibale, excess females at table t
@variable(wp, f[t=1:T] >= 0)

# 1 Objective: maximize SharedInterests
@expression(wp, SI,  sum( SharedInterests[g1,g2]*y[g1,g2,t] for t=1:T, g1=1:G, g2=1:G if g1<g2))

# 2 Objective: maximize negative number gender differences plus the negative number of interests of guest who knows less than 3
@expression(wp, difference,  - sum( k[g] for g=1:G ) - sum( m[t] + f[t] for t=1:T))

#Define combined BI-Objective
@objective(wp, Max, [SI, difference])

# 0) all guests has to sit at a table
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


# Set MIP solver
set_optimizer(wp, ()->MultiObjectiveAlgorithms.Optimizer(Gurobi.Optimizer))
set_silent(wp)
# Set MO solver
set_attribute(wp, MultiObjectiveAlgorithms.Algorithm(),
MultiObjectiveAlgorithms.EpsilonConstraint())
optimize!(wp)

# Solution
if result_count(wp)>=1
    println("No Pareto optimal points: ",result_count(wp))
    for j in 1:result_count(wp)
        h = objective_value(wp; result = j)
        println("Obj1 ",round.(Int,h[1]), ", Obj2 ",round.(Int,h[2]))
    end
else
println("No solutions found")
end



