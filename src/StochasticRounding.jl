module StochasticRounding

    # use BFloat16 from BFloat16s.jl
    import BFloat16s: BFloat16s, BFloat16
    export BFloat16     # reexport BFloat16

    # faster random number generator
    import RandomNumbers.Xorshifts.Xoroshiro128Plus
    const Xor128 = Ref{Xoroshiro128Plus}(Xoroshiro128Plus())

    import DoubleFloats: DoubleFloats, Double64

    """Reseed the PRNG randomly by recalling."""
    function __init__()
        Xor128[] = Xoroshiro128Plus()
    end

    """Seed the PRNG with any integer >0."""
    function seed(i::Integer)
        Xor128[] = Xoroshiro128Plus(UInt64(i))
        return nothing
    end

    # define abstract type
    export AbstractStochasticFloat
    abstract type AbstractStochasticFloat <: AbstractFloat end

    include("types.jl")             # define concrete types
    include("promotions.jl")        # their promotions
    include("general.jl")           # and general functions
end
