using SimulationService, AlgebraicPetri, DataFrames, DifferentialEquations, ModelingToolkit, Symbolics, EasyModelAnalysis, Catlab, Catlab.CategoricalAlgebra, JSON3, UnPack, SimulationService.SciMLInterface.SciMLOperations
using CSV, DataFrames, JSONTables
using ForwardDiff

_datadir() = joinpath(@__DIR__, "../examples")
_data(s) = joinpath(_datadir(), s)

_logdir() = joinpath(@__DIR__, "logs")
_log(s) = joinpath(_logdir(), s)
mkpath(_logdir())

# NOTE: THIS IS AN OUTDATED MODEL, USE MODEL REPRESENTATION INSTEAD
bn = "BIOMD0000000955_miranet.json"
fn = _data(bn)
T = PropertyLabelledReactionNet{Number,Number,Dict}
TAny = PropertyLabelledReactionNet{Any,Any,Any}

# we should be able to assume that all concentration and rate are set (despite this not being the case for the other 2 Miras from ben)
petri = read_json_acset(T, fn)
ps = string.(tnames(petri)) .=> petri[:rate]
u0 = string.(snames(petri)) .=> petri[:concentration]

params = Dict(ps)
initials = Dict(u0)
tspan = (0.0, 100.0)

nt = (; model=petri, params, initials, tspan)
body = Dict(pairs(nt))
j = JSON3.write(body)
forecast_fn = _log("forecast.json")
write(forecast_fn, j)

df = SimulationService.SciMLInterface.simulate(; nt...)
@test df isa DataFrame

params["t1"] = 0.1
nt = (; model = petri, params, initials, tspan)
df2 = SimulationService.SciMLInterface.simulate(; nt...)

timesteps = df.timestamp
data = Dict(["Susceptible" => df[:, 2]])
fit_args = (; model=petri, params, initials, dataset=df, timesteps_column="timestamp", feature_mappings=Dict("Susceptible(t)"=>"Susceptible"))
fit_body = Dict(pairs(fit_args))
fit_j = JSON3.write(fit_body)
calibrate_fn = _log("calibrate.json")
write(calibrate_fn, fit_j)

fitp = SimulationService.SciMLInterface.calibrate(; fit_args...)
prob = SciMLOperations._to_prob(petri, params, initials, extrema(timesteps))
sys = prob.f.sys

# example of dloss/dp
pkeys = parameters(sys)
pvals = [params[string(x)] for x in pkeys]
data = [states(sys)[1] => df[:, 2]]

l = EasyModelAnalysis.l2loss(pvals, (prob, pkeys, timesteps, data))
ForwardDiff.gradient(p -> EasyModelAnalysis.l2loss(p, (prob, pkeys, timesteps, data)), last.(fitp))
