"""The Float64 + stochastic rounding type."""
primitive type Float64sr <: AbstractFloat 64 end

# basic properties
Base.sign_mask(::Type{Float64sr}) = Base.sign_mask(Float64)
Base.exponent_mask(::Type{Float64sr}) = Base.exponent_mask(Float64)
Base.significand_mask(::Type{Float64sr}) = Base.significand_mask(Float64)
Base.precision(::Type{Float64sr}) = Base.precision(Float64)

Base.one(::Type{Float64sr}) = reinterpret(Float64sr,one(Float64))
Base.zero(::Type{Float64sr}) = reinterpret(Float64sr,zero(Float64))
Base.one(::Float64sr) = one(Float64sr)
Base.zero(::Float64sr) = zero(Float64sr)

Base.typemin(::Type{Float64sr}) = Float64sr(typemin(Float64))
Base.typemax(::Type{Float64sr}) = Float64sr(typemax(Float64))
Base.floatmin(::Type{Float64sr}) = Float64sr(floatmin(Float64))
Base.floatmax(::Type{Float64sr}) = Float64sr(floatmax(Float64))

Base.typemin(::Float64sr) = typemin(Float64sr)
Base.typemax(::Float64sr) = typemax(Float64sr)
Base.floatmin(::Float64sr) = floatmin(Float64sr)
Base.floatmax(::Float64sr) = floatmax(Float64sr)

Base.eps(::Type{Float64sr}) = Float64sr(eps(Float64))
Base.eps(x::Float64sr) = Float64sr(eps(Float64(x)))

const Infsr = reinterpret(Float64sr, Inf)
const NaNsr = reinterpret(Float64sr, NaN)

# basic operations
Base.abs(x::Float64sr) = reinterpret(Float64sr, abs(reinterpret(Float64,x)))
Base.isnan(x::Float64sr) = isnan(reinterpret(Float64,x))
Base.isfinite(x::Float64sr) = isfinite(reinterpret(Float64,x))

Base.uinttype(::Type{Float64sr}) = UInt64
Base.nextfloat(x::Float64sr) = Float64sr(nextfloat(Float64(x)))
Base.prevfloat(x::Float64sr) = Float64sr(prevfloat(Float64(x)))

Base.:(-)(x::Float64sr) = reinterpret(Float64sr, reinterpret(UInt64, x) ⊻ Base.sign_mask(Float64sr))

# conversions
Base.Float64(x::Float64sr) = reinterpret(Float64,x)
Float64sr(x::Float64) = reinterpret(Float64sr,x)
Float64sr(x::Float16) = Float64sr(Float64(x))
Float64sr(x::Float32) = Float64sr(Float64(x))
Base.Float16(x::Float64sr) = Float16(Float64(x))
Base.Float32(x::Float64sr) = Float32(Float64(x))

DoubleFloats.Double64(x::Float64sr) = Double64(Float64(x))

Float64sr(x::Integer) = Float64sr(Float64(x))
(::Type{T})(x::Float64sr) where {T<:Integer} = T(Float64(x))

"""Stochastically round x::Double64 to Float64 with distance-proportional probabilities."""
function Float64_stochastic_round(x::Double64)
    rbits = rand(Xor128[],UInt64)   # create random bits
    
    # create [1,2)-1.5 = [-0.5,0.5)
    r = reinterpret(Float64,reinterpret(UInt64,one(Float64)) + (rbits >> 12)) - 1.5
    a = x.hi    # the more significant float64 in x
    b = x.lo    # the less significant float64 in x
    u = eps(a)  # = ulp

    return Float64sr(a + (b+u*r))    # (b+u*r) first as a+b would be rounded to a
end

Base.promote_rule(::Type{Float16}, ::Type{Float64sr}) = Float64sr
Base.promote_rule(::Type{Float32}, ::Type{Float64sr}) = Float64sr
Base.promote_rule(::Type{Float64}, ::Type{Float64sr}) = Float64sr

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval Base.promote_rule(::Type{Float64sr}, ::Type{$t}) = Float64sr
end

# Rounding
Base.round(x::Float64sr, r::RoundingMode{:ToZero}) = Float64sr(round(Float64(x), r))
Base.round(x::Float64sr, r::RoundingMode{:Down}) = Float64sr(round(Float64(x), r))
Base.round(x::Float64sr, r::RoundingMode{:Up}) = Float64sr(round(Float64(x), r))
Base.round(x::Float64sr, r::RoundingMode{:Nearest}) = Float64sr(round(Float64(x), r))

# Comparison
for op in (:(==), :<, :<=, :isless)
    @eval Base.$op(a::Float64sr, b::Float64sr) = ($op)(Float64(a), Float64(b))
end

# Arithmetic
for f in (:+, :-, :*, :/, :^)
    @eval Base.$f(x::Float64sr, y::Float64sr) = Float64_stochastic_round($(f)(Double64(x), Double64(y)))
end

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::Float64sr) = Float64_stochastic_round($func(Float64(a)))
    end
end

for func in (:atan,:hypot)
    @eval begin
        Base.$func(a::Float64sr,b::Float64sr) = Float64_stochastic_round($func(Double64(a),Double64(b)))
    end
end


# Showing
function Base.show(io::IO, x::Float64sr)
    if isinf(x)
        print(io, x < 0 ? "-Infsr" : "Infsr")
    elseif isnan(x)
        print(io, "NaNsr")
    else
        io2 = IOBuffer()
        print(io2,Float64(x))
        f = String(take!(io2))
        print(io,"Float64sr("*f*")")
    end
end

Base.bitstring(x::Float64sr) = bitstring(reinterpret(UInt64,x))

function Base.bitstring(x::Float64sr,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
        return "$(s[1]) $(s[2:12]) $(s[13:end])"
    else
        return bitstring(x)
    end
end