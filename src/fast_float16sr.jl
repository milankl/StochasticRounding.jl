import FastFloat16s.FastFloat16

"""The Float32 + stochastic rounding type."""
primitive type FastFloat16sr <: AbstractFloat 32 end

# basic properties
sign_mask(::Type{FastFloat16sr}) = 0x8000_0000
exponent_mask(::Type{FastFloat16sr}) = 0x7f80_0000
significand_mask(::Type{FastFloat16sr}) = 0x007f_ffff
precision(::Type{FastFloat16sr}) = 11

one(::Type{FastFloat16sr}) = reinterpret(FastFloat16sr,one(Float32))
zero(::Type{FastFloat16sr}) = reinterpret(FastFloat16sr,0x0000_0000)
one(::FastFloat16sr) = one(FastFloat16sr)
zero(::FastFloat16sr) = zero(FlastFloat16r)

typemin(::Type{FastFloat16sr}) = Float32sr(typemin(Float16))
typemax(::Type{FastFloat16sr}) = Float32sr(typemax(Float16))
floatmin(::Type{FastFloat16sr}) = Float32sr(floatmin(Float16))
floatmax(::Type{FastFloat16sr}) = Float32sr(floatmax(FastFlaot16))

typemin(::FastFloat16sr) = typemin(FastFloat16sr)
typemax(::FastFloat16sr) = typemax(FastFloat16sr)
floatmin(::FastFloat16sr) = floatmin(FastFloat16sr)
floatmax(::FastFloat16sr) = floatmax(FastFloat16sr)

eps(::Type{FastFloat16sr}) = FastFloat16sr(eps(Float16))
eps(x::FastFloat16sr) = FastFloat16sr(eps(Float16(x)))

const InfF16sr = reinterpret(FastFloat16sr, Inf32)
const NaNF16sr = reinterpret(FastFloat16sr, NaN32)

# basic operations
abs(x::FastFloat16sr) = reinterpret(FastFloat16sr, abs(Float32(x)))
isnan(x::FastFloat16sr) = isnan(Float32(x))
isfinite(x::FastFloat16sr) = isfinite(Float32(x))

nextfloat(x::FastFloat16sr) = FastFloat16sr(nextfloat(Float16(x)))
prevfloat(x::FastFloat16sr) = FastFloat16sr(prevfloat(Float16(x)))

-(x::FastFloat16sr) = reinterpret(FastFloat16sr, reinterpret(UInt32, x) ⊻ sign_mask(FastFloat16sr))

# conversions
Float32(x::FastFloat16sr) = reinterpret(Float32,x)
FastFloat16sr(x::FastFloat16) = reinterpret(FastFloat16sr,x)
FastFloat16(x::FastFloat16sr) = reinterpret(FastFloat16,x)
FastFloat16sr(x::Float32) = FastFloat16sr(FastFloat16(x))
FastFloat16sr(x::Float16) = FastFloat16sr(Float32(x))
FastFloat16sr(x::Float64) = FastFloat16sr(Float32(x))
Float16(x::FastFloat16sr) = Float16(Float32(x))
Float64(x::FastFloat16sr) = Float64(Float32(x))

FastFloat16sr(x::Integer) = FastFloat16sr(Float32(x))
(::Type{T})(x::FastFloat16sr) where {T<:Integer} = T(Float32(x))

"""Convert to FastFloat16sr from Float32 with stochastic rounding.
Binary arithmetic version."""
function FastFloat16_stochastic_round(x::Float32)
	ix = reinterpret(Int32,x)
	# if deterministically round to 0 return 0
	# to avoid a stochastic rounding to NaN
	# push to the left to get rid of sign
	# push to the right to get rid of the insignificant bits
	((ix << 1) >> 13) == zero(Int32) && return zero(FastFloat16sr)

	# r are random bits for the last 31
	# >> either introduces 0s for the first 33 bits
	# or 1s. Interpreted as Int64 this corresponds to [-ulp/2,ulp/2)
	# which is added with binary arithmetic subsequently
	# this is the stochastic perturbation.
	# Then deterministic round to nearest to either round up or round down.
	r = rand(Xor128[],Int32) >> 19   # = preserve 1 sign, 8 ebits, 10sbits
	xr = reinterpret(Float32,ix + r)
	return FastFloat16sr(xr)			# round to nearest
end

# # Promotion
# promote_rule(::Type{Float16}, ::Type{FastFloat32sr}) = Float32
# promote_rule(::Type{Float64}, ::Type{Float32sr}) = Float64

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval promote_rule(::Type{FastFloat16sr}, ::Type{$t}) = FastFloat16sr
end

# Rounding
round(x::FastFloat16sr, r::RoundingMode{:ToZero}) = FastFloat16sr(round(Float32(x), r))
round(x::FastFloat16sr, r::RoundingMode{:Down}) = FastFloat16sr(round(Float32(x), r))
round(x::FastFloat16sr, r::RoundingMode{:Up}) = FastFloat16sr(round(Float32(x), r))
round(x::FastFloat16sr, r::RoundingMode{:Nearest}) = FastFloat16sr(round(Float32(x), r))

# Comparison
function ==(x::FastFloat16sr, y::FastFloat16sr)
	return Float32(x) == Float32(y)
end

for op in (:<, :<=, :isless)
    @eval ($op)(a::FastFloat16sr, b::FastFloat16sr) = ($op)(Float32(a), Float32(b))
end

# Arithmetic
for f in (:+, :-, :*, :/, :^)
	@eval ($f)(x::FastFloat16sr, y::FastFloat16sr) = FastFloat16_stochastic_round($(f)(Float32(x), Float32(y)))
end

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::FastFloat16sr) = FastFloat16_stochastic_round($func(Float32(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        $func(a::FastFloat16sr,b::FastFloat16sr) = FastFloat16_stochastic_round($func(Float32(a),Float32(b)))
    end
end


# Showing
function show(io::IO, x::FastFloat16sr)
    if isinf(x)
        print(io, x < 0 ? "-InfF16sr" : "InfF16sr")
    elseif isnan(x)
        print(io, "NaNF16sr")
    else
		io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"FastFloat16sr("*f*")")
    end
end

bitstring(x::FastFloat16sr) = bitstring(reinterpret(UInt32,x))

function bitstring(x::FastFloat16sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
		return "$(s[1]) $(s[2:9]) $(s[10:end])"
    else
        return bitstring(x)
    end
end
