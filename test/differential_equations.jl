@testset "Successful run with DE.jl" begin
    f = (u,p,t) -> (p*u)
    prob_ode_linear = ODEProblem(f,Float32sr(1.0)/Float32sr(2.0),(Float32sr(0.0),Float32sr(1.0)),Float32sr(1.01));
    sol =solve(prob_ode_linear,Tsit5())  
end