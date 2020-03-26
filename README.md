[![Build Status](https://travis-ci.com/milankl/StochasticRounding.jl.svg?branch=master)](https://travis-ci.com/milankl/StochasticRounding.jl)

# StochasticRounding

This package exports `Float32sr`,`Float16sr` and `BFloat16sr`. Three number formats that behave like their deterministic counterparts but with stochastic rounding that is proportional to the distance of the next representable numbers and therefore [exact in expectation](https://en.wikipedia.org/wiki/Rounding#Stochastic_rounding) (see also example below in "Usage"). Although there is currently no known hardware implementation available, [Graphcore is working on IPUs with stochastic rounding](https://www.graphcore.ai/posts/directions-of-ai-research). Stochastic rounding makes the current `Float16`/`BFloat16` software implementations considerably slower, but less than <10x currently. [Xoroshio128Plus](https://sunoru.github.io/RandomNumbers.jl/stable/man/xorshifts/#Xorshift-Family-1), a random number generator from the [Xorshift family](https://en.wikipedia.org/wiki/Xorshift), is used through the [RandomNumbers.jl](https://github.com/sunoru/RandomNumbers.jl) package.

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

### Theory

Round nearest (tie to even) is the standard rounding mode for IEEE floats. Stochastic rounding is explained in the following schematic

<img src="figs/schematic.png">

The exact result x of an arithmetic operation (located at one fifth between x₂ and x₃ in this example) is round down to x₂ for round to nearest rounding mode.
For stochastic rounding only at 80% chance x is round down, in 20% chance it is round up to x₃, proportional to the distance of x between x₂ and x₃.

### Performance

Define a few random 1000x1000 matrices
```julia
julia> using StochasticRounding, BenchmarkTools, BFloat16s
julia> A = rand(Float32,1000,1000);
julia> B = Float32sr.(A);
julia> C = BFloat16.(A);
julia> D = BFloat16sr.(A);
julia> E = Float16.(A);
julia> F = Float16sr.(A);
```
Then on an Intel(R) Xeon(R) CPU E5-2698 v3 @ 2.30GHz timings are
```julia
julia> @btime +($A,$A);     # Float32
  506.308 μs (2 allocations: 3.81 MiB)

julia> @btime +($B,$B);     # Float32sr
  3.663 ms (2 allocations: 3.81 MiB)

julia> @btime +($C,$C);     # BFloat16
  752.281 μs (2 allocations: 1.91 MiB)

julia> @btime +($D,$D);     # BFloat16sr
  6.247 ms (2 allocations: 1.91 MiB)

julia> @btime +($E,$E);     # Float16
  8.884 ms (2 allocations: 1.91 MiB)

julia> @btime +($F,$F);     # Float16sr
  21.464 ms (2 allocations: 1.91 MiB)
```

Stochastic rounding imposes a x7 performance decrease for Float32, x8 performance decrease for BFloat16 and x2.4 for Float16.
