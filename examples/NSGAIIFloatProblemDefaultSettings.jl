using MetaJul

using Dates

# NSGA-II algorithm example configured from the NSGA-II template

function main()
    problem = ZDT1()

    solver::NSGAII = NSGAII(problem)

    startingTime = Dates.now()
    optimize(solver)
    endTime = Dates.now()

    front = foundSolutions(solver)

    objectivesFileName = "FUN.csv"
    variablesFileName = "VAR.csv"

    println("Algorithm: ", name(solver))

    println("Objectives stored in file ", objectivesFileName)
    printObjectivesToCSVFile(objectivesFileName, front)

    println("Variables stored in file ", variablesFileName)
    printVariablesToCSVFile(variablesFileName, front)
    println("Computing time: ", (endTime - startingTime))
end