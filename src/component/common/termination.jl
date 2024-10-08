struct TerminationByEvaluations <: Termination
    numberOfEvaluationsToStop::Int
end


function isMet(termination::TerminationByEvaluations, algorithmAttributes::Dict)::Bool
    return get(algorithmAttributes, "EVALUATIONS", 0) >= termination.numberOfEvaluationsToStop
end

struct TerminationByComputingTime <: Termination
    computingTimeLimit
end

function isMet(termination::TerminationByComputingTime, algorithmAttributes::Dict)::Bool
    return get(algorithmAttributes, "COMPUTING_TIME", 0) >= termination.computingTimeLimit
end

struct TerminationByIterations <: Termination
    maximumNumberOfIterations
end

function isMet(termination::TerminationByIterations, algorithmAttributes::Dict)::Bool
    return get(algorithmAttributes, "ITERATIONS", 0) >= termination.maximumNumberOfIterations
end

