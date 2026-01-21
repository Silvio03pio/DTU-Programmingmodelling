using JuMP, Gurobi, MultiObjectiveAlgorithms

I = 1:7          # tasks
J = 1:2          # persons (j=1 Eve, j=2 Steve)

# -----------------------------
# Data
# c[j,i] = hours person j needs to complete task i
# -----------------------------
c = [
    4.5 7.8 3.6 2.9 2.1 1.9 2.5;
    4.9 7.2 4.3 3.1 1.5 3.2 1.2;
]

# -----------------------------
# Model (multiobjective wrapper + Gurobi solver)
# -----------------------------
EX = Model(() -> MultiObjectiveAlgorithms.Optimizer(Gurobi.Optimizer))
set_silent(EX)

# -----------------------------
# Decision variables
# x[j,i] = 1 if task i assigned to person j, else 0
# -----------------------------
@variable(EX, x[j in J, i in I], Bin)

# -----------------------------
# Objective 1: minimize total worked time
# -----------------------------
@expression(EX, timeworked, sum(x[j,i] * c[j,i] for j in J, i in I))

# Total time of each person (used for fairness objective)
@expression(EX, TE, sum(x[1,i] * c[1,i] for i in I))   # Eve total time
@expression(EX, TS, sum(x[2,i] * c[2,i] for i in I))   # Steve total time

# -----------------------------
# Objective 2: minimize absolute difference |TS - TE|
# Implement absolute value with an auxiliary variable d >= 0:
#   d >= TS - TE
#   d >= TE - TS
# Then d = |TS - TE| at optimum (because we minimize it)
# -----------------------------
@variable(EX, d >= 0)
@constraint(EX, TS - TE <= d)
@constraint(EX, TE - TS <= d)
@expression(EX, timedifference, d)

# Combined bi-objective (Minimize both)
@objective(EX, Min, [timeworked, timedifference])

# -----------------------------
# Constraints
# Each task must be assigned to exactly one person
# -----------------------------
@constraint(EX, [i in I], sum(x[j,i] for j in J) == 1)

# -----------------------------
# Solve with epsilon-constraint method (returns multiple Pareto points)
# -----------------------------
set_attribute(EX, MultiObjectiveAlgorithms.Algorithm(),
              MultiObjectiveAlgorithms.EpsilonConstraint())
optimize!(EX)

# -----------------------------
# Print Pareto points (objective values)
# result_count(EX) = number of Pareto optimal solutions found
# objective_value(EX; result=r) returns [obj1, obj2] for Pareto point r
# -----------------------------
k = result_count(EX)
println("No Pareto optimal points: ", k)

for r in 1:k
    y = objective_value(EX; result = r)
    println("Point ", r,
            " | total time: ", y[1],
            " | |TS-TE|: ", y[2])
end
