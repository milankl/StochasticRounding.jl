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