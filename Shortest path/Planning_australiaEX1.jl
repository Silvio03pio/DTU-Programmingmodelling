#planning a trip to australia
using JuMP
using Gurobi

EX = Model(Gurobi.Optimizer)
set_silent(EX)

# Data & Indexes
N = 6 # nodes
S = 1  # source node
T = 6 # destination node
c = [ # cost matrix, C35 = 9, NO 2
    0 6 2 0 0 0
    0 0 0 2 5 0
    0 5 0 5 9 0
    0 0 0 0 6 10
    0 0 0 0 0 5
    0 0 0 0 0 0
] 

# Variables
@variable(EX, x[1:N,1:N] >= 0)

# Fix infeasible arcs to zero (where c[i,j] = 0)
for i in 1:N, j in 1:N
    if c[i,j] == 0
        fix(x[i,j], 0.0; force = true)
    end
end

# objective function 
@objective(EX, Min, sum(c[i,j]*x[i,j] for i in 1:N, j in 1:N))

#Source constraint; OUTFLOW - INFLOW = 1 
@constraint(EX, sum(x[S,j] for j in 1:N) - sum(x[i,S] for i in 1:N) == 1)

#Destination constraint; OUTFLOW - INFLOW = - 1 
@constraint(EX, sum(x[i,T] for i in 1:N) - sum(x[T,j] for j in 1:N) == 1)

#intermediate nodes; OUTFLOW - INFLOW = 0 
for v in 1:N
    if v != S && v !=T 
        @constraint(EX, 
            sum(x[i,v] for i in 1:N) == sum(x[v,j] for j in 1:N)
        )
    end
end

write_to_file(EX, "test1.lp")

optimize!(EX)
if termination_status(EX) == MOI.OPTIMAL
    println("termination_status ", termination_status(EX))
    println("objective_value \$  ",objective_value(EX)*100)

    println("\nchosen arcs:")
    for i in 1:N, j in 1:N
        if value(x[i,j]) >1e-6
            println("x[$i,$j] = $(value(x[i,j]))")
        end
    end
else
    println("model not optimal (maybe infeasible).")
end







