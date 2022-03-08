"""The Float32 + stochastic rounding type."""
primitive type Float32sr <: AbstractFloat 32 end

# basic properties
Base.sign_mask(::Type{Float32sr}) = 0x8000_0000
Base.exponent_mask(::Type{Float32sr}) = 0x7f80_0000
Base.significand_mask(::Type{Float32sr}) = 0x007f_ffff
Base.precision(::Type{Float32sr}) = 24

"""Mask for both sign and exponent bits. Equiv to ~significand_mask(Float64)."""
signexp_mask(::Type{Float64}) = 0xfff0_0000_0000_0000

Base.one(::Type{Float32sr}) = reinterpret(Float32sr,one(Float32))
Base.zero(::Type{Float32sr}) = reinterpret(Float32sr,0x0000_0000)
Base.one(::Float32sr) = one(Float32sr)
Base.zero(::Float32sr) = zero(Float32sr)

Base.typemin(::Type{Float32sr}) = Float32sr(typemin(Float32))
Base.typemax(::Type{Float32sr}) = Float32sr(typemax(Float32))
Base.floatmin(::Type{Float32sr}) = Float32sr(floatmin(Float32))
Base.floatmax(::Type{Float32sr}) = Float32sr(floatmax(Float32))

Base.typemin(::Float32sr) = typemin(Float32sr)
Base.typemax(::Float32sr) = typemax(Float32sr)
Base.floatmin(::Float32sr) = floatmin(Float32sr)
Base.floatmax(::Float32sr) = floatmax(Float32sr)

Base.eps(::Type{Float32sr}) = Float32sr(eps(Float32))
Base.eps(x::Float32sr) = Float32sr(eps(Float32(x)))

const Inf32sr = reinterpret(Float32sr, Inf32)
const NaN32sr = reinterpret(Float32sr, NaN32)

# basic operations
Base.abs(x::Float32sr) = reinterpret(Float32sr, abs(reinterpret(Float32,x)))
Base.isnan(x::Float32sr) = isnan(reinterpret(Float32,x))
Base.isfinite(x::Float32sr) = isfinite(reinterpret(Float32,x))

Base.uinttype(::Type{Float32sr}) = UInt32
Base.nextfloat(x::Float32sr) = Float32sr(nextfloat(Float32(x)))
Base.prevfloat(x::Float32sr) = Float32sr(prevfloat(Float32(x)))

Base.:(-)(x::Float32sr) = reinterpret(Float32sr, reinterpret(UInt32, x) ⊻ Base.sign_mask(Float32sr))

# conversions
Base.Float32(x::Float32sr) = reinterpret(Float32,x)
Float32sr(x::Float32) = reinterpret(Float32sr,x)
Float32sr(x::Float16) = Float32sr(Float32(x))
Float32sr(x::Float64) = Float32sr(Float32(x))
Base.Float16(x::Float32sr) = Float16(Float32(x))
Base.Float64(x::Float32sr) = Float64(Float32(x))

Float32sr(x::Integer) = Float32sr(Float32(x))
(::Type{T})(x::Float32sr) where {T<:Integer} = T(Float32(x))

const eps_F32 = prevfloat(Float64(nextfloat(zero(Float32))))
const floatmin_F32 = Float64(floatmin(Float32))
const oneF64 = reinterpret(Int64,one(Float64))

"""Stochastically round x::Float64 to Float32 with distance-proportional probabilities."""
function Float32_stochastic_round(x::Float64)
    rbits = rand(Xor128[],UInt64)               # create random bits

    # subnormals are rounded with float-arithmetic for uniform stoch perturbation
    abs(x) < floatmin_F32 && return Float32sr(x+eps_F32*(reinterpret(Float64,oneF64 | (rbits >> 12))-1.5))

    ui = reinterpret(UInt64,x)
    ui += (rbits & 0x0000_0000_1fff_ffff)       # add stochastic perturbation in [0,u)
    ui &= 0xffff_ffff_e000_0000                 # round to zero 
    return reinterpret(Float32sr,Float32(reinterpret(Float64,ui)))
end

"""Chance that x::Float64 is round up when converted to Float32sr."""
function Float32_chance_roundup(x::Float64)
    xround = Float64(Float32(x))
    xround == x && return zero(Float64)
    xround_down, xround_up = xround < x ? (xround,Float64(nextfloat(Float32(xround)))) :
        (Float64(prevfloat(Float32(xround))),xround)
    
    return (x-xround_down)/(xround_up-xround_down)
end

# Promotion
Base.promote_rule(::Type{Float16}, ::Type{Float32sr}) = Float32
Base.promote_rule(::Type{Float64}, ::Type{Float32sr}) = Float64

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval Base.promote_rule(::Type{Float32sr}, ::Type{$t}) = Float32sr
end

# Rounding
Base.round(x::Float32sr, r::RoundingMode{:ToZero}) = Float32sr(round(Float32(x), r))
Base.round(x::Float32sr, r::RoundingMode{:Down}) = Float32sr(round(Float32(x), r))
Base.round(x::Float32sr, r::RoundingMode{:Up}) = Float32sr(round(Float32(x), r))
Base.round(x::Float32sr, r::RoundingMode{:Nearest}) = Float32sr(round(Float32(x), r))

# Comparison
for op in (:(==), :<, :<=, :isless)
    @eval Base.$op(a::Float32sr, b::Float32sr) = ($op)(Float32(a), Float32(b))
end

# Arithmetic
for f in (:+, :-, :*, :/, :^)
    @eval Base.$f(x::Float32sr, y::Float32sr) = Float32_stochastic_round($(f)(Float64(x), Float64(y)))
end

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::Float32sr) = Float32_stochastic_round($func(Float64(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        Base.$func(a::Float32sr,b::Float32sr) = Float32_stochastic_round($func(Float64(a),Float64(b)))
    end
end


# Showing
function Base.show(io::IO, x::Float32sr)
    if isinf(x)
        print(io, x < 0 ? "-Inf32sr" : "Inf32sr")
    elseif isnan(x)
        print(io, "NaN32sr")
    else
        io2 = IOBuffer()
        print(io2,Float32(x))
        f = String(take!(io2))
        print(io,"Float32sr("*f*")")
    end
end

Base.bitstring(x::Float32sr) = bitstring(reinterpret(UInt32,x))

function Base.bitstring(x::Float32sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
        return "$(s[1]) $(s[2:9]) $(s[10:end])"
    else
        return bitstring(x)
    end
end