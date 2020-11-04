"""The BFloat16 + stochastic rounding type."""
primitive type BFloat16sr <: AbstractFloat 16 end

# Floating point property queries
for f in (:sign_mask, :exponent_mask, :exponent_one,
            :exponent_half, :significand_mask)
    @eval $(f)(::Type{BFloat16sr}) = UInt16($(f)(Float32) >> 16)
end

"""Mask for both sign and exponent bits. Equiv to ~significand_mask(Float32)."""
signexp_mask(::Type{Float32}) = 0xff80_0000

iszero(x::BFloat16sr) = reinterpret(UInt16, x) & ~sign_mask(BFloat16sr) == 0x0000
isfinite(x::BFloat16sr) = (reinterpret(UInt16,x) & exponent_mask(BFloat16sr)) != exponent_mask(BFloat16sr)
isnan(x::BFloat16sr) = (reinterpret(UInt16,x) & ~sign_mask(BFloat16sr)) > exponent_mask(BFloat16sr)

precision(::Type{BFloat16sr}) = 8
one(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x3f80)
zero(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x0000)

const InfB16sr = reinterpret(BFloat16sr, 0x7f80)
const NaNB16sr = reinterpret(BFloat16sr, 0x7fc0)

typemin(::Type{BFloat16sr}) = -InfB16sr
typemax(::Type{BFloat16sr}) = InfB16sr
floatmin(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x0080)
floatmax(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x7f7f)

typemin(::BFloat16sr) = typemin(BFloat16sr)
typemax(::BFloat16sr) = typemax(BFloat16sr)
floatmin(::BFloat16sr) = floatmin(BFloat16sr)
floatmax(::BFloat16sr) = floatmax(BFloat16sr)

# Truncation from Float32
Base.uinttype(::Type{BFloat16sr}) = UInt16
Base.trunc(::Type{BFloat16sr}, x::Float32) = reinterpret(BFloat16sr,
        (reinterpret(UInt32, x) >> 16) % UInt16)

# same for BFloat16sr, but do not apply stochastic rounding to avoid InexactError
round(x::BFloat16sr, r::RoundingMode{:Up}) = BFloat16sr(ceil(Float32(x)))
round(x::BFloat16sr, r::RoundingMode{:Down}) = BFloat16sr(floor(Float32(x)))
round(x::BFloat16sr, r::RoundingMode{:Nearest}) = BFloat16sr(round(Float32(x)))

# conversion to integer
Int64(x::BFloat16sr) = Int64(Float32(x))
Int32(x::BFloat16sr) = Int32(Float32(x))
Int16(x::BFloat16sr) = Int16(Float32(x))
Int8(x::BFloat16sr) = Int8(Float32(x))
UInt64(x::BFloat16sr) = UInt64(Float32(x))
UInt32(x::BFloat16sr) = UInt32(Float32(x))
UInt16(x::BFloat16sr) = UInt16(Float32(x))
UInt8(x::BFloat16sr) = UInt8(Float32(x))

const F32_one = reinterpret(UInt32,one(Float32))	# Float32 one as UInt32

"""Convert to BFloat16sr from Float32 via round-to-nearest
and tie to even. Identical to BFloat16(::Float32)."""
function BFloat16sr(x::Float32)
    isnan(x) && return NaNB16sr
    h = reinterpret(UInt32, x)
    h += 0x7fff + ((h >> 16) & 1)
    return reinterpret(BFloat16sr, (h >> 16) % UInt16)
end

"""Convert to BFloat16sr from Float32 with stochastic rounding.
Binary arithmetic version."""
function BFloat16_stochastic_round(x::Float32)
	ix = reinterpret(Int32,x)
	# if deterministically round to 0 return 0
	# to avoid a stochastic rounding to NaN
	# push to the left to get rid of sign
	# push to the right to get rid of the insignificant bits
	((ix << 1) >> 16) == 0x0000_0000 && return zero(BFloat16sr)
	# r are random bits for the last 15
	# >> either introduces 0s for the first 17 bits
	# or 1s. Interpreted as Int32 this corresponds to [-ulp/2,ulp/2)
	# which is added with binary arithmetic subsequently
	# this is the stochastic perturbation.
	# Then deterministic round to nearest to either round up or round down.
	r = rand(Xor128[],Int32) >> 16
	xr = reinterpret(Float32,ix + r)
	return BFloat16sr(xr)
end

"""Chance that x::Float32 is round up when converted to BFloat16sr."""
function BFloat16_chance_roundup(x::Float32)
    isnan(x) && return NaNB16sr
	ui = reinterpret(UInt32, x)
	# sig is the signficand (exponents & sign is masked out)
	sig = ui & significand_mask(Float32)
	# sig << 7, push significant bits that would be round away into the most
	# most significant bits, then set the exponent to be equi to one(Float32)
	# Consequently frac is fraction where x is in between x0 and x1.
	# For x=x0, frac=0, for x halfway between x0 and x1, frac=0.5
	# for one quarter the way, frac=1/4 etc.
	# this equals the chance that x gets round up in stochastic rounding
	# note that frac is in [0,1).
	frac = reinterpret(Float32,F32_one | (sig << 7)) - 1f0
    return frac
end

# Conversions
"""Convert BFloat16sr to Float32 by padding trailing zeros."""
Float32(x::BFloat16sr) = reinterpret(Float32, UInt32(reinterpret(UInt16, x)) << 16)

BFloat16sr(x::Float64) = BFloat16sr(Float32(x))
BFloat16sr(x::Float16) = BFloat16sr(Float32(x))
BFloat16sr(x::Integer) = BFloat16sr(Float32(x))

Float64(x::BFloat16sr) = Float64(Float32(x))
Float16(x::BFloat16sr) = Float16(Float32(x))

# conversion between BFloat16 and BFloat16sr
BFloat16(x::BFloat16sr) = reinterpret(BFloat16,x)
BFloat16sr(x::BFloat16) = reinterpret(BFloat16sr,x)

# Truncation to integer types
Base.unsafe_trunc(T::Type{<:Integer}, x::BFloat16sr) = unsafe_trunc(T, Float32(x))

# Basic arithmetic
for f in (:+, :-, :*, :/, :^)
	@eval ($f)(x::BFloat16sr, y::BFloat16sr) = BFloat16_stochastic_round($(f)(Float32(x), Float32(y)))
end

# negation via signbit flip
-(x::BFloat16sr) = reinterpret(BFloat16sr, reinterpret(UInt16, x) ⊻ sign_mask(BFloat16sr))

# absolute value by setting the signbit to zero
abs(x::BFloat16sr) = reinterpret(BFloat16sr, reinterpret(UInt16, x) & 0x7fff)

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::BFloat16sr) = BFloat16_stochastic_round($func(Float32(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        $func(a::BFloat16sr,b::BFloat16sr) = BFloat16_stochastic_round($func(Float32(a),Float32(b)))
    end
end

# Floating point comparison
function Base.:(==)(x::BFloat16sr, y::BFloat16sr)
    ix = reinterpret(UInt16, x)
    iy = reinterpret(UInt16, y)
    # NaNs (isnan(x) || isnan(y))
    if (ix|iy)&~sign_mask(BFloat16sr) > exponent_mask(BFloat16sr)
        return false
    end
    # Signed zeros
    if (ix|iy)&~sign_mask(BFloat16sr) == 0
        return true
    end
    return ix == iy
end

function Base.:(<)(x::BFloat16sr, y::BFloat16sr)
	return Float32(x) < Float32(y)
end

function Base.:(<=)(x::BFloat16sr, y::BFloat16sr)
	return Float32(x) <= Float32(y)
end

function Base.:(>)(x::BFloat16sr, y::BFloat16sr)
	return Float32(x) > Float32(y)
end

function Base.:(>=)(x::BFloat16sr, y::BFloat16sr)
	return Float32(x) >= Float32(y)
end

widen(::Type{BFloat16sr}) = Float32

promote_rule(::Type{Float32}, ::Type{BFloat16sr}) = Float32
promote_rule(::Type{Float64}, ::Type{BFloat16sr}) = Float64

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
	@eval promote_rule(::Type{BFloat16sr}, ::Type{$t}) = BFloat16sr
end

# Wide multiplication
widemul(x::BFloat16sr, y::BFloat16sr) = Float32(x) * Float32(y)

# Showing
function show(io::IO, x::BFloat16sr)
    if isinf(x)
        print(io, x < 0 ? "-InfB16" : "InfB16")
    elseif isnan(x)
        print(io, "NaNB16")
    else
		io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"BFloat16sr("*f*")")
    end
end

bitstring(x::BFloat16sr) = bitstring(reinterpret(UInt16,x))

function bitstring(x::BFloat16sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
		return "$(s[1]) $(s[2:9]) $(s[10:end])"
    else
        return bitstring(x)
    end
end

function nextfloat(x::BFloat16sr)
    if isfinite(x)
		ui = reinterpret(UInt16,x)
		if ui < 0x8000	# positive numbers
			return reinterpret(BFloat16sr,ui+0x0001)
		elseif ui == 0x8000		# =-zero(T)
			return reinterpret(BFloat16sr,0x0001)
		else				# negative numbers
			return reinterpret(BFloat16sr,ui-0x0001)
		end
	else	# NaN / Inf case
		return x
	end
end

function prevfloat(x::BFloat16sr)
    if isfinite(x)
		ui = reinterpret(UInt16,x)
		if ui == 0x0000		# =zero(T)
			return reinterpret(BFloat16sr,0x8001)
		elseif ui < 0x8000	# positive numbers
			return reinterpret(BFloat16sr,ui-0x0001)
		else				# negative numbers
			return reinterpret(BFloat16sr,ui+0x0001)
		end
	else	# NaN / Inf case
		return x
	end
end
