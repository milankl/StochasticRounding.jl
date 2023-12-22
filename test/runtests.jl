using StochasticRounding
using Test
using DifferentialEquations

import BFloat16s: BFloat16

include("general_tests.jl")
include("conversions.jl")
include("seeding.jl")
include("differential_equations.jl")