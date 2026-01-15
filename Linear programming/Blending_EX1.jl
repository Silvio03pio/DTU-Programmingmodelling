using JuMP
import Gurobi

m = Model(Gurobi.Optimizer)
set_silent(m)

V = 2
O = 3
U = V + O

veg = 1:V
nonveg = (V+1):U
all = 1:U

c = [110, 120, 130, 110, 115]
h = [8.8, 6.1, 2.0, 4.2, 5.0]

cap_veg, cap_nonv = 200.0, 250.0
hmin, hmax = 3.0, 6.0

p = 150.0

#Variables
@variable(m, x[all] >= 0)          # quantità raffinata di ciascun olio

#Objective
@objective(m, Max, sum(x[i]*p - c[i]*x[i] for i in all))

# 1) Capacità
@constraint(m, sum(x[i] for i in veg) <= cap_veg)
@constraint(m, sum(x[i] for i in nonveg) <= cap_nonv)

# 2) Vincoli di hardening medio (linearizzati)
@constraint(m, sum((h[i] - hmin) * x[i] for i in all) >= 0)
@constraint(m, sum((hmax - h[i]) * x[i] for i in all) >= 0)

optimize!(m)

println("Obj = ", objective_value(m))
println("x = ", value.(x))

