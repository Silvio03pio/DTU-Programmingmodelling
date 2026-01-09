#************************************************************************
# Factory Planning Assignment ULTIMO-STORAGE,
# "Mathematical Programming Modelling" (42112)
#************************************************************************
# Intro definitions
using JuMP
using HiGHS
#************************************************************************
#************************************************************************
# PARAMETERS
Machines = ["Grinding","Vertical drilling",
"Horizontal drilling","Boring","Planing"]
M=length(Machines)
Products = ["PROD1","PROD2","PROD3","PROD4",
"PROD5","PROD6","PROD7"]
P=length(Products)
Time = ["Jan" "Feb" "Mar" "Apr" "May" "Jun"]
T = length(Time)
# data
Profit = [10 6 8 4 11 9 3]
ProcessTime = # machine,product
[0.5 0.7 0.0 0.0 0.3 0.2 0.5; # Grinding
0.1 0.2 0.0 0.3 0.0 0.6 0.0; # Vertical drilling
0.2 0.0 0.8 0.0 0.0 0.0 0.6; # Horizontal drilling
0.05 0.03 0.0 0.07 0.1 0.0 0.08; # Boring
0.0 0.0 0.01 0.0 0.05 0.0 0.05 # Planing
]
#= mainteinance dataset for L2_EX2
MachineRepairs = #machine, time
#Jan #Feb #Mar #Apr #May #Jun
[1.0 0.0 0.0 0.0 1.0 0.0; #Grinding
0.0 0.0 0.0 1.0 1.0 0.0; #V drill
0.0 2.0 0.0 0.0 0.0 1.0; #H drill
0.0 0.0 1.0 0.0 0.0 0.0; #Boring
0.0 0.0 0.0 0.0 0.0 1.0] #Planing
=#
NumMach = [4 2 3 1 1]
StorageCap = 100
StorageCost = 0.5
EndStock = 50
WorkingHoursPrMonth = 24*8*2 # no working days, 2 shifts of 8 hours
Demand = # product, month
#Jan #Feb #Mar #Apr #May #Jun
[500 600 300 200 0 500; #PROD1
1000 500 600 300 100 500; #PROD2
300 200 0 400 500 100; #PROD3
300 0 0 500 100 300; #PROD4
800 400 500 200 1000 1100; #PROD5
200 300 400 0 300 500; #PROD6
100 150 100 100 0 60; #PROD7
]
#************************************************************************
#************************************************************************
# Model
factoryplanning = Model(HiGHS.Optimizer)

# production of product p in month t
@variable(factoryplanning, x[1:P,1:T] >= 0)
# sale of product p in month t
@variable(factoryplanning, y[1:P,1:T] >= 0)
# storage of product p in THE END of month t
@variable(factoryplanning, s[1:P,1:T] >= 0)


# maximize profit
@objective(factoryplanning, Max,
sum(Profit[p]*y[p,t] for p=1:P, t=1:T) -
sum(StorageCost*s[p,t] for p=1:P, t=1:T))

# machine capacity limit constraint
@constraint(factoryplanning, machine_cap[m=1:M,t=1:T],
sum(ProcessTime[m,p]*x[p,t] for p=1:P) <= (NumMach[m] #=MachineRepairs[m,t]=#)*WorkingHoursPrMonth)
# storage balance constraint
@constraint(factoryplanning, [p=1:P, t=1:T],
s[p,t] == x[p,t] - y[p,t] + (t>1 ? s[p,t-1] : 0) )
# end storage
@constraint(factoryplanning, [p=1:P],
s[p,6] == EndStock)
# max storage
@constraint(factoryplanning, [p=1:P, t=1:T],
s[p,t] <= StorageCap)
# demand limit
@constraint(factoryplanning, [p=1:P, t=1:T],
y[p,t] <= Demand[p,t])
print(factoryplanning)


#************************************************************************
#************************************************************************
# solve
optimize!(factoryplanning)
println("Termination status: $(termination_status(factoryplanning))")
#************************************************************************
#************************************************************************
# Report results
println("-------------------------------------");
if termination_status(factoryplanning) == MOI.OPTIMAL
println("RESULTS:\n")
println("objective = $(objective_value(factoryplanning))")
println("Positive shadowprices for machine capacity constraints:")
for m=1:M
for t=1:T
if shadow_price(machine_cap[m,t])>0
println("Machine \"$(Machines[m])\" in $(Time[t]), : $(shadow_price.(machine