# TennisEX.jl
# Assignments 14.1–14.4 (Tennis lines sweeping)
# Uses: JuMP + Gurobi
# 14.1: walk ONLY on lines, start=stop  -> optimal 390
# 14.2: can walk between lines, start=stop -> optimal 306
# 14.3: can walk between lines, start!=stop -> optimal 280.5
# 14.4: can walk between lines, start!=stop, endpoints only on outside lines -> optimal 287.47

using JuMP
using Gurobi
using Printf

# -----------------------------
# Geometry / graph definition
# -----------------------------
const n = 12

# Node coordinates (feet). Court half: from net (y=0) to baseline (y=39)
# x: left(-) to right(+), center at 0
x = [-18.0, -13.5,  0.0,  13.5,  18.0,  -13.5,  0.0,  13.5,  -18.0, -13.5, 13.5, 18.0]
y = [  0.0,   0.0,  0.0,   0.0,   0.0,   21.0, 21.0, 21.0,   39.0,  39.0, 39.0, 39.0]

# Required undirected edges = tennis lines to sweep (i, j, length)
required_edges = [
    (1,  9, 39.0),   # left doubles sideline
    (2,  6, 21.0),   # left singles from net to service line
    (6, 10, 18.0),   # left singles from service line to baseline
    (3,  7, 21.0),   # center line from net to service line
    (6,  7, 13.5),   # service line left half
    (7,  8, 13.5),   # service line right half
    (4,  8, 21.0),   # right singles from net to service line
    (8, 11, 18.0),   # right singles from service line to baseline
    (5, 12, 39.0),   # right doubles sideline
    (9, 10,  4.5),   # baseline left doubles alley
    (10,11, 27.0),   # baseline singles width
    (11,12,  4.5),   # baseline right doubles alley
]

L_required = sum(w for (_,_,w) in required_edges)

# -----------------------------
# Utilities: distance matrices
# -----------------------------
function euclid_dist_matrix(x::Vector{Float64}, y::Vector{Float64})
    n = length(x)
    d = zeros(Float64, n, n)
    for i in 1:n, j in 1:n
        d[i,j] = hypot(x[i]-x[j], y[i]-y[j])
    end
    return d
end

function shortest_path_on_lines(n::Int, edges)
    INF = 1.0e15
    d = fill(INF, n, n)
    for i in 1:n
        d[i,i] = 0.0
    end
    for (i,j,w) in edges
        d[i,j] = min(d[i,j], w)
        d[j,i] = min(d[j,i], w)
    end
    # Floyd–Warshall (n=12 -> fast)
    for k in 1:n, i in 1:n, j in 1:n
        v = d[i,k] + d[k,j]
        if v < d[i,j]
            d[i,j] = v
        end
    end
    return d
end

d_euc   = euclid_dist_matrix(x, y)
d_lines = shortest_path_on_lines(n, required_edges)

# -----------------------------
# Odd-degree nodes
# -----------------------------
deg = zeros(Int, n)
for (i,j,_) in required_edges
    deg[i] += 1
    deg[j] += 1
end
O = [i for i in 1:n if isodd(deg[i])]   # odd nodes

# -----------------------------
# Minimum-weight perfect matching on a node set T (|T| even)
# -----------------------------
function solve_matching_cost(d::Matrix{Float64}, T::Vector{Int})
    m = Model(Gurobi.Optimizer)
    set_attribute(m, "OutputFlag", 0)

    pairs = [(T[a], T[b]) for a in 1:length(T) for b in a+1:length(T)]
    @variable(m, yvar[pairs], Bin)

    for i in T
        @constraint(m, sum(yvar[(min(i,j), max(i,j))] for j in T if j != i) == 1)
    end

    @objective(m, Min, sum(d[i,j] * yvar[(i,j)] for (i,j) in pairs))
    optimize!(m)

    cost = objective_value(m)
    chosen = [(i,j) for (i,j) in pairs if value(yvar[(i,j)]) > 0.5]
    return cost, chosen
end

# -----------------------------
# Best open-walk extra via T-join:
# For endpoints (s,t), required odd set becomes T = O Δ {s,t}
# then extra = min perfect matching on T
# -----------------------------
function best_open_cost(d::Matrix{Float64}, O::Vector{Int}, candidates::Vector{Int})
    best = 1.0e18
    best_st = (0, 0)
    best_match = Tuple{Int,Int}[]

    Oset = Set(O)

    for a in 1:length(candidates), b in a+1:length(candidates)
        s = candidates[a]
        t = candidates[b]

        Tset = symdiff(Oset, Set([s, t]))   # symmetric difference (Set-safe)
        T = sort!(collect(Tset))

        if isodd(length(T))
            continue
        end

        cost, chosen = solve_matching_cost(d, T)
        if cost < best
            best = cost
            best_st = (s, t)
            best_match = chosen
        end
    end

    return best, best_st, best_match
end

# -----------------------------
# Assignment 14.1
# Only allowed to walk on the lines, must return to start (closed)
# => Chinese Postman on line-graph metric
# -----------------------------
cost_141, _ = solve_matching_cost(d_lines, O)
@printf("14.1  Optimal distance = %.2f ft  (expected 390)\n", L_required + cost_141)

# -----------------------------
# Assignment 14.2
# Allowed to walk between lines (Euclidean), still closed
# -----------------------------
cost_142, _ = solve_matching_cost(d_euc, O)
@printf("14.2  Optimal distance = %.2f ft  (expected 306)\n", L_required + cost_142)

# -----------------------------
# Assignment 14.3
# Allowed to walk between lines (Euclidean), open walk (start != stop), endpoints free
# -----------------------------
cand_all = collect(1:n)
best_143, best_st_143, _ = best_open_cost(d_euc, O, cand_all)
@printf("14.3  Optimal distance = %.2f ft  (expected 280.5)\n", L_required + best_143)
@printf("      Best endpoints (start,stop) = %s\n", string(best_st_143))

# -----------------------------
# Assignment 14.4
# Allowed to walk between lines (Euclidean), open walk, endpoints only on outside lines:
# leftmost (x=-18), rightmost (x=18), bottommost (y=39)
# -----------------------------
outside = [i for i in 1:n if (x[i] == -18.0) || (x[i] == 18.0) || (y[i] == 39.0)]
best_144, best_st_144, _ = best_open_cost(d_euc, O, outside)
@printf("14.4  Optimal distance = %.2f ft  (expected 287.47)\n", L_required + best_144)
@printf("      Best endpoints (start,stop) = %s\n", string(best_st_144))
