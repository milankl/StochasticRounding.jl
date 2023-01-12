# always promote to the format that contains both
Base.promote_rule(::Type{Float16sr}, ::Type{Float32sr}) = Float32sr
Base.promote_rule(::Type{BFloat16sr}, ::Type{Float32sr}) = Float32sr
Base.promote_rule(::Type{Float16sr}, ::Type{BFloat16sr}) = Float32sr