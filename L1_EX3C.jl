# Blending (compact) — JuMP + HiGHS
using JuMP
import HiGHS

m = Model(HiGHS.Optimizer)
set_silent(m)

OILS = [:VEG1, :VEG2, :OIL1, :OIL2, :OIL3]
VEG  = [:VEG1, :VEG2]
NONV = [:OIL1, :OIL2, :OIL3]

price = 150.0
cost  = Dict(:VEG1=>110.0, :VEG2=>120.0, :OIL1=>130.0, :OIL2=>110.0, :OIL3=>115.0) # potrei nche fare la versione con vettore e indexes
hard  = Dict(:VEG1=>8.8,   :VEG2=>6.1,   :OIL1=>2.0,   :OIL2=>4.2,   :OIL3=>5.0) # potrei nche fare la versione con vettore e indexes

cap_veg, cap_nonv = 200.0, 250.0
hmin, hmax = 3.0, 6.0

@variable(m, x[o in OILS] >= 0)  # tons of each oil used

@expression(m, total, sum(x[o] for o in OILS)) # total production, lo uso quando voglio semplificare un'espressione ripetuta
@expression(m, hard_total, sum(hard[o] * x[o] for o in OILS)) # total hardness, usato quando voglio semplificare un'espressione ripetuta

@objective(m, Max, price * total - sum(cost[o] * x[o] for o in OILS))

@constraint(m, sum(x[o] for o in VEG)  <= cap_veg)
@constraint(m, sum(x[o] for o in NONV) <= cap_nonv)
@constraint(m, hard_total >= hmin * total)
@constraint(m, hard_total <= hmax * total)

optimize!(m)

println("Termination: ", termination_status(m))
println("Objective (profit): ", objective_value(m))
for o in OILS
    println(o, " = ", value(x[o]))
end
println("Total produced: ", value(total))
println("Hardness: ", value(hard_total) / value(total))
