module StochasticRounding

    # use BFloat16 from BFloat16s.jl
    import BFloat16s: BFloat16s, BFloat16
    export BFloat16     # reexport BFloat16

    # Random bits for stochastic rounding come from Julia's task-local Xoshiro256++.
    # Each task has its own generator state, so stochastic rounding is thread-safe
    # and needs no locking, and child tasks are seeded deterministically from their
    # parent, so threaded code is reproducible after `seed`.
    import Random
    const RNG = Random.TaskLocalRNG()

    import DoubleFloats: DoubleFloats, Double64

    """
        seed(i::Integer)

    Seed the random number generator used for stochastic rounding in the current task.
    Tasks spawned afterwards (e.g. by `Threads.@threads`) derive their generators from it.

    !!! note
        This is the task-local default generator, so this also seeds `rand()` in the
        current task, i.e., it is the same as `Random.seed!(i)`.
    """
    function seed(i::Integer)
        Random.seed!(RNG, i)
        return nothing
    end

    # define abstract type
    export AbstractStochasticFloat
    abstract type AbstractStochasticFloat <: AbstractFloat end

    include("types.jl")             # define concrete types
    include("promotions.jl")        # their promotions
    include("general.jl")           # and general functions
end
