using MetaJul
using Dates

# NSGA-II algorithm example configured from the NSGA-II template

function main()
    problem = ZDT1()

    solver::NSGAII = NSGAII(
        problem,
        populationSize = 50, 
        termination = TerminationByComputingTime(Dates.Second(2)),
        crossover = SBXCrossover(probability = 1.0, distributionIndex = 20.0, bounds = problem.bounds),
        mutation = PolynomialMutation(probability = 1.0 / numberOfVariables(problem), distributionIndex = 20.0, bounds = problem.bounds))

    optimize!(solver)

    front = foundSolutions(solver)

    objectivesFileName = "FUN.csv"
    variablesFileName = "VAR.csv"

    println("Algorithm: ", name(solver))

    println("Objectives stored in file ", objectivesFileName)
    printObjectivesToCSVFile(objectivesFileName, front)

    println("Variables stored in file ", variablesFileName)
    printVariablesToCSVFile(variablesFileName, front)
    println("Computing time: ", computingTime(solver))
end