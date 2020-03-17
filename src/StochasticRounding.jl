module StochasticRounding

    export BFloat16,BFloat16sr,
            BFloat16_stochastic_round,
            BFloat16_chance_roundup,
            NaNB16, InfB16,
            Float16sr,Float16_stochastic_round,
            Float16_chance_roundup

    import Base: isfinite, isnan, precision, iszero,
            sign_mask, exponent_mask, exponent_one, exponent_half,
	        significand_mask,
	        +, -, *, /, ^

    using RandomNumbers.Xorshifts
    const Xor128 = Xoroshiro128Plus()

    include("bfloat16.jl")
    # using BFloat16            # to be swapped once BFloat16s.jl contains features

    include("bfloat16sr.jl")
    include("float16sr.jl")

end
