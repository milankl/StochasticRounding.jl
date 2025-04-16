# always promote to the format that contains both
Base.promote_rule(::Type{Float16sr}, ::Type{Float32sr}) = Float32sr
Base.promote_rule(::Type{BFloat16sr}, ::Type{Float32sr}) = Float32sr
Base.promote_rule(::Type{Float16sr}, ::Type{BFloat16sr}) = Float32sr

Base.promote_rule(::Type{Float16sr}, ::Type{Float64sr}) = Float64sr
Base.promote_rule(::Type{BFloat16sr}, ::Type{Float64sr}) = Float64sr
Base.promote_rule(::Type{Float32sr}, ::Type{Float64sr}) = Float64sr

# (to be extended for new formats)

# promotion between stochastic and deterministic floats yields deterministic
Base.promote_rule(::Type{S},::Type{D}) where {S<:AbstractStochasticFloat,D<:AbstractFloat} =
    promote_type(float(S),D)