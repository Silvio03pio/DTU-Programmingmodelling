    #Blending part 2

    using JuMP
    import HiGHS

    EX = Model(HiGHS.Optimizer)
    set_silent(EX)

    #data & indexes
    M = 1:6 # months
    I = 1:5 # oils
    VEG  = 1:2
    NONV = 3:5

    Price = 150 # ton of oil sold
    storage_cost = 5 # ton of oil stocked
    max_oil_storable = 1000 # per each month & per each oil
    max_reffinery_o = 250
    max_reffinery_v = 200
    cost_oils = [
        110 120 130 110 115 ;
        130 130 110 90 115 ;
        110 140 130 100 95 ;
        120 110 120 120 125 ;
        100 120 150 110 105 ;
        90 100 140 80 135 ;
    ]
    Hardness = [
        8.8 6.1 2.0 4.2 5.0 ;
        8.8 6.1 2.0 4.2 5.0 ;
        8.8 6.1 2.0 4.2 5.0 ;
        8.8 6.1 2.0 4.2 5.0 ;
        8.8 6.1 2.0 4.2 5.0 ;
        8.8 6.1 2.0 4.2 5.0 ;
    ]

    #variables, se mettessi : in cost_oils avrei il valore della matrice, ma a me ora interessa lindice
    @variable(EX, x[m in M, i in I] >= 0 ) # tons of oil purchased each month for each oil
    @variable(EX, s[m in M, i in I] >= 0 ) # tons of oil stocked each month for each oil
    @variable(EX, w[m in M, i in I] >= 0 ) # tons of oil sold each month for each oil

    @objective(EX, Max, sum(Price * w[m,i] - cost_oils[m,i] * x[m,i] - storage_cost * s[m,i]
                            for m in M, i in I))

    #constraints, standard constraint("nome modello",matrice di vincli, condizione)
    @constraint(EX, r[m in M, i in I], s[m,i] <= 1000)

    #balance constraint
    @constraint(EX, balance[m in M, i in I],
        s[m,i] == (m > 1 ? s[m-1,i] : 500.0) + x[m,i] - w[m,i]
    )
    @constraint(EX, [i in I], s[6,i] == 500.0)


    # lower boud hardness
    @constraint(EX, hard_min[m in M],
    sum(Hardness[m,i] * w[m,i] for i in I) >= 3 * sum(w[m,i] for i in I)
    )
    #upper bound
    @constraint(EX, hard_max[m in M],
        sum(Hardness[m,i] * w[m,i] for i in I) <= 6 * sum(w[m,i] for i in I)
    )

    #reffinery constraint
   @constraint(EX, vegcap[m in M],  sum(w[m,i] for i in VEG)  <= max_reffinery_v)
   @constraint(EX, nonvcap[m in M], sum(w[m,i] for i in NONV) <= max_reffinery_o)



    optimize!(EX)
    println("Termination: ", termination_status(EX))
    println("Objective (profit): ", objective_value(EX))
    for m in M
        for i in I
            println("x[", m, ",", i, "] = ", value(x[m,i]))
        end
    end

