# TODO this should be implemented upstream for various number formats
Base.ldexp(x::AbstractFloat,n::Integer) = x*2^n