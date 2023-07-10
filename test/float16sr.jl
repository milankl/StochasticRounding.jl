@testset "Sign flip" begin
    @test one(Float16sr) == -(-(one(Float16sr)))
    @test zero(Float16sr) == -(zero(Float16sr))
end

@testset "NaN and Inf" begin
    @test isnan(NaN16sr)
    @test ~isfinite(NaN16sr)
    @test ~isfinite(Inf16sr)

    N = 1000
    for i in 1:N
        @test Inf16sr == Float16_stochastic_round(Inf32)
        @test -Inf16sr == Float16_stochastic_round(-Inf32)
        @test isnan(Float16_stochastic_round(NaN32))
    end
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

@testset "Odd floats are never rounded away" begin
    # chances are 2^-29 = 2e-9
    # so technically one should use N = 100_000_000
    N = 100_000 

    f_odd = prevfloat(one(Float16sr))
    f_odd_f32 = Float32(f_odd)
    for _ = 1:N
        @test f_odd == Float16sr(f_odd_f32)
        @test f_odd == Float16_stochastic_round(f_odd_f32)
    end
end

@testset "Even floats are never round away" begin
    # chances are 2^-29 = 2e-9
    # so technically one should use N = 100_000_000
    N = 100_000 

    f_odd = prevfloat(prevfloat(one(Float16sr)))
    f_odd_f32 = Float32(f_odd)
    for _ = 1:N
        @test f_odd == Float16sr(f_odd_f32)
        @test f_odd == Float16_stochastic_round(f_odd_f32)
    end
end

function test_chances_round(f32::Float32;N::Int=100_000)
    p = Float16_chance_roundup(f32)

    f16_round = Float16sr(f32)

    if Float32(f16_round) == f32
        f16_roundup=f16_round
        f16_rounddown=f16_round
    elseif Float32(f16_round) < f32
        f16_rounddown = f16_round
        f16_roundup = nextfloat(f16_round)
    else
        f16_roundup = f16_round
        f16_rounddown = prevfloat(f16_round)
    end

    Ndown = 0
    Nup = 0 
    for _ in 1:N
        f16 = Float16_stochastic_round(f32)
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
        # exclude subnormals from testing, they are tested further down
        if ~issubnormal(Float16(x))
            Ndown,Nup,N,p = test_chances_round(x)
            @test Ndown + Nup == N
            Ndown + Nup != N && @info "Test failed for $x, $(bitstring(Float16(x)))"
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
        end
    end
end

@testset "Test for U(0,1)" begin
    for x in rand(Float32,10_000)
        # exclude subnormals from testing, they are tested further down
        if ~issubnormal(Float16(x))
            Ndown,Nup,N,p = test_chances_round(x)
            @test Ndown + Nup == N
            Ndown + Nup != N && @info "Test failed for $x, $(bitstring(Float16(x)))"
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
        end
    end
end

@testset "Test for powers of two" begin
    for x in Float32[2,4,8,16,32,64,128,256]
        Ndown,Nup,N,p = test_chances_round(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in -Float32[2,4,8,16,32,64,128,256]
        Ndown,Nup,N,p = test_chances_round(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in Float32[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256]
        Ndown,Nup,N,p = test_chances_round(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in -Float32[1/2,1/4,1/8,1/16,1/32,1/64,1/128,1/256]
        Ndown,Nup,N,p = test_chances_round(x)
        @test Ndown + Nup == N
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end
end

@testset "Test for subnormals" begin

    floatminF16 = reinterpret(UInt32,Float32(floatmin(Float16)))
    minposF16 = reinterpret(UInt32,Float32(nextfloat(zero(Float16))))

    N = 10_000
    subnormals = reinterpret.(Float32,rand(minposF16:floatminF16,N))
    for x in subnormals
        Ndown,Nup,N,p = test_chances_round(x)
        @test Ndown + Nup == N
        Ndown + Nup != N && @info "Test failed for $x, $(bitstring(Float16(x)))"
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end

    for x in -subnormals
        Ndown,Nup,N,p = test_chances_round(x)
        @test Ndown + Nup == N
        Ndown + Nup != N && @info "Test failed for $x, $(bitstring(Float16(x)))"
        @test isapprox(Ndown/N,1-p,atol=2e-2)
        @test isapprox(Nup/N,p,atol=2e-2)
    end
end

# USED TO TEST SOME SUBNORMALS MANUALLY
# const ϵ = prevfloat(Float32(nextfloat(zero(Float16))),1)

# function g(x::Float32,r::Float32)
#     # x + ϵ*(r-1.5f0)
#     x + randfloat(reinterpret(UInt32,r))
# end

# function randfloat(ui::UInt32)

#     lz = leading_zeros(ui)
#     e = ((101 - lz) % UInt32) << 23
#     e |= (ui << 31)

#     # combine exponent and significand
#     return reinterpret(Float32,e | (ui & 0x007f_ffff))
# end


# function h(x::Float32)
#     # deterministically rounded correct value in uint16
#     c = Int(reinterpret(UInt16,Float16(x)))

#     v = zeros(Int16,2^23)
#     r = 1f0

#     for i in 0:2^23-1
#         v[i+1] = Int(reinterpret(UInt16,Float16(g(x,r)))) - c
#         r = nextfloat(r)
#     end
#     return v
# end