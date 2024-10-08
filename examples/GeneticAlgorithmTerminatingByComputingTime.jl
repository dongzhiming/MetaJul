using MetaJul
using Dates

# Genetic algorithm example applied to problem Sphere
function main()
    problem = sphere(100)

    solver::EvolutionaryAlgorithm = EvolutionaryAlgorithm()
    solver.name = "GA"

    populationSize = 100
    offspringPopulationSize = 100

    solver.solutionsCreation = DefaultSolutionsCreation(problem, populationSize)

    solver.evaluation = SequentialEvaluation(problem)

    solver.termination = TerminationByComputingTime(Dates.Millisecond(6000))

    mutation = PolynomialMutation(probability = 1.0 / numberOfVariables(problem), distributionIndex = 20.0, bounds = problem.bounds)
    """
    solver.crossover = BLXAlphaCrossover(probability=1.0, alpha=0.5, bounds=problem.bounds)
    """
    crossover = SBXCrossover(probability = 1.0, distributionIndex = 20.0, bounds = problem.bounds)
    solver.variation = CrossoverAndMutationVariation(offspringPopulationSize, crossover, mutation)

    solver.selection = BinaryTournamentSelection(solver.variation.matingPoolSize, IthObjectiveComparator(1))

    solver.replacement = MuPlusLambdaReplacement(IthObjectiveComparator(1))

    optimize!(solver)

    foundSolutions = solver.foundSolutions

    println("Algorithm: ", name(solver))

    printObjectivesToCSVFile("FUN.csv", [foundSolutions[1]])
    printVariablesToCSVFile("VAR.csv", [foundSolutions[1]])

    println("Best solution found: ", foundSolutions[1].objectives[1])
    println("Computing time: ", computingTime(solver))
end