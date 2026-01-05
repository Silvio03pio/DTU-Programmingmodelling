# L1_EX1.jl — STANDARD (readable) VERSION
# Production planning LP with 5 products, 3 machines, and 1 labor resource

using JuMP
import HiGHS
using Printf

# =========================
# 1) DATA
# =========================
products = 1:5
machines = 1:3

profit = Dict(
    1 => 50.0,
    2 => 45.0,
    3 => 85.0,
    4 => 60.0,
    5 => 55.0
)

# a[m,i] = machine m time required per unit of product i
a = Dict(
    (1,1) => 7.0,  (1,2) => 0.0,  (1,3) => 0.0,  (1,4) => 9.0,  (1,5) => 0.0,
    (2,1) => 5.0,  (2,2) => 7.0,  (2,3) => 11.0, (2,4) => 0.0,  (2,5) => 5.0,
    (3,1) => 0.0,  (3,2) => 3.0,  (3,3) => 8.0,  (3,4) => 15.0, (3,5) => 3.0
)

machine_capacity = Dict(1 => 450.0, 2 => 450.0, 3 => 450.0)

# labor per unit
labor = Dict(1 => 12.0, 2 => 3.0, 3 => 11.0, 4 => 9.0, 5 => 6.0)
labor_capacity = 900.0

# demand upper bounds
demand_ub = Dict(1 => 25.0, 2 => 10.0, 3 => 12.0, 4 => 15.0, 5 => 60.0)

# =========================
# 2) MODEL
# =========================
IC = Model(HiGHS.Optimizer)
set_silent(IC)  # comment out if you want solver output

# =========================
# 3) DECISION VARIABLES
# =========================
@variable(IC, x[i in products] >= 0)

# =========================
# 4) OBJECTIVE FUNCTION
# =========================
@objective(IC, Max, sum(profit[i] * x[i] for i in products))

# =========================
# 5) CONSTRAINTS
# =========================
# Machine capacity constraints (one per machine)
@constraint(IC, machineCap[m in machines],
    sum(a[(m,i)] * x[i] for i in products) <= machine_capacity[m]
)

# Labor constraint
@constraint(IC, laborCap,
    sum(labor[i] * x[i] for i in products) <= labor_capacity
)

# Demand constraints (upper bounds)
@constraint(IC, demand[i in products], x[i] <= demand_ub[i])

# (Optional) Print model to screen
print(IC)

# =========================
# 6) SOLVE
# =========================
optimize!(IC)

# =========================
# 7) RESULTS
# =========================
println("\n===== RESULTS =====")
println("Termination: ", termination_status(IC))
@printf("Objective value: %12.6f\n", objective_value(IC))
println("-------------------")
for i in products
    @printf("x[%d] = %12.6f\n", i, value(x[i]))
end
println("===================\n")
