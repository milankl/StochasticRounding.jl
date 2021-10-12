@testset "1.0 always to 1.0" begin
    N = 10000

    for i = 1:N
        @test 1.0f0 == Float32(Float32sr(1.0))
        @test 1.0f0 == Float32(Float32_stochastic_round(1.0))
    end
end

@testset "Odd floats are never round away" begin
    # chances are 2^-28 = 4e-9
    # so technically one should use N > 100_000_000 but takes too long
    N = 100_000 

    f_odd = prevfloat(one(Float32sr))
    f_odd_f64 = Float64(f_odd)
    for _ = 1:N
        @test f_odd == Float32sr(f_odd_f64)
        @test f_odd == Float32_stochastic_round(f_odd_f64)
    end
end

@testset "Even floats are never round away" begin
    # chances are 2^-28 = 4e-9
    # so technically one should use N > 100_000_000 but takes too long
    N = 100_000 

    f_odd = prevfloat(prevfloat(one(Float32sr)))
    f_odd_f64 = Float64(f_odd)
    for _ = 1:N
        @test f_odd == Float32sr(f_odd_f64)
        @test f_odd == Float32_stochastic_round(f_odd_f64)
    end
end

@testset "Sign flip" begin
    @test one(Float32sr) == -(-(one(Float32sr)))
    @test zero(Float32sr) == -(zero(Float32sr))
end

@testset "Integer promotion" begin
    f = Float32sr(1)
    @test 2f == Float32sr(2)
    @test 0 == Float32sr(0)
end

@testset "Rounding" begin
    @test 1 == Int(round(Float32sr(1.2)))
    @test 1 == Int(floor(Float32sr(1.2)))
    @test 2 == Int(ceil(Float32sr(1.2)))

    @test -1 == Int(round(Float32sr(-1.2)))
    @test -2 == Int(floor(Float32sr(-1.2)))
    @test -1 == Int(ceil(Float32sr(-1.2)))
end

@testset "Nextfloat prevfloat" begin
    o = one(Float32sr)
    @test o == nextfloat(prevfloat(o))
    @test o == prevfloat(nextfloat(o))
end

@testset "Comparisons" begin
    @test Float32sr(1f0) <  Float32sr(2f0)
    @test Float32sr(1)   <  Float32sr(2)
    @test Float32sr(1.0) <  Float32sr(2.0)
    @test Float32sr(1)   <= Float32sr(2)
    @test Float32sr(1f0) <= Float32sr(2f0)
    @test Float32sr(1.0) <= Float32sr(2.0)
    @test Float32sr(2)   >  Float32sr(1)
    @test Float32sr(2f0) >  Float32sr(1f0)
    @test Float32sr(2)   >= Float32sr(1)
    @test Float32sr(2f0) >= Float32sr(1f0)
    @test Float32sr(2.0) >= Float32sr(1.0)
end

@testset "NaN and Inf" begin
    @test isnan(NaN32sr)
    @test ~isfinite(NaN32sr)
    @test ~isfinite(Inf32sr)
    @test isnan(Float32_stochastic_round(NaN))
    @test Inf32 == Float32(Float32_stochastic_round(Inf))
    @test -Inf32 == Float32(Float32_stochastic_round(-Inf))

    N = 1000
    for i in 1:N
        @test Inf32sr == Float32_stochastic_round(Inf)
        @test -Inf32sr == Float32_stochastic_round(-Inf)
        @test isnan(Float32_stochastic_round(NaN))
    end
end

@testset "No stochastic round to NaN" begin
    f1 = nextfloat(0.0)
    f2 = prevfloat(0.0)
    for i in 1:1000
        @test isfinite(Float32_stochastic_round(f1))
        @test isfinite(Float32_stochastic_round(f2))
    end
end

@testset "No stochastic round to NaN" begin
    f1 = Float64(floatmax(Float32))   # larger can map to Inf though!
    f2 = -f1
    for i in 1:1000
        @test isfinite(Float32_stochastic_round(f1))
        @test isfinite(Float32_stochastic_round(f2))
    end
end

function test_chances_round(f64::Float64;N::Int=100_000)
    p = Float32_chance_roundup(f64)

    f32_round = Float32sr(f64)
    if Float64(f32_round) <= f64
        f32_rounddown = f32_round
        f32_roundup = nextfloat(f32_round)
    else
        f32_roundup = f32_round
        f32_rounddown = prevfloat(f32_round)
    end

    Ndown = 0
    Nup = 0 
    for _ in 1:N
        f32 = Float32_stochastic_round(f64)
        if f32 == f32_rounddown
            Ndown += 1
        elseif f32 == f32_roundup
            Nup += 1
        end
    end

    test1 = Ndown + Nup == N
    test2 = isapprox(Ndown/N,1-p,atol=1e-2)
    test3 = isapprox(Nup/N,p,atol=1e-2)
    
    return test1 && test2 && test3
end

@testset "Test for N(0,1)" begin
    for x in randn(10_000)
        @test test_chances_round(x)
    end
end

@testset "Test for U(0,1)" begin
    for x in rand(10_000)
        @test test_chances_round(x)
    end
end

@testset "Test for powers of two" begin
    for x in Float64[2,4,8,16,32,64,128,256]
        @test test_chances_round(x)
    end

    for x in -Float64[2,4,8,16,32,64,128,256]
        @test test_chances_round(x)
    end

    for x in Float64[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256]
        @test test_chances_round(x)
    end

    for x in -Float64[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256]
        @test test_chances_round(x)
    end
end

@testset "Test for subnormals" begin

    floatminF32 = reinterpret(UInt64,Float64(floatmin(Float32)))
    minposF32 = reinterpret(UInt64,Float64(nextfloat(zero(Float32))))

    N = 100
    subnormals = reinterpret.(Float64,rand(minposF32:floatminF32,N))
    for x in subnormals
        @test test_chances_round(x)
    end

    for x in -subnormals
        @test test_chances_round(x)
    end
end