# TODO this should be implemented upstream for various number formats
Base.ldexp(x::AbstractFloat,n::Integer) = x*2^n

# TODO remove here once implemented in BFloat16s.jl
function Base.nextfloat(x::BFloat16,n::Integer)
    n < 0 && return prevfloat(x,-n)
    n == 0 && return x
    nextfloat(nextfloat(x),n-1)
end

function Base.prevfloat(x::BFloat16,n::Integer)
    n < 0 && return nextfloat(x,-n)
    n == 0 && return x
    prevfloat(prevfloat(x),n-1)
end

function Base.decompose(x::BFloat16)::NTuple{3,Int}
    isnan(x) && return 0, 0, 0
    isinf(x) && return ifelse(x < 0, -1, 1), 0, 0
    n = reinterpret(UInt16, x)
    s = (n & 0x007f) % Int16
    e = ((n & 0x7f80) >> 7) % Int
    s |= Int16(e != 0) << 7
    d = ifelse(signbit(x), -1, 1)
    s, e - 134 + (e == 0), d
end