"""The BFloat16 + stochastic rounding type."""
primitive type BFloat16sr <: AbstractFloat 16 end

Base.sign_mask(::Type{BFloat16sr}) = 0x8000
Base.exponent_mask(::Type{BFloat16sr}) = 0x7f80
Base.significand_mask(::Type{BFloat16sr}) = 0x007f

Base.iszero(x::BFloat16sr) = iszero(Float32(x))
Base.isfinite(x::BFloat16sr) = isfinite(Float32(x))
Base.isnan(x::BFloat16sr) = isnan(Float32(x))

Base.precision(::Type{BFloat16sr}) = 8
Base.one(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x3f80)
Base.zero(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x0000)

const InfB16sr = reinterpret(BFloat16sr, 0x7f80)
const NaNB16sr = reinterpret(BFloat16sr, 0x7fc0)

Base.typemin(::Type{BFloat16sr}) = -InfB16sr
Base.typemax(::Type{BFloat16sr}) = InfB16sr
Base.floatmin(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x0080)
Base.floatmax(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x7f7f)
minpos(::Type{BFloat16sr}) = reinterpret(BFloat16sr,0x0001)

Base.typemin(::BFloat16sr) = typemin(BFloat16sr)
Base.typemax(::BFloat16sr) = typemax(BFloat16sr)
Base.floatmin(::BFloat16sr) = floatmin(BFloat16sr)
Base.floatmax(::BFloat16sr) = floatmax(BFloat16sr)
minpos(::BFloat16sr) = minpos(BFloat16sr)

# Truncation from Float32
Base.uinttype(::Type{BFloat16sr}) = UInt16
Base.trunc(::Type{BFloat16sr}, x::Float32) = reinterpret(BFloat16sr,
        (reinterpret(UInt32, x) >> 16) % UInt16)

# same for BFloat16sr, but do not apply stochastic rounding to avoid InexactError
Base.round(x::BFloat16sr, r::RoundingMode{:Up}) = BFloat16sr(ceil(Float32(x)))
Base.round(x::BFloat16sr, r::RoundingMode{:Down}) = BFloat16sr(floor(Float32(x)))
Base.round(x::BFloat16sr, r::RoundingMode{:Nearest}) = BFloat16sr(round(Float32(x)))

# Conversions
"""Convert BFloat16sr to Float32 by padding trailing zeros."""
Base.Float32(x::BFloat16sr) = reinterpret(Float32, UInt32(reinterpret(UInt16, x)) << 16)

BFloat16sr(x::Float64) = BFloat16sr(Float32(x))
BFloat16sr(x::Float16) = BFloat16sr(Float32(x))
BFloat16sr(x::Integer) = BFloat16sr(Float32(x))

Base.Float64(x::BFloat16sr) = Float64(Float32(x))
Base.Float16(x::BFloat16sr) = Float16(Float32(x))

# conversion between BFloat16 and BFloat16sr
BFloat16(x::BFloat16sr) = reinterpret(BFloat16,x)
BFloat16sr(x::BFloat16) = reinterpret(BFloat16sr,x)

# conversion to integer
(::Type{T})(x::BFloat16sr) where {T<:Integer} = T(Float32(x))

"""Convert to BFloat16sr from Float32 via round-to-nearest
and tie to even. Identical to BFloat16(::Float32)."""
function BFloat16sr(x::Float32)
    isnan(x) && return NaNB16sr
    h = reinterpret(UInt32, x)
    h += 0x7fff + ((h >> 16) & 1)
    return reinterpret(BFloat16sr, (h >> 16) % UInt16)
end

"""Stochastically round x::Float32 to BFloat16 with distance-proportional probabilities."""
function BFloat16_stochastic_round(x::Float32)
    ui = reinterpret(UInt32,x)
    ui += rand(Xor128[],UInt16)							# add stochastic perturbation in [0,u)
    return reinterpret(BFloat16sr,(ui >> 16) % UInt16)	# round to zero and convert to BFloat16
end

"""Chance that x::Float32 is round up when converted to BFloat16sr."""
function BFloat16_chance_roundup(x::Float32)
    xround = Float32(BFloat16(x))
    xround == x && return zero(Float32)
    xround_down, xround_up = xround < x ? (xround,Float32(nextfloat(BFloat16sr(xround)))) :
        (Float32(prevfloat(BFloat16sr(xround))),xround)
    
    return (x-xround_down)/(xround_up-xround_down)
end

# Basic arithmetic
for f in (:+, :-, :*, :/, :^)
    @eval Base.$f(x::BFloat16sr, y::BFloat16sr) = BFloat16_stochastic_round($(f)(Float32(x), Float32(y)))
end

# negation via signbit flip
Base.:(-)(x::BFloat16sr) = reinterpret(BFloat16sr, reinterpret(UInt16, x) ⊻ 0x8000)

# absolute value by setting the signbit to zero
Base.abs(x::BFloat16sr) = reinterpret(BFloat16sr, reinterpret(UInt16, x) & 0x7fff)

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::BFloat16sr) = BFloat16_stochastic_round($func(Float32(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        Base.$func(a::BFloat16sr,b::BFloat16sr) = BFloat16_stochastic_round($func(Float32(a),Float32(b)))
    end
end

# Floating point comparison
function Base.:(==)(x::BFloat16sr, y::BFloat16sr)
    return BFloat16(x) == BFloat16(y)
end

for op in (:<, :<=, :isless)
    @eval Base.$op(a::BFloat16sr, b::BFloat16sr) = ($op)(Float32(a), Float32(b))
end

Base.promote_rule(::Type{Float32}, ::Type{BFloat16sr}) = Float32
Base.promote_rule(::Type{Float64}, ::Type{BFloat16sr}) = Float64

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval Base.promote_rule(::Type{BFloat16sr}, ::Type{$t}) = BFloat16sr
end

# Showing
function Base.show(io::IO, x::BFloat16sr)
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

Base.bitstring(x::BFloat16sr) = bitstring(reinterpret(UInt16,x))

function Base.bitstring(x::BFloat16sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
        return "$(s[1]) $(s[2:9]) $(s[10:end])"
    else
        return bitstring(x)
    end
end

function Base.nextfloat(x::BFloat16sr)
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

function Base.prevfloat(x::BFloat16sr)
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
