primitive type BFloat16sr <: AbstractFloat 16 end		# stochastic rounding

# Floating point property queries
for f in (:sign_mask, :exponent_mask, :exponent_one,
            :exponent_half, :significand_mask)
    @eval $(f)(::Type{BFloat16sr}) = UInt16($(f)(Float32) >> 16)
end

iszero(x::BFloat16sr) = reinterpret(UInt16, x) & ~sign_mask(BFloat16sr) == 0x0000
isfinite(x::BFloat16sr) = (reinterpret(UInt16,x) & exponent_mask(BFloat16sr)) != exponent_mask(BFloat16sr)
isnan(x::BFloat16sr) = (reinterpret(UInt16,x) & ~sign_mask(BFloat16sr)) > exponent_mask(BFloat16sr)

precision(::Type{BFloat16sr}) = 8
one(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x3f80)
zero(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x0000)

const InfB16sr = reinterpret(BFloat16sr, 0x7f80)
const NaNB16sr = reinterpret(BFloat16sr, 0x7fc0)

# Truncation from Float32
Base.uinttype(::Type{BFloat16sr}) = UInt16
Base.trunc(::Type{BFloat16sr}, x::Float32) = reinterpret(BFloat16sr,
        (reinterpret(UInt32, x) >> 16) % UInt16
    )

# same for BFloat16sr, but do not apply stochastic rounding to avoid InexactError
round(x::BFloat16sr, r::RoundingMode{:Up}) = BFloat16sr(ceil(Float32(x)))
round(x::BFloat16sr, r::RoundingMode{:Down}) = BFloat16sr(floor(Float32(x)))
round(x::BFloat16sr, r::RoundingMode{:Nearest}) = BFloat16sr(round(Float32(x)))
Int64(x::BFloat16sr) = Int64(Float32(x))

"""
    epsBF16
Machine epsilon for BFloat16 as Float32.
"""
const epsBF16 = 0.0078125f0							# machine epsilon of BFloat16 as Float32
const epsBF16_half = epsBF16/2
const eps_quarter = 0x00004000						# a quarter of eps as Float32 sig bits
const F32_one = reinterpret(UInt32,one(Float32))

# Conversion from Float32 with deterministic rounding - identical to BFloat16(::Float32)
function BFloat16sr(x::Float32)
    isnan(x) && return NaNB16sr
	# Round to nearest even (matches TensorFlow and our convention for
    # rounding to lower precision floating point types).
    h = reinterpret(UInt32, x)
    h += 0x7fff + ((h >> 16) & 1)
    return reinterpret(BFloat16sr, (h >> 16) % UInt16)
end

# Conversion from Float32 with distance proportional stochastic rounding
# only used within arithmetic operations
function BFloat16_stochastic_round(x::Float32)
    isnan(x) && return NaNB16sr

	ui = reinterpret(UInt32, x)

	# stochastic rounding
	# e is the base 2 exponent of x (sign and signficand set to zero)
	e = reinterpret(Float32,ui & exponent_mask(Float32))

	# sig is the signficand (exponents & sign is masked out)
	sig = ui & significand_mask(Float32)

	# special case for rounding within 2^n <= x < 2^n+nextfloat(2^n)/4 due to doubling of eps towards nextfloat
	q = sig < eps_quarter
	frac = q ? reinterpret(Float32,F32_one | (sig << 7)) - 1f0 : 0.5f0
	eps = q ? epsBF16_half : epsBF16
	x += e*eps*(rand(Xor128,Float32) - frac)

    # Round to nearest after stochastic perturbation
	ui = reinterpret(UInt32, x)
    ui += 0x7fff + ((ui >> 16) & 1)
    return reinterpret(BFloat16sr, (ui >> 16) % UInt16)
end

function BFloat16_chance_roundup(x::Float32)
    isnan(x) && return NaNB16sr
	ui = reinterpret(UInt32, x)
	# sig is the signficand (exponents & sign is masked out)
	sig = ui & significand_mask(Float32)
	frac = reinterpret(Float32,F32_one | (sig << 7)) - 1f0
    return frac
end

# Conversion from Float64
function BFloat16sr(x::Float64)
	BFloat16sr(Float32(x))
end

# Conversion from Integer
function BFloat16sr(x::Integer)
	convert(BFloat16sr, convert(Float32, x))
end

# Expansion to Float32 - no rounding applied
function Base.Float32(x::BFloat16sr)
    reinterpret(Float32, UInt32(reinterpret(UInt16, x)) << 16)
end

# Expansion to Float64
function Base.Float64(x::BFloat16sr)
    Float64(Float32(x))
end

# conversion between BFloat16 and BFloat16sr
BFloat16(x::BFloat16sr) = reinterpret(BFloat16,x)
BFloat16sr(x::BFloat16) = reinterpret(BFloat16sr,x)
# Base.promote_rule(::Type{BFloat16}, ::Type{BFloat16sr}) = BFloat16

# Truncation to integer types
Base.unsafe_trunc(T::Type{<:Integer}, x::BFloat16sr) = unsafe_trunc(T, Float32(x))

# Basic arithmetic
for f in (:+, :-, :*, :/, :^)
	@eval ($f)(x::BFloat16sr, y::BFloat16sr) = BFloat16_stochastic_round($(f)(Float32(x), Float32(y)))
end

-(x::BFloat16sr) = reinterpret(BFloat16sr, reinterpret(UInt16, x) ⊻ sign_mask(BFloat16sr))

# bit-wise & with ~sign_mask
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
