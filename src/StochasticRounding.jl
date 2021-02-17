module StochasticRounding

    export BFloat16sr,BFloat16_stochastic_round,        # BFloat16 + SR
        BFloat16_chance_roundup,NaNB16sr,InfB16sr,
        Float16sr,Float16_stochastic_round,             # Float16 + SR
        Float16_chance_roundup,NaN16sr,Inf16sr,
        Float32sr,Float32_stochastic_round,             # Float32 + SR
        Float32_chance_roundup,NaN32sr,Inf32sr,
        FastFloat16sr,FastFloat16_stochastic_round,     # FastFloat16 + SR
        NaNF16sr,InfF16sr

    # faster random number generator
    import RandomNumbers.Xorshifts.Xoroshiro128Plus
    const Xor128 = Ref{Xoroshiro128Plus}(Xoroshiro128Plus())

    """Reseed the PRNG randomly by recalling."""
    function __init__()
        Xor128[] = Xoroshiro128Plus()
    end

    """Seed the PRNG with any integer >0."""
    function seed(i::Integer)
        Xor128[] = Xoroshiro128Plus(UInt64(i))
        return nothing
    end

    include("bfloat16sr.jl")
    include("float16sr.jl")
    include("float32sr.jl")
    include("fast_float16sr.jl")

end
