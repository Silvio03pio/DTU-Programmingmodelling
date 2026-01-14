using JuMP
using Gurobi  # o HiGHS

model = Model(Gurobi.Optimizer)
set_silent(model)

#Data & indexes 
N = 1:6
# Ordine nodi: 1=Grocery, 2=1, 3=2, 4=3, 5=4, 6=5
coords = [
    0   0
  104  19
  370 305
  651 221
  112 121
  134 515
]

n = size(coords, 1)
dist = zeros(Float64, n, n)

for i in 1:n, j in 1:n
    dist[i,j] = hypot(coords[i,1] - coords[j,1], coords[i,2] - coords[j,2])
end


#Variables
@variable(model, x[i in N,j in N], Bin) # 1 if van goes from i to j, 0 otherways

#fo
@objective(model, Min, sum(x[i,j]*dist[i,j] for i in N, j in N))

# 1)I can get in to each node only once
@constraint(model, in_once[j in N], sum(x[i,j] for i in N) == 1 )

# 2)I can get out to each node only once
@constraint(model, out_once[i in N], sum(x[i,j] for j in N) == 1 )

# 3) I can't stay in the same node
@constraint(model, sum(x[i,i] for i in N) == 0)

optimize!(model)
println("Status: ", termination_status(model))
println("objective_value is \$ ", objective_value(model))

for i in N, j in N
    if value(x[i,j]) > 0.5   # perché x è binaria (0/1), tolleranza numerica
        println("arc ", i, " -> ", j, "  x = ", value(x[i,j]))
    end
end
