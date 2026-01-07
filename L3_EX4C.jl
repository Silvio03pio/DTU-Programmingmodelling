#stamp-Bid 
using JuMP
using HiGHS

EX = Model(HiGHS.Optimizer)
set_silent(EX)

#Data & indexes
N = 1:100 #stamps
I = 1:213 #Bid

#variables
@variable(EX, x[n in N, i in I], Bin)


#FO
@objective(EX, Max, sum(BidPrice[i] * x[i] for i in I))

#constraint
@constraint(EX, once_sold[n in N], sum(x[n,i] for i in I) <= 1)

