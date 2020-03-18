primitive type Float16sr <: AbstractFloat 16 end		# stochastic rounding

# basic properties
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
isnan(x::Float16sr) = reinterpret(UInt16,x) & 0x7fff > 0x7c00
isfinite(x::Float16sr) = reinterpret(UInt16,x) & 0x7c00 != 0x7c00

nextfloat(x::Float16sr) = Float16sr(nextfloat(Float16(x)))
prevfloat(x::Float16sr) = Float16sr(prevfloat(Float16(x)))

-(x::Float16sr) = reinterpret(Float16sr, reinterpret(UInt16, x) ⊻ sign_mask(Float16sr))

# conversions
Float16(x::Float16sr) = reinterpret(Float16,x)
Float16sr(x::Float16) = reinterpret(Float16sr,x)
Float16sr(x::Float32) = Float16sr(Float16(x))	# deterministic
Float16sr(x::Float64) = Float16sr(Float32(x))
Float32(x::Float16sr) = Float32(Float16(x))
Float64(x::Float16sr) = Float64(Float16(x))

Float16sr(x::Integer) = Float16sr(Float32(x))
(::Type{T})(x::Float16sr) where {T<:Integer} = T(Float32(x))

# Float32 -> Float16 algorithm from:
#   "Fast Half Float Conversion" by Jeroen van der Zijp
#   ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
#
# With adjustments for round-to-nearest, ties to even.
#
let _basetable = Vector{UInt16}(undef, 512),
    _shifttable = Vector{UInt8}(undef, 512)
    for i = 0:255
        e = i - 127
        if e < -25  # Very small numbers map to zero
            _basetable[i|0x000+1] = 0x0000
            _basetable[i|0x100+1] = 0x8000
            _shifttable[i|0x000+1] = 25
            _shifttable[i|0x100+1] = 25
        elseif e < -14  # Small numbers map to denorms
            _basetable[i|0x000+1] = 0x0000
            _basetable[i|0x100+1] = 0x8000
            _shifttable[i|0x000+1] = -e-1
            _shifttable[i|0x100+1] = -e-1
        elseif e <= 15  # Normal numbers just lose precision
            _basetable[i|0x000+1] = ((e+15)<<10)
            _basetable[i|0x100+1] = ((e+15)<<10) | 0x8000
            _shifttable[i|0x000+1] = 13
            _shifttable[i|0x100+1] = 13
        elseif e < 128  # Large numbers map to Infinity
            _basetable[i|0x000+1] = 0x7C00
            _basetable[i|0x100+1] = 0xFC00
            _shifttable[i|0x000+1] = 24
            _shifttable[i|0x100+1] = 24
        else  # Infinity and NaN's stay Infinity and NaN's
            _basetable[i|0x000+1] = 0x7C00
            _basetable[i|0x100+1] = 0xFC00
            _shifttable[i|0x000+1] = 13
            _shifttable[i|0x100+1] = 13
        end
    end
    global const shifttable = (_shifttable...,)
    global const basetable = (_basetable...,)
end

const epsF16 = Float32(eps(Float16))
const epsF16_half = epsF16/2
const eps_quarter = 0x00004000						# a quarter of eps as Float32 sig bits
const F32_one = reinterpret(UInt32,one(Float32))
const F16floatmin = reinterpret(UInt32,Float32(floatmin(Float16)))
const sbitsF32 = 23

function Float16_stochastic_round(x::Float32)
	isnan(x) && return NaN16sr

	ui = reinterpret(UInt32, x)

	# stochastic rounding
	# e is the base 2 exponent of x (sign and signficand set to zero)
	e = reinterpret(Float32,ui & exponent_mask(Float32))

	# sig is the signficand (exponents & sign is masked out)
	sig = ui & significand_mask(Float32)

	# special case for rounding within 2^n <= x < 2^n+nextfloat(2^n)/4 due to doubling of eps towards nextfloat
	q = sig < eps_quarter

	# Check whether Float32 value would map to Float16 subnormals - no stochastic rounding in this case
	s = ui & ~sign_mask(Float32) < F16floatmin
	subnormal_mask = s ? 0f0 : 1f0

	frac = q ? reinterpret(Float32,F32_one | (sig << 10)) - 1f0 : 0.5f0
	eps = q ? epsF16_half : epsF16
	x += subnormal_mask*e*eps*(rand(Xor128,Float32) - frac)

	ui = reinterpret(UInt32,x)
	# change exponent bits
    i = ((ui & ~significand_mask(Float32)) >> sbitsF32) + 1
    @inbounds sh = shifttable[i]
    ui &= significand_mask(Float32)
    # If x is subnormal, the tables are set up to force the
    # result to 0, so the significand has an implicit `1` in the
    # cases we care about.
    ui |= significand_mask(Float32) + 0x1
    @inbounds h = (basetable[i] + (ui >> sh) & significand_mask(Float16sr)) % UInt16
    # round
    # NOTE: we maybe should ignore NaNs here, but the payload is
    # getting truncated anyway so "rounding" it might not matter
    nextbit = (ui >> (sh-1)) & 1
    if nextbit != 0 && (h & 0x7C00) != 0x7C00
        # Round halfway to even or check lower bits
        if h & 1 == 1 || (ui & ((1<<(sh-1))-1)) != 0
            h += UInt16(1)
        end
    end
    reinterpret(Float16sr, h)
end

function Float16_chance_roundup(x::Float32)
	isnan(x) && return NaN16sr
	ui = reinterpret(UInt32, x)
	# sig is the signficand (exponents & sign is masked out)
	sig = ui & significand_mask(Float32)
	frac = reinterpret(Float32,F32_one | (sig << 10)) - 1f0
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
