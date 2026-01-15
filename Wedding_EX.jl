# Wedding
using JuMP
using Gurobi

#Data
include("WeddingData20.jl")   

tables = 1:T
guests = 1:G

m = Model(Gurobi.Optimizer)
set_silent(m)

# 1) Variable: 1 if guest g sits on table t, 0 otherways
@variable(m, x[g in guests,t in tables], Bin)

# 2) Variable: 1 if guest g1 sits on the same table of guest g2
@variable(m, y[g1 in guests, g2 in guests], Bin)

# 1) Constraint: Everyone has to sit
@constraint(m, sit_once[g in guests], sum(x[g,t] for t in tables) == 1)

# 2) Constraint: Max 9 people at one table
@constraint(m, max9[t in Tables], sum(x[g,t] for g in guests) <= 9 )

# 3) constraint: cuples has to be sit on the same table
Couple_pairs = [(g1,g2) for g1 in guests, g2 in guests if g1 < g2 && Couple[g1,g2] == 1]  # sto creando delle coppie, perche la matrice binaria non e' sufficiente
@constraint(m, [t in tables, (g1,g2) in Couple_pairs], x[g1,t] == x[g2,t]) # una volta che ho creato le coppie allora applico la condizione

# 1) Objective function: maximizing the shared interests in a table
@objective(m, Max, sum(y[g1,g2]*SharedInterests[g1,g2] for g1 in guests,g2=g1+1:length(guests)))


write_to_file(m, "testwedding.lp")
optimize!(m)


println("objective value = ", objective_value(m))