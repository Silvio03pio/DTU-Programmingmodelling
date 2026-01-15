using JuMP
using HiGHS
using Printf

# Data & indexes
type_raw = [2 2 1 1 1 2 2 2 1 2 1 2 2 2 1 1 1 2 1 2 1 1 1 2 1 1 1 2 2 2 2 1 2 1 1 2 2 2 2 2 1 1 2 1 2 1 1 1 2 1 1 2 1 2 1 2 2 2 1 1 1 1 2 2 2 1 1 2 1 1]

arrival_raw = [1326 1346 1365 1292 1299 1354 1310 1327 1241 1218 1231 1377 1302 1314 1290 1277 1219 1232 1359 1313 1315 1325 1261 1338 1335 1217 1212 1201 1222 1297 1202 1368 1344 1233 1240 1307 1372 1341 1373 1228 1259 1376 1288 1246 1369 1234 1324 1262 1366 1276 1367 1242 1328 1225 1316 1291 1353 1249 1374 1247 1211 1298 1293 1321 1237 1363 1204 1380 1253 1378]

depart_raw = [1757 1894 1767 1936 1782 1783 1866 1787 1921 1750 1777 1908 1918 1893 1848 1881 1907 1788 1834 1853 1840 1771 1958 1753 1896 1959 1789 1922 1778 1935 1973 1974 1862 1801 1796 1938 1957 1810 1868 1961 1867 1811 1769 1925 1825 1781 1784 1843 1759 1886 1944 1955 1747 1960 1816 1772 1975 1785 1872 1758 1916 1970 1806 1923 1790 1766 1887 1819 1779 1879]

# Lunghezze binari (T=8)
L = [500, 800, 700, 400, 650, 650, 750, 500]

# ============================================================
# PREPROCESSING
# ============================================================

type_u = vec(type_raw)
arrival = vec(arrival_raw)
depart  = vec(depart_raw)

I = length(type_u)
T = length(L)

# Lunghezza unità: type 1 = 42m, type 2 = 84m
len_u = [type_u[i] == 1 ? 42 : 84 for i in 1:I]

# Controllo condizione per eliminare p_{i,k} (tutte presenti contemporaneamente in una finestra)
max_arr = maximum(arrival)
min_dep = minimum(depart)
println("Check finestra overnight: max(arrival) = $max_arr, min(depart) = $min_dep")
if max_arr >= min_dep
    println("ATTENZIONE: max(arrival) >= min(depart). In questo caso NON è lecito eliminare p_{i,k} per la capacità.")
    println("Questo script resta comunque eseguibile, ma la capacità sarebbe sottostimata in generale.")
else
    println("OK: max(arrival) < min(depart). Capacità 'statica' valida (tutte presenti tra $max_arr e $min_dep).")
end

# Costruzione conflitti LIFO (interleaving): (ai < aj < di < dj) OR (aj < ai < dj < di)
function build_conflicts(arrival::Vector{Int}, depart::Vector{Int})
    I = length(arrival)
    conflicts = Tuple{Int,Int}[]
    for i in 1:(I-1)
        ai, di = arrival[i], depart[i]
        for j in (i+1):I
            aj, dj = arrival[j], depart[j]
            if (ai < aj && aj < di && di < dj) || (aj < ai && ai < dj && dj < di)
                push!(conflicts, (i, j))
            end
        end
    end
    return conflicts
end

conflicts = build_conflicts(arrival, depart)
println("Numero coppie in conflitto LIFO (interleaving): ", length(conflicts))

# ============================================================
# SOLVER
# Versione SENZA p_{i,k} per la capacità, con counter y_t
# ============================================================

function solve_depot(; same_type_per_track::Bool=false,
                     type_u::Vector{Int},
                     len_u::Vector{Int},
                     L::Vector{Int},
                     conflicts::Vector{Tuple{Int,Int}})

    I = length(type_u)
    T = length(L)

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, x[1:I, 1:T], Bin)                  # 1 se unità i su binario t
    @variable(model, 0 <= y[t=1:T] <= L[t])             # counter: occupazione in metri (capacitata direttamente)

    # Ogni unità al massimo su un binario
    @constraint(model, [i=1:I], sum(x[i,t] for t in 1:T) <= 1)

    # Definizione counter (capacità statica: tutte presenti contemporaneamente)
    @constraint(model, [t=1:T], y[t] == sum(len_u[i] * x[i,t] for i in 1:I))

    # Vincoli LIFO: due unità in conflitto non possono stare sullo stesso binario
    @constraint(model, [t=1:T, (i,j) in conflicts], x[i,t] + x[j,t] <= 1)

    # Vincoli Assignment 13.2: un solo tipo per binario
    if same_type_per_track
        @variable(model, z[t=1:T, r=1:2], Bin)                      # binario t dedicato a tipo r
        @constraint(model, [t=1:T], sum(z[t,r] for r in 1:2) <= 1)  # al più un tipo per binario
        @constraint(model, [i=1:I, t=1:T], x[i,t] <= z[t, type_u[i]])
    end

    # Obiettivo: massimizzare # unità parcheggiate
    @objective(model, Max, sum(x[i,t] for i in 1:I, t in 1:T))

    optimize!(model)

    status = termination_status(model)
    if status != MOI.OPTIMAL && status != MOI.FEASIBLE_POINT
        println("Solver status: ", status)
    end

    obj = objective_value(model)
    xval = value.(x)
    yval = value.(y)

    return obj, xval, yval
end

# ============================================================
# STAMPA SOLUZIONE
# ============================================================

function print_solution(title::String, obj, xval, yval, type_u, len_u, L)
    I = size(xval, 1)
    T = size(xval, 2)

    println("\n============================================================")
    println(title)
    println("Obiettivo (unità parcheggiate): ", obj)
    println("============================================================")

    parked = Int[]
    not_parked = Int[]

    for i in 1:I
        assigned = false
        for t in 1:T
            if xval[i,t] > 0.5
                assigned = true
                break
            end
        end
        if assigned
            push!(parked, i)
        else
            push!(not_parked, i)
        end
    end

    println("Totale parcheggiate: ", length(parked))
    println("Totale non parcheggiate: ", length(not_parked))
    if !isempty(not_parked)
        println("Unità non parcheggiate (indici): ", not_parked)
    end

    for t in 1:T
        units_on_t = [i for i in 1:I if xval[i,t] > 0.5]
        used = yval[t]
        @printf("\nBinario %d: usato = %.0f m / %d m\n", t, used, L[t])
        if isempty(units_on_t)
            println("  (vuoto)")
        else
            # Stampa (indice, tipo, lunghezza)
            for i in units_on_t
                @printf("  unità %2d | tipo %d | len %2d\n", i, type_u[i], len_u[i])
            end
        end
    end
end

# ============================================================
# RUN: Assignment 13.1
# ============================================================

obj1, x1, y1 = solve_depot(
    same_type_per_track=false,
    type_u=type_u,
    len_u=len_u,
    L=L,
    conflicts=conflicts
)

print_solution("Assignment 13.1 (senza p_{i,k}, con counter y[t])", obj1, x1, y1, type_u, len_u, L)

# ============================================================
# RUN: Assignment 13.2 (stesso tipo per binario)
# ============================================================

obj2, x2, y2 = solve_depot(
    same_type_per_track=true,
    type_u=type_u,
    len_u=len_u,
    L=L,
    conflicts=conflicts
)

print_solution("Assignment 13.2 (stesso tipo per binario, senza p_{i,k})", obj2, x2, y2, type_u, len_u, L)
