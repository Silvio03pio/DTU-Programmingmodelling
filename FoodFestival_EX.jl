using JuMP
using Gurobi

include("FoodFestival_data.jl")   # deve definire S e Conflict

m = Model(Gurobi.Optimizer)
set_silent(m)

I = 25
workers = 1:I
shifts = 1:S

@variable(m, x[workers, shifts], Bin)   # 1 se worker i fa shift s
@variable(m, w[workers], Bin)           # 1 se worker i è assunto

@objective(m, Min, sum(w[i] for i in workers))

# 1) ogni shift deve essere coperto da un worker
@constraint(m, cover[s in shifts], sum(x[i,s] for i in workers) == 1)

# 2) conflitti (matrice binaria)
conflict_pairs = [(s,t) for s in shifts, t in shifts if s < t && Conflict[s,t] == 1]
@constraint(m, [i in workers, (s,t) in conflict_pairs], x[i,s] + x[i,t] <= 1)

# 3) linking: se lavora allora deve essere assunto
@constraint(m, [i in workers, s in shifts], x[i,s] <= w[i])

# opzionale: se è assunto deve lavorare almeno uno shift
# @constraint(m, [i in workers], sum(x[i,s] for s in shifts) >= w[i])

optimize!(m)

println("Obj = ", objective_value(m))
