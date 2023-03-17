# Architecture

The `simulation-service` handles simulation blocks from the TERArium workflow view. The API performs the following operations on a submitted job:
1. Validate
1. Generate
1. Execute
1. Cache

## Validating
When a job is submitted, we have to ensure the prerequisite inputs have been generated by previous jobs. For example, we cannot `forecast` without a `select_model`'s job existing in the cache. If all the inputs are the same, the cached result is returned instead of running through the rest of the operations.

## Generating
From the job payload, a corresponding `block.jl` file is generated from a hydrated [EasyModelAnalysis](https://github.com/SciML/EasyModelAnalysis.jl) template.

## Executing
A Julia session (eventually an Executor API?) will run the generated code.

## Caching
The resulting [JLD.jl](https://github.com/JuliaIO/JLD.jl) object will be saved to some kind of shared state.