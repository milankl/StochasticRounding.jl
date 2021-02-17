import FastFloat16s.FastFloat16

"""The Float32 + stochastic rounding type."""
primitive type FastFloat16sr <: AbstractFloat 32 end

# basic properties
Base.sign_mask(::Type{FastFloat16sr}) = 0x8000_0000
Base.exponent_mask(::Type{FastFloat16sr}) = 0x7f80_0000
Base.significand_mask(::Type{FastFloat16sr}) = 0x007f_ffff
Base.precision(::Type{FastFloat16sr}) = 11

Base.one(::Type{FastFloat16sr}) = reinterpret(FastFloat16sr,one(Float32))
Base.zero(::Type{FastFloat16sr}) = reinterpret(FastFloat16sr,0x0000_0000)
Base.one(::FastFloat16sr) = one(FastFloat16sr)
Base.zero(::FastFloat16sr) = zero(FlastFloat16r)

Base.typemin(::Type{FastFloat16sr}) = Float32sr(typemin(Float16))
Base.typemax(::Type{FastFloat16sr}) = Float32sr(typemax(Float16))
Base.floatmin(::Type{FastFloat16sr}) = Float32sr(floatmin(Float16))
Base.floatmax(::Type{FastFloat16sr}) = Float32sr(floatmax(FastFlaot16))

Base.typemin(::FastFloat16sr) = typemin(FastFloat16sr)
Base.typemax(::FastFloat16sr) = typemax(FastFloat16sr)
Base.floatmin(::FastFloat16sr) = floatmin(FastFloat16sr)
Base.floatmax(::FastFloat16sr) = floatmax(FastFloat16sr)

Base.eps(::Type{FastFloat16sr}) = FastFloat16sr(eps(Float16))
Base.eps(x::FastFloat16sr) = FastFloat16sr(eps(Float16(x)))

const InfF16sr = reinterpret(FastFloat16sr, Inf32)
const NaNF16sr = reinterpret(FastFloat16sr, NaN32)

# basic operations
Base.abs(x::FastFloat16sr) = reinterpret(FastFloat16sr, abs(Float32(x)))
Base.isnan(x::FastFloat16sr) = isnan(Float32(x))
Base.isfinite(x::FastFloat16sr) = isfinite(Float32(x))

Base.nextfloat(x::FastFloat16sr) = FastFloat16sr(nextfloat(Float16(x)))
Base.prevfloat(x::FastFloat16sr) = FastFloat16sr(prevfloat(Float16(x)))

# flip the sign bit with signmask 0x8000_0000
Base.:(-)(x::FastFloat16sr) = reinterpret(FastFloat16sr, reinterpret(UInt32, x) ⊻ 0x8000_0000)

# conversions
Base.Float32(x::FastFloat16sr) = reinterpret(Float32,x)
FastFloat16sr(x::FastFloat16) = reinterpret(FastFloat16sr,x)
FastFloat16(x::FastFloat16sr) = reinterpret(FastFloat16,x)
FastFloat16sr(x::Float32) = FastFloat16sr(FastFloat16(x))
FastFloat16sr(x::Float16) = FastFloat16sr(Float32(x))
FastFloat16sr(x::Float64) = FastFloat16sr(Float32(x))
Base.Float16(x::FastFloat16sr) = Float16(Float32(x))
Base.Float64(x::FastFloat16sr) = Float64(Float32(x))

FastFloat16sr(x::Integer) = FastFloat16sr(Float32(x))
(::Type{T})(x::FastFloat16sr) where {T<:Integer} = T(Float32(x))

const minpos_f16_asInt32 = reinterpret(Int32,Float32(nextfloat(zero(Float16))))
const ssmask = reinterpret(Int32,0x7f80_0000)           # sign and signifcand mask

"""Convert to FastFloat16sr from Float32 with stochastic rounding."""
function FastFloat16_stochastic_round(x::Float32)
    xi = reinterpret(Int32,x)
    # if round to nearest to 0 return 0
	(xi & ssmask) < minpos_f16_asInt32 && return zero(FastFloat16sr)
    # random perturbation in integer arithmetic
	xr = reinterpret(Float32,xi + rand(Xor128[],Int32) >> 19)
	return FastFloat16sr(xr)
end

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval Base.promote_rule(::Type{FastFloat16sr}, ::Type{$t}) = FastFloat16sr
end

# Rounding
Base.round(x::FastFloat16sr, r::RoundingMode{:ToZero}) = FastFloat16sr(round(Float32(x), r))
Base.round(x::FastFloat16sr, r::RoundingMode{:Down}) = FastFloat16sr(round(Float32(x), r))
Base.round(x::FastFloat16sr, r::RoundingMode{:Up}) = FastFloat16sr(round(Float32(x), r))
Base.round(x::FastFloat16sr, r::RoundingMode{:Nearest}) = FastFloat16sr(round(Float32(x), r))

# Comparison
function Base.:(==)(x::FastFloat16sr, y::FastFloat16sr)
	return Float32(x) == Float32(y)
end

for op in (:<, :<=, :isless)
    @eval Base.$op(a::FastFloat16sr, b::FastFloat16sr) = ($op)(Float32(a), Float32(b))
end

# Arithmetic
for f in (:+, :-, :*, :/, :^)
	@eval Base.$f(x::FastFloat16sr, y::FastFloat16sr) = FastFloat16_stochastic_round($(f)(Float32(x), Float32(y)))
end

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::FastFloat16sr) = FastFloat16_stochastic_round($func(Float32(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        Base.$func(a::FastFloat16sr,b::FastFloat16sr) = FastFloat16_stochastic_round($func(Float32(a),Float32(b)))
    end
end


# Showing
function Base.show(io::IO, x::FastFloat16sr)
    if isinf(x)Base.
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

Base.bitstring(x::FastFloat16sr) = bitstring(reinterpret(UInt32,x))

function Base.bitstring(x::FastFloat16sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
		return "$(s[1]) $(s[2:9]) $(s[10:end])"
    else
        return bitstring(x)
    end
end
