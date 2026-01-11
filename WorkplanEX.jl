#************************************************************************
# Workplan Teaching Assistant Assignment question 2,
# "Mathematical Programming Modelling" (42112)
using JuMP
using HiGHS
#************************************************************************
#************************************************************************
# PARAMETERS
include(joinpath(@__DIR__, "WorkplanData.jl"))

#************************************************************************
#************************************************************************
# Model
taworkplan = Model(HiGHS.Optimizer)

# 1 if ta is working oin time period p on day d
@variable(taworkplan, x[ta=1:TA,p=1:P,d=1:D],Bin)
# 1 if ta STARTS working in period p on day d
@variable(taworkplan, y[ta=1:TA,p=1:P,d=1:D],Bin)

# Minimize summed Inconvenience
@objective(taworkplan, Min,
    sum( Inconvenience[ta,p,d]*x[ta,p,d] for ta=1:TA,p=1:P,d=1:D))

# satisfy demand for TAs
@constraint(taworkplan, [p=1:P,d=1:D],
    sum( x[ta,p,d] for ta=1:TA) >= Demand[p,d])

# each TA should work exactly 52 hours
@constraint(taworkplan, [ta=1:TA],
    sum( x[ta,p,d] for p=1:P,d=1:D) == 52)

# only start working once a day
@constraint(taworkplan, [ta=1:TA,d=1:D], sum( y[ta,p,d] for p=1:P) <= 1 )

# require connected work plans
@constraint(taworkplan, [ta=1:TA,d=1:D,p=1:P],x[ta,p,d] <= (p>1 ? x[ta,p-1,d] : 0) + y[ta,p,d])

# at least 2 hours of work pr. day if working that day
@constraint(taworkplan, [ta=1:TA,d=1:D],sum( x[ta,p,d] for p=1:P) >= 2*sum( y[ta,p,d] for p=1:P) )

#************************************************************************
#************************************************************************
# solve
optimize!(taworkplan)
println("Termination status: $(termination_status(taworkplan))")
println("Primal status:      $(primal_status(taworkplan))")
if has_values(taworkplan)
    println("Objective value:    $(objective_value(taworkplan))")
end

#************************************************************************