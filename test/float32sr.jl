N = 10000

@testset "1.0 always to 1.0" begin
    for i = 1:N
        @test 1.0f0 == Float32(Float32sr(1.0))
        @test 1.0f0 == Float32(Float32_stochastic_round(1.0))
    end
end

@testset "1+eps/2 is round 50/50 up/down" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32))
    x = 1 + e/2

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 1.0f0 == f
            p1 += 1
        elseif 1 + e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.45
    @test p1/N < 0.55
end

@testset "-1-eps/2 is round 50/50 up/down" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32))
    x = -1 - e/2

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if -1.0f0 == f
            p1 += 1
        elseif -1-e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.45
    @test p1/N < 0.55
end

@testset "1+eps/2 is round 50/50 up/down" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32))
    x = 1 + e/2

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 1.0f0 == f
            p1 += 1
        elseif 1 + e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.45
    @test p1/N < 0.55
end

@testset "1+eps/4 is round 25% up" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32))
    x = 1 + e/4

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 1.0f0 == f
            p1 += 1
        elseif 1 + e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.70
    @test p1/N < 0.80
end

@testset "2+eps/4 is round 25% up" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32))
    x = 2 + e/2

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 2.0f0 == f
            p1 += 1
        elseif 2 + 2e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.70
    @test p1/N < 0.80
end

@testset "powers of 2 are not round" begin

    p1 = 0
    p2 = 0

    for x in Float64[2,4,8,16,32,64,128,256,512,1024]
        for i = 1:100
            @test x == Float32_stochastic_round(x)
        end
    end

    for x in Float64[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256,1/512,1/1024]
        for i = 1:100
            @test x == Float32_stochastic_round(x)
        end
    end
end

@testset "1+eps+eps/8 is round 12.5% up" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32sr))
    x = 1 + e + e/8

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 1.0f0 + e == f
            p1 += 1
        elseif 1 + 2e == f
            p2 += 1
        end
    end
    @test p1+p2 == N
    @test p1/N > 0.825
    @test p1/N < 0.925
end

@testset "1+eps/8 is round 12.5% up" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32sr))
    x = 1 + e/8

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 1.0f0 == f
            p1 += 1
        elseif 1 + e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.825
    @test p1/N < 0.925
end

@testset "-1-eps/8 is round 12.5% away from zero" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32sr))
    x = -1 - e/8

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if -1.0f0 == f
            p1 += 1
        elseif -1-e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p1/N > 0.825
    @test p1/N < 0.925
end

@testset "1+eps/16 is round 6.25% up" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32sr))
    x = 1 + e/16

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 1.0f0 == f
            p1 += 1
        elseif 1 + e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p2/N > 0.05
    @test p2/N < 0.08
end

@testset "2+eps/16 is round 6.25% up" begin

    p1 = 0
    p2 = 0

    e = Float64(eps(Float32sr))
    x = 2 + e/8

    for i = 1:N
        f = Float32(Float32_stochastic_round(x))
        if 2.0f0 == f
            p1 += 1
        elseif 2 + 2e == f
            p2 += 1
        end
    end

    @test p1+p2 == N
    @test p2/N > 0.05
    @test p2/N < 0.08
end

@testset "Stochastic round for subnormals" begin

    ulp_half = Float64(reinterpret(Float32,0x0000_0001))/2

    for hex in 0x0000_0001:0x0000_0ffe:0x007f_ffff    # test for some subnormals of Float32

        # add ulp/2 to have stochastic rounding that is 50/50 up/down.
        x = Float64(reinterpret(Float32,hex)) + ulp_half

        p1 = 0
        p2 = 0

        for i = 1:N
            f = Float32(Float32_stochastic_round(x))
            if f >= x
                p1 += 1
            else
                p2 += 1
            end
        end

        @test p1+p2 == N
        @test p1/N > 0.45
        @test p1/N < 0.55
    end
end

@testset "NaN and Inf" begin
    @test isnan(NaN32sr)
    @test ~isfinite(NaN32sr)
    @test ~isfinite(Inf32sr)
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

# Due to the gradual transition to round to nearest in the subnormals, these
# tests currently would fail
@testset "Some other subnormals" begin
    for scale in [2,4,8,16,32]
        for frac in [4,8,16]
            f64 = Float64(floatmin(Float32))/scale+eps(floatmin(Float32))/Float64(frac)
            f32_rounddown = Float32sr(f64)
            f32_roundup = nextfloat(f32_rounddown)

            N = 100_000
            p_down = 0
            p_up = 0 
            for _ in 1:N
                f = Float32_stochastic_round(f64)
                if f == f32_rounddown
                    p_down += 1
                elseif f == f32_roundup
                    p_up += 1
                end
            end

            @test_skip p_down + p_up == N
            @test_skip isapprox(p_down/N,1-1/frac,rtol=5e-2)
            @test_skip isapprox(p_up/N,1/frac,rtol=5e-2)
        end
    end
end