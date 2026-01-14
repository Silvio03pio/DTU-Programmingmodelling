using JuMP
using Gurobi  # o HiGHS

model = Model(Gurobi.Optimizer)
set_silent(model)

nodes = 1:10
warehouses = [4, 9]

# Domande clienti (come nella tabella)
demand = Dict(1=>30, 2=>30, 3=>50, 5=>20, 6=>30, 7=>30, 8=>40, 10=>20)
D = sum(values(demand))  # 250

# --- DATI RETE ---
arcs = Tuple{Int,Int}[
    (1,5), (1,4),
    (3,1), (3,6), (3,8), (3,10),
    (4,3), (4,5),
    (5,9),
    (6,9),
    (7,2), (7,9), (7,1),
    (8,4), (8,10),
    (9,10), (9,1),
    (10,7)
]  

c = Dict{Tuple{Int,Int}, Int}()
c[(1,5)] = 5
c[(1,4)] = 4
c[(3,1)] = 3
c[(3,6)] = 9
c[(3,8)] = 8
c[(3,10)] = 9
c[(4,3)] = 8
c[(4,5)] = 5
c[(5,9)] = 7
c[(6,9)] = 3
c[(7,2)] = 1
c[(7,9)] = 1
c[(7,1)] = 8
c[(8,4)] = 3
c[(8,10)] = 5
c[(9,10)] = 6
c[(9,1)] = 7
c[(10,7)] = 7


# Variabili di flusso sugli archi
@variable(model, x[a in arcs] >= 0)

# Variabili di apertura warehouse
@variable(model, y[w in warehouses], Bin)

#= sblocca per ex.1
# z = 1 se entrambi aperti
@variable(model, z, Bin)
=#

# supply iniettata da ciascun warehouse
@variable(model, s[w in warehouses] >= 0)

# Obiettivo: costi spedizione + costi apertura
@objective(model, Min, sum(c[a] * x[a] for a in arcs) + 1000*(y[4] + y[9]))

# Almeno un warehouse aperto
@constraint(model, y[4] + y[9] >= 1)


#= sblocca per ex.1
# z = AND(y4,y9)
@constraint(model, z <= y[4])
@constraint(model, z <= y[9])
@constraint(model, z >= y[4] + y[9] - 1)

# Capacità: 250 se solo uno aperto, 125 ciascuno se entrambi
@constraint(model, s[4] <= 250*y[4] - 125*z)
@constraint(model, s[9] <= 250*y[9] - 125*z)
=#

#sblocca per ex.2
@constraint(model, s[4] <= 250 * y[4])
@constraint(model, s[9] <= 250 * y[9])
@constraint(model, s[4] + s[9] == D)
@constraint(model, y[4] + y[9] >= 1)


# Soddisfa domanda totale
@constraint(model, s[4] + s[9] == D)

# Flow balance su ogni nodo
for v in nodes
    local out = sum((x[a] for a in arcs if a[1] == v); init = 0.0)
    local inn = sum((x[a] for a in arcs if a[2] == v); init = 0.0)

    if v == 4
        @constraint(model, out - inn == s[4])
    elseif v == 9
        @constraint(model, out - inn == s[9])
    elseif haskey(demand, v)
        @constraint(model, out - inn == -demand[v])
    else
        @constraint(model, out - inn == 0)
    end
end






optimize!(model)
println("Status: ", termination_status(model))


println("y4 = ", value(y[4]), "   y9 = ", value(y[9]))
println("s4 = ", value(s[4]), "   s9 = ", value(s[9]))
println("Obj = ", objective_value(model))


for a in arcs
    if value(x[a]) > 1e-6
        println(a, "  flow=", value(x[a]), "  cost=", c[a])
    end
end