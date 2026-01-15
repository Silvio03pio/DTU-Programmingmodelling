using JuMP
using HiGHS

function solve_tariff_rates(reserve_ratio::Float64)
    I = 1:3
    T = 1:5

    demand = [15000.0, 30000.0, 25000.0, 40000.0, 27000.0]
    hours  = [6.0, 3.0, 6.0, 3.0, 6.0]

    N    = [12, 10, 5]
    Pmin = [850.0, 1250.0, 1500.0]
    Pmax = [2000.0, 1750.0, 4000.0]

    c0 = [1000.0, 2600.0, 3000.0]   # €/hour at minimum
    c1 = [2.0, 1.3, 3.0]            # €/ (MW * hour) above minimum
    su = [2000.0, 1000.0, 500.0]    # start-up cost

    model = Model(HiGHS.Optimizer)

    @variable(model, 0 <= x[i in I, t in T] <= N[i], Int)   # units on
    @variable(model, p[i in I, t in T] >= 0)                # MW produced (total by type)
    @variable(model, u[i in I, t in T] >= 0, Int)           # start-ups

   # Objective
    @objective(model, Min, sum(
        hours[t] * (c0[i] * x[i,t] + c1[i] * (p[i,t] - Pmin[i] * x[i,t])) + su[i] * u[i,t]
        for i in I, t in T
    ))

    # Demand
    @constraint(model, [t in T], sum(p[i,t] for i in I) == demand[t])

    # Min/max output per type
    @constraint(model, [i in I, t in T], p[i,t] >= Pmin[i] * x[i,t])
    @constraint(model, [i in I, t in T], p[i,t] <= Pmax[i] * x[i,t])

    # Reserve
    @constraint(model, [t in T],
        sum(Pmax[i] * x[i,t] for i in I) >= (1.0 + reserve_ratio) * demand[t]
    )

    # Start-ups (cyclic)
    @constraint(model, [i in I, t in 2:5], u[i,t] >= x[i,t] - x[i,t-1])
    @constraint(model, [i in I],          u[i,1] >= x[i,1] - x[i,5])

    optimize!(model)

    println("Reserve ratio = ", reserve_ratio)
    println("Optimal objective = ", objective_value(model))

    for t in T
        println("\nPeriod ", t,
            " | x = ", [Int(round(value(x[i,t]))) for i in I],
            " | p = ", [value(p[i,t]) for i in I],
            " | u = ", [Int(round(value(u[i,t]))) for i in I]
        )
    end

    return model
end

# 15% reserve case
solve_tariff_rates(0.15)

# No-reserve case (for Assignment 12.2 baseline comparison)
solve_tariff_rates(0.0)
