# conversion from other stochastic floating points to BFloat16sr
BFloat16sr(x::Float16sr) = BFloat16sr(Float32(x))
BFloat16sr(x::Float32sr) = BFloat16sr(Float32(x))

# Conversions from other stochastic floating points to Float16sr
Float16sr(x::BFloat16sr) = Float16sr(Float32(x))
Float16sr(x::Float32sr) = Float16sr(Float32(x))

# Conversions from other stochastic floating points to Float32sr
Float32sr(x::Float16sr) = Float32sr(Float32(x))
Float32sr(x::BFloat16sr) = Float32sr(Float32(x))
