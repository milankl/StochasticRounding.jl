@testset "Sign flip" begin
    @test one(Float16sr) == -(-(one(Float16sr)))
    @test zero(Float16sr) == -(zero(Float16sr))
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
        @test isfinite(Float16_stochastic_round(f1))
        @test isfinite(Float16_stochastic_round(f2))
    end
end

@testset "Integer promotion" begin
    f = Float16sr(1)
    @test 2f == Float16sr(2)
    @test 0 == Float16sr(0)
end

@testset "Rounding" begin
    @test 1 == Int(round(Float16sr(1.2)))
    @test 1 == Int(floor(Float16sr(1.2)))
    @test 2 == Int(ceil(Float16sr(1.2)))

    @test -1 == Int(round(Float16sr(-1.2)))
    @test -2 == Int(floor(Float16sr(-1.2)))
    @test -1 == Int(ceil(Float16sr(-1.2)))
end

@testset "Nextfloat prevfloat" begin
    o = one(Float16sr)
    @test o == nextfloat(prevfloat(o))
    @test o == prevfloat(nextfloat(o))
end

@testset "Deterministic conversion float" begin
    fs = [1.0,2.5,10.0,0.0,-0.25,-5.0]

    for f in fs
        @test f == Float64(Float16sr(f))
        @test Float32(f) == Float32(Float16sr(f))
        @test Float16(f) == Float16(Float16sr(f))
    end
end

@testset "Deterministic conversion int" begin
    fs = [-5,-1,0,-0,1,2]

    for f in fs
        @test f == Int64(Float16sr(f))
        @test Int32(f) == Int32(Float16sr(f))
        @test Int16(f) == Int16(Float16sr(f))
    end
end

@testset "Comparisons" begin
    @test Float16sr(1)   <  Float16sr(2)
    @test Float16sr(1f0) <  Float16sr(2f0)
    @test Float16sr(1.0) <  Float16sr(2.0)
    @test Float16sr(1)   <= Float16sr(2)
    @test Float16sr(1f0) <= Float16sr(2f0)
    @test Float16sr(1.0) <= Float16sr(2.0)
    @test Float16sr(2)   >  Float16sr(1)
    @test Float16sr(2f0) >  Float16sr(1f0)
    @test Float16sr(2)   >= Float16sr(1)
    @test Float16sr(2f0) >= Float16sr(1f0)
    @test Float16sr(2.0) >= Float16sr(1.0)
end

N = 10000

@testset "1.0 always to 1.0" begin
    for i = 1:N
        @test 1.0f0 == Float32(Float16sr(1.0f0))
        @test 1.0f0 == Float32(Float16_stochastic_round(1.0f0))
    end
end

@testset "1+eps/2 is round 50/50 up/down" begin

    p1 = 0
    p2 = 0

    e = Float32(eps(Float16sr))
    x = 1 + e/2

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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

    e = Float32(eps(Float16sr))
    x = 1 + e/4

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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

    e = Float32(eps(Float16sr))
    x = 2 + e/2

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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
            @test x == Float32(Float16_stochastic_round(x))
            @test x == Float32(Float16(x))
        end
    end

    for x in Float32[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256,1/512,1/1024]
        for i = 1:100
            @test x == Float32(Float16_stochastic_round(x))
            @test x == Float32(Float16(x))
        end
    end
end

@testset "1+eps+eps/8 is round 12.5% up" begin

    p1 = 0
    p2 = 0

    e = Float32(eps(Float16sr))
    x = 1 + e + e/8

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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

    e = Float32(eps(Float16sr))
    x = 1 + e/8

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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

    e = Float32(eps(Float16sr))
    x = -1 - e/8

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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

    e = Float32(eps(Float16sr))
    x = 1 + e/16

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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

    e = Float32(eps(Float16sr))
    x = 2 + e/8

    for i = 1:N
        f = Float32(Float16_stochastic_round(x))
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
            f = Float32(Float16_stochastic_round(x))
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
