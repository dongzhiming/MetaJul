include("../src/bounds.jl")
include("../src/solution.jl")
include("../src/operator.jl")
include("../src/binaryProblem.jl")
include("../src/algorithm.jl")
include("../src/component.jl")
include("../src/utils.jl")

using Dates

# Genetic algorithm example applied to problem OneMax
problem = oneMax(512)

solver::EvolutionaryAlgorithm = EvolutionaryAlgorithm()
solver.problem = problem
solver.populationSize = 100
solver.offspringPopulationSize = 100

solver.solutionsCreation = DefaultSolutionsCreation((problem = solver.problem, numberOfSolutionsToCreate = solver.populationSize))

solver.evaluation = SequentialEvaluation((problem = solver.problem, ))

solver.termination = terminationByEvaluations
solver.terminationParameters = (numberOfEvaluationToStop = 40000, )

solver.selection = BinaryTournamentSelection((matingPoolSize = 100, comparator = compareIthObjective))

mutation = BitFlipMutation((probability=1.0/numberOfVariables(problem),))
crossover = SinglePointCrossover((probability=1.0,))
solver.variation = CrossoverAndMutationVariation((offspringPopulationSize = solver.offspringPopulationSize, crossover = crossover, mutation = mutation))

solver.replacement = muPlusLambdaReplacement
solver.replacementParameters = (comparator = compareIthObjective, )

startingTime = Dates.now()
optimize(solver)
endTime = Dates.now()

foundSolutions = solver.foundSolutions

printObjectivesToCSVFile("FUN.csv", [foundSolutions[1]])
printVariablesToCSVFile("VAR.csv", [foundSolutions[1]])

println("Fitness: ", -1.0 * foundSolutions[1].objectives[1])
println("Solution: ", foundSolutions[1].variables)
println("Computing time: ", (endTime - startingTime))
