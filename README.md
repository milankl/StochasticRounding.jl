[![Build Status](https://travis-ci.com/milankl/StochasticRounding.jl.svg?branch=master)](https://travis-ci.com/milankl/StochasticRounding.jl.svg)

# StochasticRounding

This package exports `Float16sr` and `BFloat16sr`. Two number formats that behave like their deterministic counterparts but with stochastic rounding that is proportional to the distance of the next representable numbers and therefore [exact in expectation](https://en.wikipedia.org/wiki/Rounding#Stochastic_rounding) (see also example below in "Usage"). Although there is currently no known hardware implementation available, [Graphcore is working on IPUs with stochastic rounding](https://www.graphcore.ai/posts/directions-of-ai-research). Stochastic rounding makes the current `Float16`/`BFloat16` implementation considerably slower, but only ~x15. [Xoroshio128Plus](https://sunoru.github.io/RandomNumbers.jl/stable/man/xorshifts/#Xorshift-Family-1), a random number generator from the [Xorshift family](https://en.wikipedia.org/wiki/Xorshift), is used through the [RandomNumbers.jl](https://github.com/sunoru/RandomNumbers.jl) package.

Stochastic rounding is only applied on arithmetic operations, and not on type conversions or for subnormal numbers (standard round to nearest instead).

### Usage

```julia
julia> a = BFloat16sr(1.0)
BFloat16sr(1.0)
julia> a/3
BFloat16sr(0.33398438)
julia> a/3
BFloat16sr(0.33203125)
```
As `1/3` is not exactly representable the rounding will be at 66.6% chance towards 0.33398438 and at 33.3% towards 0.33203125 such that in expectation the result is 0.33333... and therefore exact. You can use `BFloat16_chance_roundup(x::Float32)` to get the chance that `x` will be round up.

### Performance

```julia
julia> using BFloat16s, BenchmarkTools
julia> A = rand(Float32,1000,1000);
julia> B = BFloat16.(A);
julia> C = BFloat16sr.(A);
julia> @btime +($A,$A);
  310.638 μs (2 allocations: 3.81 MiB)

julia> @btime +($B,$B);
  567.917 μs (2 allocations: 1.91 MiB)

julia> @btime +($C,$C);
  8.518 ms (8 allocations: 1.91 MiB)
```
Stochastic rounding imposes a ~x15 performance decrease.
