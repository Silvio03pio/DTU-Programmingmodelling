#Young couple
using JuMP
using HiGHS

EX = Model(HiGHS.Optimizer)
set_silent(EX)

#Data & indexes
I = 1:4 # task
J = 1:2 # person
c = [       # matrix, hours to complete a task i by a person j 
    4.5 7.8 3.6 2.9 ;
    4.9 7.2 4.3 3.1 ;
]

#variables
@variable(EX, 0 <= x[j in J, i in I] <= 1)


#Objective FUNCTION
@objective(EX, Min, sum(c[j,i]*x[j,i] for j in J, i in I))

#constraints
@constraint(EX, task_to_person[i in I], sum(x[j,i] for j in J) == 1) # each task has to be assigned to one person
# @constraint(EX, person_to_task[j in J], sum(x[j,i] for i in I) == 1) # each person has to be assigne to one task
@constraint(EX, person_two_tasks[j in J], sum(x[j,i] for i in I) == 2) # every person has to have 2 task



# optimize
optimize!(EX)    
println("\n===== RESULTS =====")
println("Objective value: ", objective_value(EX))
println("Primal status: ", primal_status(EX))

using Printf

println("===== ASSIGNMENTS =====")
for i in I
    j_best = argmax([value(x[j,i]) for j in J])
    println("Task ", i, " -> Person ", j_best)
end


