# Struct and methods to implement the non-dominated ranking sorting method

mutable struct DominanceRanking <: Ranking
    ranks::Vector
    dominanceComparator::Comparator
end

function DominanceRanking(dominanceComparator::Comparator)
    DominanceRanking(Vector{Vector}(undef, 0), dominanceComparator)
end

function DominanceRanking()
    return DominanceRanking(DefaultDominanceComparator())
end

function getSubFront(ranking::DominanceRanking, rankId::Integer)
    message = string("The subfront id ", rankId, " is not in the range 1:", length(ranking.ranks))
    @assert length(ranking.ranks) >= rankId message
    return ranking.ranks[rankId]
end

function numberOfRanks(ranking::DominanceRanking)::Int
    return length(ranking.ranks)
end

function appendRank!(ranking::DominanceRanking, newRank::Vector{T}) where {T<:Solution}
    push!(ranking.ranks, newRank)
    return Nothing
end

function getRank(solution::Solution)
    return get(solution.attributes, "RANKING_ATTRIBUTE", 0)
end

function setRank(solution::Solution, rank::Int)
    return solution.attributes["RANKING_ATTRIBUTE"] = rank
end

struct DominanceRankingComparator <: Comparator end

function compare(comparator::DominanceRankingComparator, solution1::Solution, solution2::Solution)
    result = 0
    if getRank(solution1) < getRank(solution2)
        result = -1
    elseif getRank(solution1) > getRank(solution2)
        result = 1
    end

    return result
end

function compute!(ranking::DominanceRanking, solutions::Array{T}) where {T<:Solution}
    ranking.ranks = []
    solutionsToRank = [solution for solution in solutions]
    rankCounter = 1

    while length(solutionsToRank) > 0
        nonDominatedArchive = NonDominatedArchive(T[], ranking.dominanceComparator)
        for (index, solution) in enumerate(solutionsToRank)
            solution.attributes["INDEX"] = index
            add!(nonDominatedArchive, solution)
        end

        counterOfDeletedSolutions = 0
        for solution in nonDominatedArchive.solutions
            setRank(solution, rankCounter)
            deleteat!(solutionsToRank, solution.attributes["INDEX"] - counterOfDeletedSolutions)
            counterOfDeletedSolutions += 1
        end

        appendRank!(ranking, nonDominatedArchive.solutions)

        rankCounter += 1
    end
end

function dominates(a::Solution, b::Solution)
    all(a.objectives .<= b.objectives) && any(a.objectives .< b.objectives)
end

function compute2!(ranking::DominanceRanking, solutions::Array{T}) where {T<:Solution}
    # dominateMe[i] contains the number of individuals dominating i
    dominateMe = zeros(Int, length(solutions))

    # iDominate[k] contains the list of individuals dominated by k
    iDominate = [Int[] for _ in 1:length(solutions)]

    # front[i] contains the list of individuals belonging to the front i
    front = [Int[] for _ in 1:(length(solutions)+1)]

    for p in 1:length(solutions)
        # Initialize the list of individuals that i dominate and the number
        # of individuals that dominate me
        iDominate[p] = Int[]
        dominateMe[p] = 0
    end

    for p in 1:(length(solutions)-1)
        # For all q individuals , calculate if p dominates q or vice versa
        for q in (p+1):length(solutions)
            flagDominate = compare(ranking.dominanceComparator, solutions[p], solutions[q])

            if flagDominate == -1
                push!(iDominate[p], q)
                dominateMe[q] += 1
            elseif flagDominate == 1
                push!(iDominate[q], p)
                dominateMe[p] += 1
            end
        end
    end

    for i in 1:length(solutions)
        if dominateMe[i] == 0
            push!(front[1], i)
            setRank(solutions[i], 1)
        end
    end

    # Obtain the rest of fronts
    i = 1
    while !isempty(front[i])
        i += 1
        for p in front[i-1]
            for q in iDominate[p]
                dominateMe[q] -= 1
                if dominateMe[q] == 0
                    push!(front[i], q)
                    setRank(solutions[q], i)
                end
            end
        end
    end

    ranked_sub_populations = Vector{Vector{T}}(undef, i - 1)
    for j in 1:(i-1)
        ranked_sub_populations[j] = Vector{T}(undef, length(front[j]))
        for k in 1:length(front[j])
            ranked_sub_populations[j][k] = solutions[front[j][k]]
        end
    end

    ranking.ranks = ranked_sub_populations
end


"""
function compute2!(ranking::DominanceRanking, solutions::Array{T}) where {T<:Solution}
    ranking.ranks = []

    num_solutions = length(solutions)
    domination_counts = zeros(Int, num_solutions)
    dominated_solutions = [Int[] for _ in 1:num_solutions]
    ranks = zeros(Int, num_solutions)

    # Step 1: Determine dominance relationships
    for i in 1:num_solutions
        for j in 1:num_solutions
            if i != j
                if dominates(solutions[i], solutions[j])
                    push!(dominated_solutions[i], j)
                elseif dominates(solutions[j], solutions[i])
                    domination_counts[i] += 1
                end
            end
        end
    end

    # Step 2: Assign initial ranks
    front = Int[]
    currentSolutionsRank = []
    for i in 1:num_solutions
        if domination_counts[i] == 0
            ranks[i] = 1
            push!(front, i)
            push!(currentSolutionsRank, solutions[i])
        end
    end

    println("RANK: ", typeof(currentSolutionsRank))

    appendRank!(ranking, currentSolutionsRank)

    # Step 3: Assign ranks iteratively
    current_rank = 1
    while !isempty(front)
        next_front = Int[]
        nextSolutionsRank = T[]
        for i in front
            for j in dominated_solutions[i]
                domination_counts[j] -= 1
                if domination_counts[j] == 0
                    ranks[j] = current_rank + 1
                    push!(next_front, j)
                    push!(nextSolutionsRank, solutions[j])
                end
            end
        end
        appendRank!(ranking, nextSolutionsRank)
        front = next_front
        current_rank += 1
    end

    # Set ranks in the attributes of solutions
    for i in 1:num_solutions
        setRank(solutions[i], ranks[i])
    end
end


function compute2!(ranking::DominanceRanking, solutions::Array{T}) where {T<:Solution}
    ranking.ranks = []
    # Loop through each individual in the population
    for i in 1:length(solutions)
        # Initialize dominance count for current individual
        dominated_by = 0

        # Loop through all other individuals
        for j in 1:length(solutions)
            # Skip comparing the same individual
            if i != j
                # Check if individual i dominates individual j
                if all(solutions[i].objectives .< solutions[j].objectives)
                    # If dominated, increment dominance count
                    dominated_by += 1
                end
            end
        end

        # If not dominated by anyone, assign rank 1
        if dominated_by == 0
            push!(ranking.ranks, 1)
            setRank(solutions[i], 1)
        else
            # Find minimum rank of individuals dominating i
            min_rank = minimum(ranking.ranks[find(solutions .== (solutions[i]))])
            # Assign rank 1 higher than the minimum dominating rank
            push!(ranking.ranks, min_rank + 1)
            setRank(solutions[i], min_rank + 1)
        end
    end

    # Return the calculated ranks
    return ranks
end
"""