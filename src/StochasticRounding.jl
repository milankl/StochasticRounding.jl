module StochasticRounding

    export BFloat16,BFloat16sr,
            BFloat16_stochastic_round,
            BFloat16_chance_roundup,
            NaNB16, InfB16,
            Float16sr,Float16_stochastic_round,
            Float16_chance_roundup

	import Base: isfinite, isnan, precision, iszero,
			sign_mask, exponent_mask, significand_mask,
			significand_bits,
			+, -, *, /, ^,
			nextfloat,prevfloat,one,zero,eps,
			typemin,typemax,floatmin,floatmax,
			==,<=,<,
			Float16,Float32,Float64,
			promote_rule, round

	# faster random number generator
    using RandomNumbers.Xorshifts
    const Xor128 = Xoroshiro128Plus()

    include("bfloat16.jl")
    # using BFloat16            # to be swapped once BFloat16s.jl contains features

    include("bfloat16sr.jl")
    include("float16sr.jl")

end
