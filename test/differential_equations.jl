@testset "Successful run with DE.jl" begin
    for SR in [Float32sr, Float16sr, BFloat16sr]
        f = (u,p,t) -> (p*u)
        prob_ode_linear = ODEProblem(f,SR(1.0)/SR(2.0),(SR(0.0),SR(1.0)),SR(1.01));
        sol = solve(prob_ode_linear,Tsit5())  
        @test eltype(sol) == SR
    end
end