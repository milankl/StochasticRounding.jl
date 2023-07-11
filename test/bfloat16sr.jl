@testset "Sign flip" begin
    @test one(BFloat16sr) == -(-(one(BFloat16sr)))
    @test zero(BFloat16sr) == -(zero(BFloat16sr))
end

@testset "Integer promotion" begin
    f = BFloat16sr(1)
    @test 2f == BFloat16sr(2)
    @test 0f == BFloat16sr(0)
end

@testset "NaN and Inf" begin
    @test isnan(NaNB16sr)
    @test ~isfinite(NaNB16sr)
    @test ~isfinite(InfB16sr)

    N = 1000
    for i in 1:N
        @test InfB16sr == BFloat16_stochastic_round(Inf32)
        @test -InfB16sr == BFloat16_stochastic_round(-Inf32)
        @test isnan(BFloat16_stochastic_round(NaN32))
    end
end

@testset "No stochastic round to NaN" begin
    f1 = nextfloat(0f0)
    f2 = prevfloat(0f0)
    for i in 1:100
        @test isfinite(BFloat16_stochastic_round(f1))
        @test isfinite(BFloat16_stochastic_round(f2))
    end
end

@testset "Odd floats are never round away" begin
    N = 100_000 

    f_odd = prevfloat(one(BFloat16sr))
    f_odd_f32 = Float32(f_odd)
    for _ = 1:N
        @test f_odd == BFloat16sr(f_odd_f32)
        @test f_odd == BFloat16_stochastic_round(f_odd_f32)
    end
end

@testset "Even floats are never round away" begin
    N = 100_000 

    f_odd = prevfloat(prevfloat(one(BFloat16sr)))
    f_odd_f32 = Float32(f_odd)
    for _ = 1:N
        @test f_odd == BFloat16sr(f_odd_f32)
        @test f_odd == BFloat16_stochastic_round(f_odd_f32)
    end
end

@testset "Rounding" begin
    @test 1 == Int(round(BFloat16sr(1.2)))
    @test 1 == Int(floor(BFloat16sr(1.2)))
    @test 2 == Int(ceil(BFloat16sr(1.2)))

    @test -1 == Int(round(BFloat16sr(-1.2)))
    @test -2 == Int(floor(BFloat16sr(-1.2)))
    @test -1 == Int(ceil(BFloat16sr(-1.2)))
end

@testset "Nextfloat prevfloat" begin
    o = one(BFloat16sr)
    @test o == nextfloat(prevfloat(o))
    @test o == prevfloat(nextfloat(o))
end

@testset "Comparisons" begin
    @test BFloat16sr(1)   <  BFloat16sr(2)
    @test BFloat16sr(1f0) <  BFloat16sr(2f0)
    @test BFloat16sr(1.0) <  BFloat16sr(2.0)
    @test BFloat16sr(1)   <= BFloat16sr(2)
    @test BFloat16sr(1f0) <= BFloat16sr(2f0)
    @test BFloat16sr(1.0) <= BFloat16sr(2.0)
    @test BFloat16sr(2)   >  BFloat16sr(1)
    @test BFloat16sr(2f0) >  BFloat16sr(1f0)
    @test BFloat16sr(2)   >= BFloat16sr(1)
    @test BFloat16sr(2f0) >= BFloat16sr(1f0)
    @test BFloat16sr(2.0) >= BFloat16sr(1.0)
end

@testset "1.0 always to 1.0" begin
    for i = 1:10000
        @test 1.0f0 == Float32(BFloat16sr(1.0f0))
        @test 1.0f0 == Float32(BFloat16_stochastic_round(1.0f0))
    end
end

function test_chances_round_bf16(f32::Float32;N::Int=100_000)
    p = BFloat16_chance_roundup(f32)

    f16_round = BFloat16sr(f32)
    if Float32(f16_round) <= f32
        f16_rounddown = f16_round
        f16_roundup = nextfloat(f16_round)
    else
        f16_roundup = f16_round
        f16_rounddown = prevfloat(f16_round)
    end

    Ndown = 0
    Nup = 0 
    for _ in 1:N
        f16 = BFloat16_stochastic_round(f32)
        if f16 == f16_rounddown
            Ndown += 1
        elseif f16 == f16_roundup
            Nup += 1
        end
    end
    
    return Ndown,Nup,N,p
end

@testset "Test for N(0,1)" begin
    for x in randn(Float32,10_000)
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end
end

@testset "Test for U(0,1)" begin
    for x in rand(Float32,10_000)
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end
end

@testset "Test for powers of two" begin
    for x in Float32[2,4,8,16,32,64,128,256]
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in -Float32[2,4,8,16,32,64,128,256]
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in Float32[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256]
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in -Float32[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256]
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end
end

@testset "Test for subnormals" begin

    floatminBF16 = reinterpret(UInt32,Float32(floatmin(BFloat16sr)))
    minposBF16 = reinterpret(UInt32,Float32(nextfloat(zero(BFloat16sr))))

    N = 10_000
    subnormals = reinterpret.(Float32,rand(minposBF16:floatminBF16,N))
    for x in subnormals
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in -subnormals
        Ndown,Nup,N,p = test_chances_round_bf16(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end
end
