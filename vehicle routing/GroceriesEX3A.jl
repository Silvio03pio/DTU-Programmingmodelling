# Groceries: usando metodo con variabile x[i,j] bidimensionale
using JuMP
using Gurobi
using Printf

# -----------------------------
# Data
# -----------------------------
n = 13
depot = 1
K = 3
Q = 26

xcoord = [0, 104, 370, 651, 112, 134, 797, 347, 756, 304, 236, 687, 452]
ycoord = [0,  19, 305, 221, 121, 515, 424, 444, 141, 351, 775, 310,  57]
q      = [0,   3,   9,   7,  11,  11,   6,   7,   7,   2,   4,   2,   8]

V = 1:n
C = 2:n

# Distance matrix (Euclidean)
c = [hypot(xcoord[i] - xcoord[j], ycoord[i] - ycoord[j]) for i in V, j in V]

# -----------------------------
# Model
# -----------------------------
model = Model(Gurobi.Optimizer)

# Optional solver controls (can help on harder instances)
# set_attribute(model, "time_limit", 300.0)       # seconds
# set_attribute(model, "mip_rel_gap", 1e-6)



@variable(model, xarc[V, V], Bin)
@variable(model, u[V] >= 0)

# Objective: minimize total traveled distance
@objective(model, Min, sum(c[i, j] * xarc[i, j] for i in V, j in V))

# 1)No self-loops
@constraint(model, [i in V], xarc[i, i] == 0)

# 2)Depot must have exactly K departures and K arrivals
@constraint(model, sum(xarc[depot, j] for j in C) == K)
@constraint(model, sum(xarc[i, depot] for i in C) == K)

# 3)Each customer visited exactly once (one in, one out)
@constraint(model, [i in C], sum(xarc[i, j] for j in V if j != i) == 1)
@constraint(model, [i in C], sum(xarc[j, i] for j in V if j != i) == 1)

# 4)u definition / bounds
@constraint(model, u[depot] == 0)
@constraint(model, [i in C], u[i] <= Q - q[i])   # so u[i] + q[i] <= Q

# 5)If depot -> i is used, then i is the first customer => u[i] = 0
@constraint(model, [i in C], u[i] <= (Q - q[i]) * (1 - xarc[depot, i]))

# 6)MTZ-capacity constraints (as stated in the assignment text)
# u_i + q_i ≤ u_j + Q*(1 - x_ij), for i != j, j in customers
@constraint(model, [i in V, j in C; i != j], u[i] + q[i] <= u[j] + Q * (1 - xarc[i, j]))

optimize!(model)

# -----------------------------
# Output
# -----------------------------
status = termination_status(model)
@printf("Status: %s\n", string(status))
@printf("Objective value: %.2f\n\n", objective_value(model))

# Extract routes (start from each outgoing arc from depot)
function extract_routes(xarc, depot, n)
    routes = Vector{Vector{Int}}()
    firsts = [j for j in 1:n if j != depot && value(xarc[depot, j]) > 0.5]

    for j0 in firsts
        route = [depot, j0]
        cur = j0
        while cur != depot
            nxt_candidates = [j for j in 1:n if j != cur && value(xarc[cur, j]) > 0.5]
            if isempty(nxt_candidates)
                error("Route extraction failed: no outgoing arc from node $cur.")
            end
            nxt = nxt_candidates[1]
            push!(route, nxt)
            cur = nxt
        end
        push!(routes, route)
    end
    return routes
end

routes = extract_routes(xarc, depot, n)

for (k, r) in enumerate(routes)
    demand = sum(q[i] for i in r if i != depot)
    dist = sum(c[r[t], r[t+1]] for t in 1:length(r)-1)
    @printf("Van %d route: %s\n", k, join(r, " -> "))
    @printf("  Demand: %d / %d\n", demand, Q)
    @printf("  Distance: %.2f\n\n", dist)
end
