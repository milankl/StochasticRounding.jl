using StochasticRounding
using Test
using DifferentialEquations


import BFloat16s: BFloat16

include("bfloat16sr.jl")
include("float16sr.jl")
include("float32sr.jl")
include("conversions.jl")
include("seeding.jl")
include("differential_equations.jl")