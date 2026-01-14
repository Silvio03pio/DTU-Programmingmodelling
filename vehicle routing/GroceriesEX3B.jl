# Groceries: usando metodo con variabile x[i,j,k] tridimensionale
using JuMP
using Gurobi
using Printf

model = Model(Gurobi.Optimizer)

# data & indexes
n = 13
depot = 1
K = 3
Q = 26

xcoord = [0, 104, 370, 651, 112, 134, 797, 347, 756, 304, 236, 687, 452]
ycoord = [0,  19, 305, 221, 121, 515, 424, 444, 141, 351, 775, 310,  57]
q      = [0,   3,   9,   7,  11,  11,   6,   7,   7,   2,   4,   2,   8]

V = 1:n
C = 2:n
Kset = 1:K

# Euclidean distance costs
c = [hypot(xcoord[i] - xcoord[j], ycoord[i] - ycoord[j]) for i in V, j in V]

@variable(model, xarc[V, V, Kset], Bin)   # x[i,j,k]
@variable(model, u[V, Kset] >= 0)         # u[i,k]

# Objective
@objective(model, Min, sum(c[i, j] * xarc[i, j, k] for i in V, j in V, k in Kset))

# No self loops
@constraint(model, [i in V, k in Kset], xarc[i, i, k] == 0)

# Each vehicle leaves depot once and returns once
@constraint(model, [k in Kset], sum(xarc[depot, j, k] for j in C) == 1)
@constraint(model, [k in Kset], sum(xarc[i, depot, k] for i in C) == 1)

# Each customer has exactly one outgoing and one incoming arc across all vehicles
@constraint(model, [i in C], sum(xarc[i, j, k] for k in Kset, j in V if j != i) == 1)
@constraint(model, [i in C], sum(xarc[j, i, k] for k in Kset, j in V if j != i) == 1)

# Flow conservation per vehicle at customer nodes
@constraint(model, [i in C, k in Kset],
    sum(xarc[i, j, k] for j in V if j != i) == sum(xarc[j, i, k] for j in V if j != i)
)

# u initialization at depot
@constraint(model, [k in Kset], u[depot, k] == 0)

# u bounds for customers
@constraint(model, [i in C, k in Kset], u[i, k] <= Q - q[i])

# Strengthening: if vehicle k does not visit i, then u[i,k] = 0
@constraint(model, [i in C, k in Kset],
    u[i, k] <= (Q - q[i]) * sum(xarc[i, j, k] for j in V if j != i)
)

# MTZ-capacity constraints per vehicle:
# u[i,k] + q[i] <= u[j,k] + Q*(1 - x[i,j,k])   for j in customers, i != j
@constraint(model, [i in V, j in C, k in Kset; i != j],
    u[i, k] + q[i] <= u[j, k] + Q * (1 - xarc[i, j, k])
)

optimize!(model)

@printf("Termination status: %s\n", string(termination_status(model)))
@printf("Objective value: %.2f\n\n", objective_value(model))

# -----------------------------
# Route extraction
# -----------------------------
function extract_route_for_vehicle(xarc, depot::Int, n::Int, k::Int)
    # find first node after depot
    nexts = [j for j in 1:n if j != depot && value(xarc[depot, j, k]) > 0.5]
    isempty(nexts) && return [depot, depot]  # should not happen due to constraints
    j0 = nexts[1]

    route = [depot, j0]
    cur = j0
    while cur != depot
        nxt_candidates = [j for j in 1:n if j != cur && value(xarc[cur, j, k]) > 0.5]
        isempty(nxt_candidates) && error("Extraction failed for vehicle $k at node $cur.")
        nxt = nxt_candidates[1]
        push!(route, nxt)
        cur = nxt
    end
    return route
end

for k in Kset
    r = extract_route_for_vehicle(xarc, depot, n, k)
    demand = sum(q[i] for i in r if i != depot)
    dist = sum(c[r[t], r[t+1]] for t in 1:length(r)-1)
    @printf("Van %d route: %s\n", k, join(r, " -> "))
    @printf("  Demand: %d / %d\n", demand, Q)
    @printf("  Distance: %.2f\n\n", dist)
end


using Plots

# --- raccogli le rotte in un array ---
routes = Vector{Vector{Int}}(undef, K)
for k in Kset
    routes[k] = extract_route_for_vehicle(xarc, depot, n, k)
end

# --- plot base: punti ---
p = scatter(
    xcoord, ycoord;
    markersize=5,
    xlabel="X coordinate",
    ylabel="Y coordinate",
    title="Groceries CVRP Routes (3 Vans)",
    label="Customers"
)

# evidenzia deposito (nodo 1)
scatter!(p, [xcoord[depot]], [ycoord[depot]]; markersize=9, label="Depot")

# etichette nodi
for i in 1:n
    annotate!(p, xcoord[i] + 10, ycoord[i] + 10, text(string(i), 9))
end

# --- traccia le rotte ---
for k in Kset
    r = routes[k]
    xs = [xcoord[i] for i in r]
    ys = [ycoord[i] for i in r]
    plot!(p, xs, ys; linewidth=2, marker=:circle, label="Van $k")
end

display(p)

# opzionale: salva su file
savefig(p, "routes.png")
# savefig(p, "routes.pdf")
