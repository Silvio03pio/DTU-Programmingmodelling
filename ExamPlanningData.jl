E=12 # No of exams
R=3 # No of rooms
T=4 # No of timeslots

# No of students in each exam
ExamStudents=[ 40 97 100 18 73 55 96 82 82 55 38 93] 

# No of students who can take an exam in this room in
# one timeslot (number of seats of seats)
RoomCap=[ 96 88 190] 

# Cost of using a room in a timeslot:
# RoomCost[r,t], i.e. RoomCost[2,3]=3491
RoomCost=[
 3510  3563  3511  3582 ;
 3473  3420  3491  3550 ;
 5407  5464  5522  5463 ]

# Extra penalty having exam e in room r:
# ExamTimeslotPenalty[E,T], i.e. ExamTimeslotPenalty[3,2]=89
ExamTimeslotPenalty=[
 87  20  30  84 ;
 43  43  47  50 ;
 96  89  48  48 ;
 83  48  90  82 ;
 66  76  71  38 ;
 75  57  62  56 ;
 26  24  52  67 ;
 90  58  15  63 ;
 52  85  80  12 ;
 11  82  57  89 ;
 40  38  58  56 ;
 18  13  37  75 ]

# ExamRoomPenalty[E,R], penalty for having exam e in room r:
# ExamRoomPenalty[2,3]=37
ExamRoomPenalty=[
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ;
 96  97  37 ]

# Incidence[E,E] matrix:
# Collision[e1,e2]=0 means that exam e1 and exam e2
# cannot take place in the same timeslot
Collision=[
 1  0  1  0  1  0  0  0  0  1  1  0 ;
 0  1  1  0  1  1  1  1  1  0  0  0 ;
 1  1  1  1  1  0  0  0  1  0  1  0 ;
 0  0  1  1  0  1  0  1  1  1  1  1 ;
 1  1  1  0  1  1  0  1  0  0  1  1 ;
 0  1  0  1  1  1  1  0  1  1  0  1 ;
 0  1  0  0  0  1  1  0  0  1  0  1 ;
 0  1  0  1  1  0  0  1  0  1  0  1 ;
 0  1  1  1  0  1  0  0  1  0  1  1 ;
 1  0  0  1  0  1  1  1  0  1  0  0 ;
 1  0  1  1  1  0  0  0  1  0  1  1 ;
 0  0  0  1  1  1  1  1  1  0  1  1 ]


# exam assigment 1
using JuMP
using Gurobi

m = Model(Gurobi.Optimizer)

# 1) variable, 1 if exam e goes to room  r at time t, 0 otherways
@variable(m, x[e=1:E,r=1:R,t=1:T],Bin)

# 2) variable, 1 if room r is used a time t, 0 otherways
@variable(m, y[r=1:R, t=1:T], Bin)

# objective function
@objective(m, Min, sum( RoomCost[r,t]*y[r,t] for r=1:R,t=1:T) +
sum( ExamTimeslotPenalty[e,t]*x[e,r,t] for e=1:E,r=1:R,t=1:T ) +
sum( ExamRoomPenalty[e,r]*x[e,r,t] for e=1:E,r=1:R,t=1:T ) )

# 1) constraint, each exam has to be done in one room at one time slot.
@constraint(m, examdone[e=1:E], sum(x[e,r,t] for t=1:T,r=1:R) == 1 )

# 2) constraint, max capacity per room 
@constraint(m, maxcapacity[r=1:R,t=1:T], sum(x[e,r,t]*ExamStudents[e] for e=1:E) <= RoomCap[r] * y[r,t])

# 3) constraint, No double exams
@constraint(m, [e1=1:E,e2=1:E,t=1:T;e1<e2], sum( x[e1,r,t] for r=1:R) + sum( x[e2,r,t] for r=1:R))

# solve
optimize!(m)
println("Termination status: $(termination_status(m))")
println("Primal status:      $(primal_status(m))")
if has_values(m)
    println("Objective value:    $(objective_value(m))")
end

#************************************************************************