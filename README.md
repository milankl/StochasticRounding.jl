# StochasticRounding.jl <img width="5%" src="figs/logo.png">
[![CI](https://github.com/milankl/StochasticRounding.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/milankl/StochasticRounding.jl/actions/workflows/CI.yml)
[![DOI](https://zenodo.org/badge/247823063.svg)](https://zenodo.org/badge/latestdoi/247823063)

Stochastic rounding for floating-point arithmetic.

This package exports `Float64sr`, `Float32sr`,`Float16sr`, and `BFloat16sr`, three number formats that behave
like their deterministic counterparts but with stochastic rounding that is proportional to the
distance of the next representable numbers and therefore
[exact in expectation](https://en.wikipedia.org/wiki/Rounding#Stochastic_rounding)
(see also example below in [Usage](https://github.com/milankl/StochasticRounding.jl#usage).
The only known hardware implementation available is
[Graphcore's IPU with stochastic rounding](https://www.graphcore.ai/products/ipu),
but other vendors are likely working on stochastic rounding for their next-generation
GPUs (and maybe CPUs too).

The software emulation in StochasticRounding.jl makes the number format
slower, but e.g. Float32 with stochastic rounding is only about 2x slower than the 
default deterministically rounded Float64. 
[Xoroshiro128Plus](https://sunoru.github.io/RandomNumbers.jl/stable/man/xorshifts/#Xorshift-Family-1), 
a random number generator from the [Xorshift family](https://en.wikipedia.org/wiki/Xorshift), is used from the 
[RandomNumbers.jl](https://github.com/sunoru/RandomNumbers.jl) package, due to its speed and statistical properties.

Every format of `Float64sr`, `Float32sr`,`Float16sr`, and `BFloat16sr` uses a higher precision format
to obtain the "exact" arithmetic result which is then stochastically rounded to the respective
lower precision format. `Float16sr` and `BFloat16sr` use `Float32` for this,
`Float32sr` uses `Float64`, and `Float64sr` uses `Double64` from
[DoubleFloats.jl](https://github.com/JuliaMath/DoubleFloats.jl)

You are welcome to raise [issues](https://github.com/milankl/StochasticRounding.jl/issues),
ask questions or suggest any changes or new features.

`BFloat16sr` is based on [BFloat16s.jl](https://github.com/JuliaMath/BFloat16s.jl)   
`Float16sr` is slow in Julia <1.6, but much faster in Julia >=1.6 due to LLVM's `half` support.

## Usage

`Float64sr`, `Float32sr`, `Float16sr` and `BFloat16sr` are supposed to be drop-in replacements for their
deterministically rounded counterparts. You can create data of those types as expected
(which is bitwise identical to the deterministic formats respectively) and the type
will trigger stochastic rounding on every arithmetic operation.

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
You can use `BFloat16_chance_roundup(x::Float32)` to get the chance that `x` will be rounded up.

Solving a linear equation system with LU decomposition and stochastic rounding:
```julia
A = randn(Float32sr,3,3)
b = randn(Float32sr,3)
```
Now execute the `\` several times and the results will differ slightly due to stochastic rounding
```julia
julia> A\b
3-element Vector{Float32sr}:
  3.3321106f0
  2.0391452f0
 -0.59199476f0

julia> A\b
3-element Vector{Float32sr}:
  3.3321111f0
  2.0391457f0
 -0.5919949f0
```
The random number generator is randomly seeded on every `import` or `using` such that running
the same calculations twice, will not yield bit-reproducible results. However, you can seed
the random number generator at any time with any integer larger than zero as follows

```julia
julia> StochasticRounding.seed(2156712)
```

the state of the random number generator for StochasticRounding.jl is independent from Julia's default,
which is used for `rand()`, `randn()` etc.

## Theory

Round-to-nearest (tie to even) is the standard rounding mode for IEEE floats.
Stochastic rounding is explained in the following schematic

<img src="figs/schematic.png">

The exact result x of an arithmetic operation (located at one fifth between x₂ and x₃ in this example)
is always rounded down to x₂ for round-to-nearest.
For stochastic rounding, only at 80% chance x is round down.
At 20% chance it is round up to x₃, proportional to the distance of x between x₂ and x₃.

## Installation
StochasticRounding.jl is registered in the Julia registry. Hence, simply do
```julia
julia>] add StochasticRounding
```
where `]` opens the package manager.

## Performance

StochasticRounding.jl is among the fastest software implementation of stochastic rounding for floating-point arithmetic.
Define a few random 1000000-element arrays
```julia
julia> using StochasticRounding, BenchmarkTools, BFloat16s
julia> A = rand(Float64,1000000);
julia> B = rand(Float64,1000000);   # A, B shouldn't be identical as a+a=2a is not round
```
And similarly for the other number types. Then with Julia 1.6 on an Intel(R) Core(R) i5 (Ice Lake) @ 1.1GHz timings via
`@btime +($A,$B)` are

| rounding mode         | Float64    | Float32    | Float16   | BFloat16    |
| --------------------- | ---------- | ---------- | --------- | ----------- |
| round to nearest      | 1132 μs    |  452 μs    | 1588 μs   |  315 μs     |
| stochastic rounding   | 11,368 μs  | 2650 μs    | 3310 μs   | 1850 μs     |

Stochastic rounding imposes an about x5 performance decrease for Float32 and BFloat16, but only x2 for Float16,
however, 10x for Float64 due to the use of Double64.
For more complicated benchmarks the performance decrease is usually within x10.
About 50% of the time is spend on the random number generation with Xoroshiro128+.

## Citation

If you use this package please cite us

> Paxton EA, M Chantry, M Klöwer, L Saffin, TN Palmer, 2022. Climate Modelling in Low-Precision: Effects of both Deterministic & Stochastic Rounding, Journal of Climate, [10.1175/JCLI-D-21-0343.1](https://doi.org/10.1175/JCLI-D-21-0343.1)
