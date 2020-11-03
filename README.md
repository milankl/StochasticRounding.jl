[![Build Status](https://travis-ci.com/milankl/StochasticRounding.jl.svg?branch=master)](https://travis-ci.com/milankl/StochasticRounding.jl)

# StochasticRounding

This package exports `Float32sr`,`Float16sr` and `BFloat16sr`. Three number formats that behave like their deterministic counterparts but with stochastic rounding that is proportional to the distance of the next representable numbers and therefore [exact in expectation](https://en.wikipedia.org/wiki/Rounding#Stochastic_rounding) (see also example below in "Usage"). Although there is currently no known hardware implementation available, [Graphcore is working on IPUs with stochastic rounding](https://www.graphcore.ai/posts/directions-of-ai-research). Stochastic rounding makes the number formats considerably slower, but e.g. Float32+stochastic rounding is only about 2x slower than Float64. [Xoroshio128Plus](https://sunoru.github.io/RandomNumbers.jl/stable/man/xorshifts/#Xorshift-Family-1), a random number generator from the [Xorshift family](https://en.wikipedia.org/wiki/Xorshift), is used through the [RandomNumbers.jl](https://github.com/sunoru/RandomNumbers.jl) package.

Stochastic rounding is only applied on arithmetic operations, and not on type conversions (standard round to nearest instead).

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

From v0.3 onwards the random number generator is randomly seeded on every `import`
or `using` such that running the same calculations twice, will, in general, not
yield bit-reproducible results. However, you can seed the random number generator
at any time with any integer larger than zero as follows

```julia
julia> StochasticRounding.seed(2156712)
```

### Theory

Round nearest (tie to even) is the standard rounding mode for IEEE floats. Stochastic rounding is explained in the following schematic

<img src="figs/schematic.png">

The exact result x of an arithmetic operation (located at one fifth between x₂ and x₃ in this example) is round down to x₂ for round to nearest rounding mode.
For stochastic rounding only at 80% chance x is round down, in 20% chance it is round up to x₃, proportional to the distance of x between x₂ and x₃.

### Installation
StochasticRounding.jl is registered in the Julia registry. Hence, simply do
```julia
julia>] add StochasticRounding
```
where `]` opens the package manager.

### Performance

Define a few random 1000x1000 matrices
```julia
julia> using StochasticRounding, BenchmarkTools, BFloat16s
julia> A1 = rand(Float32,1000,1000);
julia> A2 = rand(Float32,1000,1000);   # A1, A2 shouldn't be identical as a+a=2a is not round
julia> B1,B2 = Float32sr.(A1),Float32sr.(A2);
```
And similarly for the other number types. Then on an Intel(R) Core(R) i5 (Ice Lake) @ 1.1GHz timings via `@btime +($A1,$A2)` etc. are

| rounding mode         | Float32    | BFloat16   | Float64   | Float16   |
| --------------------- | ---------- | ---------- | --------- | --------- |
| default               | 460.421 μs | 588.813 μs | 1.151ms   | 16.446 ms |
| + stochastic rounding | 2.458 ms   | 3.398 ms   | n/a       | 17.318 ms |

Stochastic rounding imposes an about x5 performance decrease for Float32/BFloat16, but is negligible for Float16. For Float32sr about 50% of the time is
spend on the random number generation, a bit less than 50% on the addition in
Float64 and the rest is the addition of the random number on the result and
round to nearest.
