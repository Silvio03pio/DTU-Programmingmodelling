#planning a trip to australia, but this time we are going to use just the needed variables
using JuMP
using Gurobi

EX = Model(Gurobi.Optimizer)
set_silent(EX)

# Data & Indexes
N = 6 # nodes
S = 1  # source node
T = 6 # destination node

#directed arcs
arcs = [
    (1,2), (1,3),
    (2,5), (2,4),
    (3,5), (3,4),
    (4,5), (4,6),
    (5,6)
]

#Arc cost 
c = Dict{Tuple{Int,Int}, Int}()
c[(1,2)] = 6
c[(1,3)] = 9
c[(2,5)] = 5
c[(2,4)] = 2
c[(3,5)] = 2
c[(3,4)] = 5
c[(4,5)] = 6
c[(4,6)] = 10
c[(5,6)] = 5

#Variables
@variable(EX, x[a in arcs] >= 0 )

#objective
@objective(EX, Min, sum(c[a]*x[a] for a in arcs))

# 1) SOURCE constraint, outflow - inflow = 1
@constraint(EX, 
    sum(x[a] for a in arcs if a[1] == S) - sum(x[a] for a in arcs if a[2] == S) ==1
    )

# 2) intermediate constraint, inflow = outflow
@constraint(EX, [k in 1:N; k != S && k != T],
    sum(x[a] for a in arcs if a[2] == k) == sum(x[a] for a in arcs if a[1] == k)
    )

# 3) destination constraint, inflow - outflow = -1
@constraint(EX, 
    sum(x[a] for a in arcs if a[2] == T) - sum(x[a] for a in arcs if a[1] == T) ==1
    )

write_to_file(EX, "test2.lp")
    
optimize!(EX)
if termination_status(EX) == MOI.OPTIMAL
    println("termination_status ", termination_status(EX))
    println("objective_value \$  ",objective_value(EX)*100)

    println("\nchosen arcs:")
    for a in arcs
        if value(x[a]) > 1e-6
            println(" flow on arc x[$a] = $(value(x[a]))")
        end
    end
else
    println("model not optimal (maybe infeasible).")
end
