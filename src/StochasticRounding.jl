module StochasticRounding

    export BFloat16sr,BFloat16_stochastic_round,
            BFloat16_chance_roundup,NaNB16sr,InfB16sr,
            Float16sr,Float16_stochastic_round,
            Float16_chance_roundup,NaN16sr,Inf16sr,
			Float32sr,Float32_stochastic_round,
			Float32_chance_roundup,NaN32sr,Inf32sr

	import Base: isfinite, isnan, precision, iszero,
			sign_mask, exponent_mask, significand_mask,
			significand_bits,
			+, -, *, /, ^,
			nextfloat,prevfloat,one,zero,eps,
			typemin,typemax,floatmin,floatmax,
			==,<=,<,
			Float16,Float32,Float64,
			Int64,Int32,Int16,Int8,
			UInt64,UInt32,UInt16,UInt8,
			promote_rule, round,
			bitstring,show

	# faster random number generator
    using RandomNumbers.Xorshifts
    const Xor128 = Xoroshiro128Plus()

	import BFloat16s.BFloat16

    include("bfloat16sr.jl")
    include("float16sr.jl")
	include("float32sr.jl")

end
