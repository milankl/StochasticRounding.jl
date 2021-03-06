@testset "Sign flip" begin
    @test one(FastFloat16sr) == -(-(one(FastFloat16sr)))
    @test zero(FastFloat16sr) == -(zero(FastFloat16sr))
end

@testset "NaN and Inf" begin
    @test isnan(NaN16sr)
    @test ~isfinite(NaN16sr)
    @test ~isfinite(Inf16sr)
end

@testset "No stochastic round to NaN" begin
    f1 = nextfloat(0f0)
    f2 = prevfloat(0f0)
    for i in 1:100
        @test isfinite(FastFloat16_stochastic_round(f1))
        @test isfinite(FastFloat16_stochastic_round(f2))
    end
end

@testset "Integer promotion" begin
    f = FastFloat16sr(1)
    @test 2f == FastFloat16sr(2)
    @test 0 == FastFloat16sr(0)
end

@testset "Rounding" begin
    @test 1 == Int(round(FastFloat16sr(1.2)))
    @test 1 == Int(floor(FastFloat16sr(1.2)))
    @test 2 == Int(ceil(FastFloat16sr(1.2)))

    @test -1 == Int(round(FastFloat16sr(-1.2)))
    @test -2 == Int(floor(FastFloat16sr(-1.2)))
    @test -1 == Int(ceil(FastFloat16sr(-1.2)))
end

@testset "Nextfloat prevfloat" begin
    o = one(FastFloat16sr)
    @test o == nextfloat(prevfloat(o))
    @test o == prevfloat(nextfloat(o))
end

@testset "Deterministic conversion float" begin
    fs = [1.0,2.5,10.0,0.0,-0.25,-5.0]

    for f in fs
        @test f == Float64(FastFloat16sr(f))
        @test Float32(f) == Float32(FastFloat16sr(f))
        @test Float16(f) == Float16(FastFloat16sr(f))
    end
end

@testset "Deterministic conversion int" begin
    fs = [-5,-1,0,-0,1,2]

    for f in fs
        @test f == Int64(FastFloat16sr(f))
        @test Int32(f) == Int32(FastFloat16sr(f))
        @test Int16(f) == Int16(FastFloat16sr(f))
    end
end

@testset "Comparisons" begin
    @test FastFloat16sr(1)   <  FastFloat16sr(2)
    @test FastFloat16sr(1f0) <  FastFloat16sr(2f0)
    @test FastFloat16sr(1.0) <  FastFloat16sr(2.0)
    @test FastFloat16sr(1)   <= FastFloat16sr(2)
    @test FastFloat16sr(1f0) <= FastFloat16sr(2f0)
    @test FastFloat16sr(1.0) <= FastFloat16sr(2.0)
    @test FastFloat16sr(2)   >  FastFloat16sr(1)
    @test FastFloat16sr(2f0) >  FastFloat16sr(1f0)
    @test FastFloat16sr(2)   >= FastFloat16sr(1)
    @test FastFloat16sr(2f0) >= FastFloat16sr(1f0)
    @test FastFloat16sr(2.0) >= FastFloat16sr(1.0)
end

N = 10000

@testset "1.0 always to 1.0" begin
    for i = 1:N
        @test 1.0f0 == Float32(FastFloat16sr(1.0f0))
        @test 1.0f0 == Float32(FastFloat16_stochastic_round(1.0f0))
    end
end

@testset "1+eps/2 is round 50/50 up/down" begin

    p1 = 0
    p2 = 0

    e = Float32(eps(FastFloat16sr))
    x = 1 + e/2

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    e = Float32(eps(FastFloat16sr))
    x = 1 + e/4

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    e = Float32(eps(FastFloat16sr))
    x = 2 + e/2

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    for x in Float32[2,4,8,16,32,64,128,256,512,1024]
        for i = 1:100
            @test x == Float32(FastFloat16_stochastic_round(x))
            @test x == Float32(Float16(x))
        end
    end

    for x in Float32[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256,1/512,1/1024]
        for i = 1:100
            @test x == Float32(FastFloat16_stochastic_round(x))
            @test x == Float32(Float16(x))
        end
    end
end

@testset "1+eps+eps/8 is round 12.5% up" begin

    p1 = 0
    p2 = 0

    e = Float32(eps(FastFloat16sr))
    x = 1 + e + e/8

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    e = Float32(eps(FastFloat16sr))
    x = 1 + e/8

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    e = Float32(eps(FastFloat16sr))
    x = -1 - e/8

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
        if -1.0f0 == f
            p1 += 1
        elseif -1 - e == f
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

    e = Float32(eps(FastFloat16sr))
    x = 1 + e/16

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    e = Float32(eps(FastFloat16sr))
    x = 2 + e/8

    for i = 1:N
        f = Float32(FastFloat16_stochastic_round(x))
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

    ulp_half = Float32(reinterpret(Float16,0x0001))/2

    # for some reason 0x0200 fails...?
    for hex in vcat(0x0001:0x01ff,0x0201:0x03ff)    # test for all subnormals of Float16

        # add ulp/2 to have stochastic rounding that is 50/50 up/down.
        x = Float32(reinterpret(Float16,hex)) + ulp_half

        p1 = 0
        p2 = 0

        for i = 1:N
            f = Float32(FastFloat16_stochastic_round(x))
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

# FastFloat16sr currently has the gradual transition to round to nearest in the 
# subnormals comprise - hence these tests would fail
# @testset "Some other subnormals" begin
#     f32 = Float32(1.068115234375e-05)
#     f16_rounddown = FastFloat16sr(f32)
#     f16_roundup = nextfloat(f16_rounddown)

#     N = 100_000
#     p_down = 0
#     p_up = 0 
#     for _ in 1:N
#         f = FastFloat16_stochastic_round(f32)
#         if f == f16_rounddown
#             p_down += 1
#         elseif f == f16_roundup
#             p_up += 1
#         end
#     end

#     @test p_down + p_up == N
#     @test isapprox(p_down/N,0.8,atol=1e-2)
#     @test isapprox(p_up/N,0.2,atol=1e-2)
# end