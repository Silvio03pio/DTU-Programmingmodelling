using JuMP
using HiGHS


# Data & indexes
I = 1:3           # beer types
M = 1:12          # months

d = [
    35 15  5;
    20 10 20;
    15 20 20;
    45 15 35;
    25 15 35;
    65 55 80;
    40 90 60;
    50 80 30;
    35 25 35;
    85 45 20;
    50  5 20;
    55 30 40
]

Brewing_capacity  = 120
Storing_capacity  = 300
Storage_cost      = 0.1
initial_storage   = [25, 65, 75]  # s0 for each beer type

# Decision variables
@variable(EX, x[m in M, i in I] >= 0)       # production (litres)
@variable(EX, s[m in M, i in I] >= 0)       # end-of-month inventory (litres)
@variable(EX, y[m in M, i in I], Bin)       # 1 if beer i is brewed in month m

# Objective: minimize total storage cost
@objective(EX, Min, Storage_cost * sum(s[m,i] for m in M, i in I))

# Inventory balance: meet demand exactly
@constraint(EX, balance[m in M, i in I],
    s[m,i] == (m == 1 ? initial_storage[i] : s[m-1,i]) + x[m,i] - d[m,i]
)

# Combined storage capacity (all beer types together)
@constraint(EX, store_cap[m in M],
    sum(s[m,i] for i in I) <= Storing_capacity
)

# Only one beer type can be brewed per month
@constraint(EX, one_type[m in M],
    sum(y[m,i] for i in I) <= 1
)

# Link production to the selected beer type (big-M)
@constraint(EX, link[m in M, i in I],
    x[m,i] <= Brewing_capacity * y[m,i]
)

optimize!(EX)

println("\n===== RESULTS =====")
println("Objective value: ", objective_value(EX))
println("Primal status: ", primal_status(EX))
