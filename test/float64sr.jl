using DoubleFloats

function test_chances_round(f128::Double64;N::Int=100_000)
    p = Float64_chance_roundup(f128)

    f64_round = Float64sr(f128)
    if Double64(f64_round) == f128
        f64_roundup = f64_round
        f64_rounddown = f64_round
    elseif Double64(f64_round) < f128
        f64_rounddown = f64_round
        f64_roundup = nextfloat(f64_round)
    else
        f64_roundup = f64_round
        f64_rounddown = prevfloat(f64_round)
    end

    Ndown = 0
    Nup = 0 
    for _ in 1:N
        f64 = Float64_stochastic_round(f128)
        if f64 == f64_rounddown
            Ndown += 1
        elseif f64 == f64_roundup
            Nup += 1
        end
    end

    test1 = Ndown + Nup == N
    test2 = isapprox(Ndown/N,1-p,atol=1e-2)
    test3 = isapprox(Nup/N,p,atol=1e-2)
    
    return test1 && test2 && test3
end

@testset "Test for N(0,1)" begin
    for x in randn(Double64,10_000)
        @test test_chances_round(x)
    end
end

@testset "Test for U(0,1)" begin
    for x in rand(Double64,10_000)
        @test test_chances_round(x)
    end
end