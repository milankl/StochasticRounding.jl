# conversions
export stochastic_float
stochastic_float(x::AbstractFloat) = reinterpret(stochastic_float(typeof(x)),x)
Base.float(x::AbstractStochasticFloat) = reinterpret(float(typeof(x)),x)
uint(x::AbstractStochasticFloat) = reinterpret(Base.uinttype(typeof(x)),x)
Base.widen(x::AbstractStochasticFloat) = widen(typeof(x))(float(x))

# integer conversions
(::Type{T})(x::AbstractStochasticFloat) where {T<:Integer} = T(widen(x))
for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval Base.promote_rule(::Type{T}, ::Type{$t}) where {T<:AbstractStochasticFloat} = T
end

# other floats, irrational and rationals
(::Type{T})(x::Real) where {T<:AbstractStochasticFloat} = stochastic_float(float(T)(x))
(::Type{T})(x::Rational) where {T<:AbstractStochasticFloat} = stochastic_float(float(T)(x))
(::Type{T})(x::AbstractStochasticFloat) where {T<:AbstractFloat} = convert(T,float(x))
(::Type{T})(x::AbstractStochasticFloat) where {T<:AbstractStochasticFloat} = stochastic_float(convert(float(T),float(x)))
DoubleFloats.Double64(x::T) where T<:AbstractStochasticFloat = Double64(float(x))

# masks same as for deterministic floats
Base.sign_mask(T::Type{<:AbstractStochasticFloat}) = Base.sign_mask(float(T))
Base.exponent_mask(T::Type{<:AbstractStochasticFloat}) = Base.exponent_mask(float(T))
Base.significand_mask(T::Type{<:AbstractStochasticFloat}) = Base.significand_mask(float(T))
Base.precision(T::Type{<:AbstractStochasticFloat}) = precision(float(T))
Base.exponent_bits(T::Type{<:AbstractStochasticFloat}) = Base.exponent_bits(float(T))
Base.significand_bits(T::Type{<:AbstractStochasticFloat}) = Base.significand_bits(float(T))

# one, zero and rand(n) elements
Base.one(T::Type{<:AbstractStochasticFloat}) = stochastic_float(one(float(T)))
Base.zero(T::Type{<:AbstractStochasticFloat}) = stochastic_float(zero(float(T)))
Base.one(x::AbstractStochasticFloat) = stochastic_float(one(float(x)))
Base.zero(x::AbstractStochasticFloat) = stochastic_float(zero(float(x)))
Base.rand(T::Type{<:AbstractStochasticFloat}) = stochastic_float(rand(float(T)))
Base.randn(T::Type{<:AbstractStochasticFloat}) = stochastic_float(randn(float(T)))

# array generators
Base.rand(::Type{T},dims::Integer...) where {T<:AbstractStochasticFloat} = reinterpret.(T,rand(float(T),dims...))
Base.randn(::Type{T},dims::Integer...) where {T<:AbstractStochasticFloat} = reinterpret.(T,randn(float(T),dims...))
Base.zeros(::Type{T},dims::Integer...) where {T<:AbstractStochasticFloat} = reinterpret.(T,zeros(float(T),dims...))
Base.ones(::Type{T},dims::Integer...) where {T<:AbstractStochasticFloat} = reinterpret.(T,ones(float(T),dims...))

Base.iszero(x::AbstractStochasticFloat) = iszero(float(x))
Base.isfinite(x::AbstractStochasticFloat) = isfinite(float(x))
Base.isnan(x::AbstractStochasticFloat) = isnan(float(x))

nan(T::Type{<:AbstractStochasticFloat}) = T(NaN)
infinity(T::Type{<:AbstractStochasticFloat}) = T(Inf)

# dynamic range
Base.typemin(T::Type{<:AbstractStochasticFloat}) = stochastic_float(typemin(float(T)))
Base.typemax(T::Type{<:AbstractStochasticFloat}) = stochastic_float(typemax(float(T)))
Base.floatmin(T::Type{<:AbstractStochasticFloat}) = stochastic_float(floatmin(float(T)))
Base.floatmax(T::Type{<:AbstractStochasticFloat}) = stochastic_float(floatmax(float(T)))
Base.maxintfloat(T::Type{<:AbstractStochasticFloat}) = stochastic_float(maxintfloat(float(T)))

# smallest positive number (subnormal)
export minpos
minpos(T::Type{<:AbstractStochasticFloat}) = stochastic_float(reinterpret(float(T),Base.uinttype(T)(0x1)))
minpos(x::AbstractStochasticFloat) = minpos(typeof(x))

# dynamic range called with instance
Base.typemin(x::AbstractStochasticFloat) = typemin(typeof(x))
Base.typemax(x::AbstractStochasticFloat) = typemax(typeof(x))
Base.floatmin(x::AbstractStochasticFloat) = floatmin(typeof(x))
Base.floatmax(x::AbstractStochasticFloat) = floatmax(typeof(x))

Base.eps(T::Type{<:AbstractStochasticFloat}) = stochastic_float(eps(float(T)))
Base.eps(x::AbstractStochasticFloat) = stochastic_float(eps(float(x)))

# show
Base.show(io::IO, x::AbstractStochasticFloat) = show(io,float(x))
Base.bitstring(x::AbstractStochasticFloat) = bitstring(uint(x))

"""Like bitstring(x) but with bitstring(x,:split) showing the bits split
into sign, exponent and mantissa bits."""
function Base.bitstring(x::AbstractStochasticFloat,mode::Symbol)
    if mode == :split	# split into sign, exponent, signficand
        s = bitstring(x)
        ne = Base.exponent_bits(typeof(x))
        return "$(s[1]) $(s[2:ne+1]) $(s[ne+2:end])"
    else
        return bitstring(x)
    end
end

# same for BFloat16sr, but do not apply stochastic rounding to avoid InexactError
Base.round(x::AbstractStochasticFloat, r::RoundingMode{:Up}) = stochastic_float(ceil(float(x)))
Base.round(x::AbstractStochasticFloat, r::RoundingMode{:Down}) = stochastic_float(floor(float(x)))
Base.round(x::AbstractStochasticFloat, r::RoundingMode{:Nearest}) = stochastic_float(round(float(x)))
Base.round(x::AbstractStochasticFloat, r::RoundingMode{:ToZero}) = stochastic_float(round(float(x),RoundToZero))
Base.trunc(::Type{T},x::AbstractStochasticFloat) where T = trunc(T,float(x))

# negation, and absolute
Base.:(-)(x::AbstractStochasticFloat) = stochastic_float(-float(x))
Base.abs(x::AbstractStochasticFloat) = stochastic_float(abs(float(x)))

# stochastic rounding
export stochastic_round
stochastic_round(T::Type{<:AbstractFloat},x::Real) = stochastic_round(T,widen(stochastic_float(T))(x))
stochastic_round(T::Type{<:AbstractStochasticFloat},x::AbstractFloat) = stochastic_float(stochastic_round(float(T),x))

# Comparison
for op in (:(==), :<, :<=, :isless)
    @eval Base.$op(a::AbstractStochasticFloat, b::AbstractStochasticFloat) = ($op)(float(a), float(b))
end

# Arithmetic
for f in (:+, :-, :*, :/, :^, :mod, :atan, :hypot)
    @eval Base.$f(x::T, y::T) where {T<:AbstractStochasticFloat} = stochastic_round(T,$(f)(widen(x), widen(y)))
end

for func in (:sin,:cos,:tan,:asin,:acos,:atan,:sinh,:cosh,:tanh,:asinh,:acosh,
             :atanh,:exp,:exp2,:exp10,:expm1,:log,:log2,:log10,:sqrt,:cbrt,:log1p)
    @eval begin
        Base.$func(a::T) where {T<:AbstractStochasticFloat} = stochastic_round(T,$func(widen(a)))
    end
end

function Base.sincos(x::T) where {T<:AbstractStochasticFloat}
    s,c = sincos(widen(x))
    return (stochastic_round(T,s),stochastic_round(T,c))
end

Base.decompose(x::AbstractStochasticFloat) = Base.decompose(float(x))
Base.ldexp(x::AbstractStochasticFloat,n::Integer) = stochastic_float(Base.ldexp(float(x),n))

Base.nextfloat(x::AbstractStochasticFloat,n::Integer) = stochastic_float(nextfloat(float(x),n))
Base.prevfloat(x::AbstractStochasticFloat,n::Integer) = stochastic_float(prevfloat(float(x),n))

export chance_roundup
chance_roundup(T::Type{<:AbstractFloat},x::Real) = chance_roundup(stochastic_float(T),x)
function chance_roundup(T::Type{<:AbstractStochasticFloat},x::Real)
    x = widen(T)(x)
    xround = float(T)(x)
    (xround == x || isnan(x)) && return zero(float(T))
    xround_down, xround_up = xround < x ? (xround,nextfloat(xround)) :
        (prevfloat(xround),xround)
    
    return (x-xround_down)/(xround_up-xround_down)
end

