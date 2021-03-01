[![Build Status](https://travis-ci.com/milankl/StochasticRounding.jl.svg?branch=master)](https://travis-ci.com/milankl/StochasticRounding.jl)

# StochasticRounding.jl

Stochastic rounding for floating-point arithmetic.

This package exports `Float32sr`,`Float16sr`,`FastFloat16sr` and `BFloat16sr`, four number formats that behave
like their deterministic counterparts but with stochastic rounding that is proportional to the distance of the
next representable numbers and therefore [exact in expectation](https://en.wikipedia.org/wiki/Rounding#Stochastic_rounding)
(see also example below in "Usage").  Although there is currently no known hardware implementation available, 
[Graphcore is working on IPUs with stochastic rounding](https://www.graphcore.ai/posts/directions-of-ai-research). 
Stochastic rounding makes the number formats considerably slower, but e.g. Float32+stochastic rounding is only 
about 2x slower than Float64. [Xoroshio128Plus](https://sunoru.github.io/RandomNumbers.jl/stable/man/xorshifts/#Xorshift-Family-1), 
a random number generator from the [Xorshift family](https://en.wikipedia.org/wiki/Xorshift), is used through the 
[RandomNumbers.jl](https://github.com/sunoru/RandomNumbers.jl) package, due to its speed and statistical properties.

You are welcome to raise [issues](https://github.com/milankl/StochasticRounding.jl/issues), ask questions or suggest any changes or new features.

`BFloat16sr` is based on [BFloat16s.jl](https://github.com/JuliaMath/BFloat16s.jl)   
`FastFloat16sr` is based on [FastFloat16s.jl](https://github.com/milankl/FastFloat16s.jl)

### Usage

```julia
julia> a = BFloat16sr(1.0)
BFloat16sr(1.0)
julia> a/3
BFloat16sr(0.33398438)
julia> a/3
BFloat16sr(0.33203125)
```
As `1/3` is not exactly representable the rounding will be at 66.6% chance towards 0.33398438 
and at 33.3% towards 0.33203125 such that in expectation the result is 0.33333... and therefore exact. 
You can use `BFloat16_chance_roundup(x::Float32)` to get the chance that `x` will be round up.

From v0.3 onwards the random number generator is randomly seeded on every `import`
or `using` such that running the same calculations twice, will, in general, not
yield bit-reproducible results. However, you can seed the random number generator
at any time with any integer larger than zero as follows

```julia
julia> StochasticRounding.seed(2156712)
```

### Theory

Round-to-nearest (tie to even) is the standard rounding mode for IEEE floats. Stochastic rounding is explained in the following schematic

<img src="figs/schematic.png">

The exact result x of an arithmetic operation (located at one fifth between x₂ and x₃ in this example) is always round down to x₂ for round-to-nearest.
For stochastic rounding, only at 80% chance x is round down. At 20% chance it is round up to x₃, proportional to the distance of x between x₂ and x₃.

### Subnormals

The subnormals are treated differently as a compromise between speed and functionality
- `Float32sr` uses a gradual transition* to round to nearest within the subnormals, |x|<minpos/2 is always round to 0,
- `FastFloat16sr` also uses the gradual transition*.
- `Float16sr` stochastically rounds all subnormals correctly,
- `BFloat16sr` as well, but |x|<minpos/2 is always round to 0.

Gradual transition means the following. Let `sn` be *the* subnormal, i.e. `floatmin`. Then
- in [sn/2,sn) only x in [ulp/4,3ulp/4] is round stochastically, round to nearest else. (ulp is the distance between two representable numbers)
- in [sn/4,sn/2) only x in [3ulp/8,5ulp/8] is round stochastically, round to nearest else.
- in [sn/8,sn/4) only x in [7ulp/16,9ulp/16] is round stochastically, round to nearest else.
- etc.

### Installation
StochasticRounding.jl is registered in the Julia registry. Hence, simply do
```julia
julia>] add StochasticRounding
```
where `]` opens the package manager.

### Performance

StochasticRounding.jl is to my knowledge among the fastest software implementation of stochastic rounding for floating-point arithmetic. Define a few random 1000x1000 matrices
```julia
julia> using StochasticRounding, BenchmarkTools, BFloat16s
julia> A1 = rand(Float32,1000,1000);
julia> A2 = rand(Float32,1000,1000);   # A1, A2 shouldn't be identical as a+a=2a is not round
julia> B1,B2 = Float32sr.(A1),Float32sr.(A2);
```
And similarly for the other number types. Then on an Intel(R) Core(R) i5 (Ice Lake) @ 1.1GHz timings via `@btime +($A1,$A2)` etc. are

| rounding mode         | Float32    | BFloat16   | Float64   | [FastFloat16](https://github.com/milankl/FastFloat16s.jl) | Float16   |
| --------------------- | ---------- | ---------- | --------- | ----------- | --------- |
| round to nearest      | 460 μs     | 556 μs     | 1.151ms   | 629 μs      | 16.446 ms |
| stochastic rounding   | 2.585 ms   | 3.820 ms   | n/a       | 3.591 ms    | 18.611 ms |

Stochastic rounding imposes an about x5-7 performance decrease for Float32/BFloat16, but is almost negligible for Float16. 
For Float32sr about 50% of the time is spend on the random number generation, a bit less than 50% on the addition in
Float64 and the rest is the addition of the random number on the result and round to nearest.
