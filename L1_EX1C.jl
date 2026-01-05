#COMPACT VERSION OF L1_EX1.jl
using JuMP
using  HiGHS
IC = Model(HiGHS.Optimizer)

@variable(IC, x1 >= 0)
@variable(IC, x2 >= 0)
@variable(IC, x3 >= 0)
@variable(IC, x4 >= 0)
@variable(IC, x5 >= 0)


@objective(IC, Max, 50x1 + 45x2 +85x3 +60x4 +55x5)

#=
machines constraints,In Julia, the prefix 0x means a hexadecimal number. So:
0x2 is the integer 2 (hex 0x02)
0x3 is 3
0x4 is 4
0x5 is 5
=#

@constraint(IC, 7x1 + 9x4 <= 450)
@constraint(IC, 5x1 + 7x2 + 11x3  + 5x5 <= 450)
@constraint(IC, 3x2 + 8x3 + 15x4 + 3x5 <= 450)
#workers constraint
@constraint(IC, 12x1 + 3x2 + 11x3 + 9x4 + 6x5 <= 900)

#DEMAND CONSTRAINTS
@constraint(IC, x1 <= 25)   
@constraint(IC, x2 <= 10)
@constraint(IC, x3 <= 12)
@constraint(IC, x4 <= 15)
@constraint(IC, x5 <= 60)

print(IC)
optimize!(IC)
println("\n===== RESULTS =====")
println("Objective value: ", objective_value(IC))
println("-------------------")
for (name, var) in [("x1", x1), ("x2", x2), ("x3", x3), ("x4", x4), ("x5", x5)]
    println(rpad(name, 3), " = ", round(value(var), digits=6))
end
println("===================\n")
