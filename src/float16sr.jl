"""Float16 + stochastic rounding type."""
primitive type Float16sr <: AbstractFloat 16 end

# basic properties (same as for Float16)
sign_mask(::Type{Float16sr}) = 0x8000
exponent_mask(::Type{Float16sr}) = 0x7c00
significand_mask(::Type{Float16sr}) = 0x03ff
precision(::Type{Float16sr}) = 11

one(::Type{Float16sr}) = reinterpret(Float16sr,0x3c00)
zero(::Type{Float16sr}) = reinterpret(Float16sr,0x0000)
one(::Float16sr) = one(Float16sr)
zero(::Float16sr) = zero(Float16sr)

typemin(::Type{Float16sr}) = Float16sr(typemin(Float16))
typemax(::Type{Float16sr}) = Float16sr(typemax(Float16))
floatmin(::Type{Float16sr}) = Float16sr(floatmin(Float16))
floatmax(::Type{Float16sr}) = Float16sr(floatmax(Float16))

typemin(::Float16sr) = typemin(Float16sr)
typemax(::Float16sr) = typemax(Float16sr)
floatmin(::Float16sr) = floatmin(Float16sr)
floatmax(::Float16sr) = floatmax(Float16sr)

eps(::Type{Float16sr}) = Float16sr(eps(Float16))
eps(x::Float16sr) = Float16sr(eps(Float16(x)))

const Inf16sr = reinterpret(Float16sr, Inf16)
const NaN16sr = reinterpret(Float16sr, NaN16)

# basic operations
abs(x::Float16sr) = reinterpret(Float16sr, reinterpret(UInt16, x) & 0x7fff)
isnan(x::Float16sr) = isnan(Float16(x))
isfinite(x::Float16sr) = isfinite(Float16(x))

nextfloat(x::Float16sr) = Float16sr(nextfloat(Float16(x)))
prevfloat(x::Float16sr) = Float16sr(prevfloat(Float16(x)))

-(x::Float16sr) = reinterpret(Float16sr, reinterpret(UInt16, x) ⊻ sign_mask(Float16sr))

# conversions via deterministic round-to-nearest
Float16(x::Float16sr) = reinterpret(Float16,x)
Float16sr(x::Float16) = reinterpret(Float16sr,x)
Float16sr(x::Float32) = Float16sr(Float16(x))	# only arithmetics are stochastic
Float16sr(x::Float64) = Float16sr(Float32(x))
Float32(x::Float16sr) = Float32(Float16(x))
Float64(x::Float16sr) = Float64(Float16(x))

Float16sr(x::Integer) = Float16sr(Float32(x))
(::Type{T})(x::Float16sr) where {T<:Integer} = T(Float32(x))

"""Convert to Float16sr from Float32 with stochastic rounding.
Binary arithmetic version."""
function Float16_stochastic_round(x::Float32)
	ix = reinterpret(Int32,x)
	# if deterministically round to 0 return 0
	# to avoid a stochastic rounding to NaN
	# push to the left to get rid of sign
	# push to the right to get rid of the insignificant bits
	((ix << 1) >> 13) == 0x0000_0000 && return zero(BFloat16sr)

	# r are random bits for the last 15
	# >> either introduces 0s for the first 17 bits
	# or 1s. Interpreted as Int64 this corresponds to [-ulp/2,ulp/2)
	# which is added with binary arithmetic subsequently
	# this is the stochastic perturbation.
	# Then deterministic round to nearest to either round up or round down.
	r = rand(Xor128[],Int32) >> 19 # = 16sbits+3expbits difference between f16,f32
	xr = reinterpret(Float32,ix + r)
	return Float16sr(xr)
end

"""Chance that x::Float32 is round up when converted to Float16sr."""
function Float16_chance_roundup(x::Float32)
	isnan(x) && return NaN16sr
	ui = reinterpret(UInt32, x)
	# sig is the signficand (exponents & sign is masked out)
	sig = ui & significand_mask(Float32)
	# sig << 10, push significant bits that would be round away into the most
	# most significant bits, then set the exponent to be equi to one(Float32)
	# Consequently frac is fraction where x is in between x0 and x1.
	# For x=x0, frac=0, for x halfway between x0 and x1, frac=0.5
	# for one quarter the way, frac=1/4 etc.
	# this equals the chance that x gets round up in stochastic rounding
	# note that frac is in [0,1).
	frac = reinterpret(Float32,0x3fff_ffff & (F32_one | (sig << 10))) - 1f0
	return frac
end

# Promotion
promote_rule(::Type{Float32}, ::Type{Float16sr}) = Float32
promote_rule(::Type{Float64}, ::Type{Float16sr}) = Float64

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval promote_rule(::Type{Float16sr}, ::Type{$t}) = Float16sr
end

widen(::Type{Float16sr}) = Float32

# Rounding
round(x::Float16sr, r::RoundingMode{:ToZero}) = Float16sr(round(Float32(x), r))
round(x::Float16sr, r::RoundingMode{:Down}) = Float16sr(round(Float32(x), r))
round(x::Float16sr, r::RoundingMode{:Up}) = Float16sr(round(Float32(x), r))
round(x::Float16sr, r::RoundingMode{:Nearest}) = Float16sr(round(Float32(x), r))

# Comparison
function ==(x::Float16sr, y::Float16sr)
	return Float16(x) == Float16(y)
end

for op in (:<, :<=, :isless)
    @eval ($op)(a::Float16sr, b::Float16sr) = ($op)(Float32(a), Float32(b))
end

# Arithmetic
for f in (:+, :-, :*, :/, :^)
	@eval ($f)(x::Float16sr, y::Float16sr) = Float16_stochastic_round($(f)(Float32(x), Float32(y)))
end

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::Float16sr) = Float16_stochastic_round($func(Float32(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        $func(a::Float16sr,b::Float16sr) = Float16_stochastic_round($func(Float32(a),Float32(b)))
    end
end


# Showing
function show(io::IO, x::Float16sr)
    if isinf(x)
        print(io, x < 0 ? "-Inf16" : "Inf16")
    elseif isnan(x)
        print(io, "NaN16")
    else
		io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"Float16sr("*f*")")
    end
end

bitstring(x::Float16sr) = bitstring(reinterpret(UInt16,x))

function bitstring(x::Float16sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
		return "$(s[1]) $(s[2:6]) $(s[7:end])"
    else
        return bitstring(x)
    end
end
