using StochasticRounding
using Test
using DifferentialEquations



@testset "Successful run with DE.jl" begin
    try
        f = (u,p,t) -> (p*u)
        prob_ode_linear = ODEProblem(f,Float32sr(1.0)/Float32sr(2.0),(Float32sr(0.0),Float32sr(1.0)),Float32sr(1.01));
        sol =solve(prob_ode_linear,Tsit5())
        @test true # The default completes without any errors 
    catch e
        @test  false
    end
end