# Supports converting between stochastic floating points, and 
# adds support for converting an entire array of floats at a time

# conversion from other stochastic floating points to BFloat16sr
BFloat16sr(x::Float16sr) = BFloat16sr(Float32(x))
BFloat16sr(x::Float32sr) = BFloat16sr(Float32(x))

# Conversion of arrays as long as they are some kind of floating point number
function BFloat16sr(list::T where T<:AbstractArray{<:Union{BFloat16,AbstractFloat}})
    n = length(list)
    ret = zeros(BFloat16sr, n)
    for k in 1:n
        ret[k] = BFloat16sr(list[k])
    end
    return ret
end

# Conversions from other stochastic floating points to Float16sr
Float16sr(x::BFloat16sr) = Float16sr(Float32(x))
Float16sr(x::Float32sr) = Float16sr(Float64(x))

# Conversion of arrays as long as they are some kind of floating point number
function Float16sr(list::T where T<:AbstractArray{<:Union{BFloat16,AbstractFloat}})
    n = length(list)
    ret = zeros(Float16sr, n)
    for k in 1:n
        ret[k] = Float16sr(list[k])
    end
    return ret
end

# Conversions from other stochastic floating points to Float32sr
Float32sr(x::Float16sr) = Float32sr(Float32(x))
Float32sr(x::BFloat16sr) = Float32sr(Float32(x))

# Conversion of arrays as long as they are some kind of floating point number
function Float32sr(list::T where T<:AbstractArray{<:Union{BFloat16,AbstractFloat}})
    n = length(list)
    ret = zeros(Float32sr, n)
    for k in 1:n
        ret[k] = Float32sr(list[k])
    end
    return ret
end
