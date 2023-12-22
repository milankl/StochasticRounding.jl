@testset for T in (BFloat16sr,Float16sr, Float32sr,Float64sr)
    @testset "Sign flip" begin
        @test one(T) == -(-(one(T)))
        @test zero(T) == -(zero(T))
    end
end

#TODO Float64sr can round down for powers of two
@testset for T in (BFloat16sr, Float16sr, Float32sr)
    @testset "Integer promotion" begin
        f = T(1)
        @test 2f == T(2)
        @test 0f == T(0)
    end
end

#TODO for Float64sr, stochastic_round(Float64sr,Inf) = NaN atm
@testset for T in (BFloat16sr, Float16sr, Float32sr)
    @testset "NaN and Inf" begin
        @test isnan(StochasticRounding.nan(T))
        @test ~isfinite(StochasticRounding.nan(T))
        @test ~isfinite(StochasticRounding.infinity(T))

        N = 1000
        for i in 1:N
            @test stochastic_round(T,Inf) == stochastic_round(T,Inf)
            @test stochastic_round(T,-Inf) == stochastic_round(T,-Inf)
            @test isnan(stochastic_round(T,NaN))
        end
    end
end

@testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
    @testset "No stochastic round to NaN" begin
        f1 = nextfloat(zero(T))
        f2 = prevfloat(zero(T))
        for i in 1:100
            @test isfinite(stochastic_round(T,f1))
            @test isfinite(stochastic_round(T,f2))
        end
    end
end

@testset for T in (BFloat16sr, Float16sr, Float32sr,Float64sr)
    @testset "Odd floats are never rounded away" begin
        N = 100_000 
    
        f_odd = prevfloat(one(T))
        f_odd_widened = widen(f_odd)
        for _ = 1:N
            @test f_odd == T(f_odd_widened)
            @test f_odd == stochastic_round(T,f_odd_widened)
        end
    end
end

#TODO Float64sr can round down for powers of two
@testset for T in (BFloat16sr, Float16sr, Float32sr)
    @testset "Even floats are never round away" begin
        N = 100_000
    
        f_even = prevfloat(one(T),2)
        f_even_widened = Float32(f_even)
        for _ = 1:N
            @test f_even == T(f_even_widened)
            @test f_even == stochastic_round(T,f_even_widened)
        end
    end
end

@testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
    @testset "Rounding" begin
        @test 1 == round(Int,T(1.2))
        @test 1 == floor(Int,T(1.2))
        @test 2 == ceil(Int,T(1.2))
    
        @test -1 == round(Int,T(-1.2))
        @test -2 == floor(Int,T(-1.2))
        @test -1 == ceil(Int,T(-1.2))
    end
end

@testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
    @testset "Nextfloat prevfloat" begin
        o = one(T)
        @test o == nextfloat(prevfloat(o))
        @test o == prevfloat(nextfloat(o))
    end
end

@testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
    @testset "Comparisons" begin
        @test T(1)   <  T(2)
        @test T(1f0) <  T(2f0)
        @test T(1.0) <  T(2.0)
        @test T(1)   <= T(2)
        @test T(1f0) <= T(2f0)
        @test T(1.0) <= T(2.0)
        @test T(2)   >  T(1)
        @test T(2f0) >  T(1f0)
        @test T(2)   >= T(1)
        @test T(2f0) >= T(1f0)
        @test T(2.0) >= T(1.0)
    end
end

#TODO Float64sr can round down for powers of two
@testset for T in (BFloat16sr, Float16sr, Float32sr)
    @testset "1.0 always to 1.0" begin
        for i = 1:10000
            @test 1 == T(1)
            @test 1 == stochastic_round(T,1.0f0)
        end
    end
end

function test_chances_round(
    T::Type{<:AbstractStochasticFloat},
    f::AbstractFloat;
    N::Int=100_000
)

    p = chance_roundup(T,f)
    f_round = T(f)
    
    if f_round <= f
        f_rounddown = f_round
        f_roundup = nextfloat(f_round)
    else
        f_roundup = f_round
        f_rounddown = prevfloat(f_round)
    end

    Ndown = 0
    Nup = 0 
    for _ in 1:N
        f_sr = stochastic_round(T,f)
        if f_sr == f_rounddown
            Ndown += 1
        elseif f_sr == f_roundup
            Nup += 1
        else
            @info "$f although in [$f_rounddown,$f_roundup] was rounded to $f_sr"
        end
    end
    
    return Ndown,Nup,N,p
end

@testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
    @testset "Test for N(0,1)" begin
        N = 10_000
        # p_ave = 0     # average absolute error in rounding chances
        # p_max = 0     # max abs error in rounding chances
        for x in randn(widen(T),N)
            Ndown,Nup,N,p = test_chances_round(T,x)
            @test Ndown + Nup == N
            Ndown + Nup != N && @info "Test failed for $x, $(bitstring(x))"
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
            p_ave += abs(Nup/N - p)
            p_max = max(p_max,abs(Nup/N - p))
        end
        # @info p_ave/N
        # @info p_max
    end
end

@testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
    @testset "Test for U(0,1)" begin
        for x in rand(widen(T),10_000)
            Ndown,Nup,N,p = test_chances_round(T,x)
            @test Ndown + Nup == N
            Ndown + Nup != N && @info "Test failed for $x, $(bitstring(x))"
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
        end
    end
end

#TODO Float64sr can round down for powers of two
@testset for T in (BFloat16sr, Float16sr, Float32sr)
    @testset "Test for powers of two" begin
        for x in [2,4,8,16,32,64,128,256]
            Ndown,Nup,N,p = test_chances_round(T,widen(T)(x))
            @test Ndown + Nup == N
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)

            # negative
            Ndown,Nup,N,p = test_chances_round(T,widen(T)(-x))
            @test Ndown + Nup == N
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)

            # inverse
            Ndown,Nup,N,p = test_chances_round(T,widen(T)(inv(x)))
            @test Ndown + Nup == N
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)

            # negative inverse
            Ndown,Nup,N,p = test_chances_round(T,widen(T)(-inv(x)))
            @test Ndown + Nup == N
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
        end
    end
end

# skip Float64sr because Double64 subnormals are the same as Float64 subnormals
# = deterministic rounding in those cases anyway
@testset for T in (BFloat16sr, Float16sr, Float32sr)
    @testset "Test for subnormals" begin
    
        N = 10_000

        if T == Float64sr
            ui = Base.uinttype(Float64)
            floatminT = reinterpret(ui,floatmin(Float64sr))
            minposT = reinterpret(ui,minpos(Float64sr))
            lows = reinterpret.(Float64,rand(minposT:floatminT,N))
            subnormals = [Double64(low) for low in lows]
        else
            ui = Base.uinttype(widen(T))
            floatminT = reinterpret(ui,widen(floatmin(T)))
            minposT = reinterpret(ui,widen(minpos(T)))
            subnormals = reinterpret.(widen(T),rand(minposT:floatminT,N))
        end

        for x in subnormals
            Ndown,Nup,N,p = test_chances_round(T,x)
            @test Ndown + Nup == N
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
        end
    
        for x in -subnormals
            Ndown,Nup,N,p = test_chances_round(T,x)
            @test Ndown + Nup == N
            @test isapprox(Ndown/N,1-p,atol=2e-2)
            @test isapprox(Nup/N,p,atol=2e-2)
        end
    end
end










