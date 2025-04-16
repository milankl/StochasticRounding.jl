# BFLOAT16 + STOCHASTIC ROUNDING, DEFINE EVERYTHING SPECIFIC
export BFloat16sr
primitive type BFloat16sr <: AbstractStochasticFloat 16 end
Base.float(::Type{BFloat16sr}) = BFloat16       # corresponding deterministic float
stochastic_float(::Type{BFloat16}) = BFloat16sr # and stochastic float
BFloat16sr(x::BFloat16) = stochastic_float(x)   # direct conversion
Base.uinttype(::Type{BFloat16sr}) = UInt16      # corresponding uint
Base.widen(::Type{BFloat16sr}) = Float32        # higher precision format for exact arithmetic

"""Stochastically round x::Float32 to BFloat16 with distance-proportional probabilities."""
function stochastic_round(T::Type{BFloat16},x::Float32)
    ui = reinterpret(UInt32,x)
    ui += rand(Xor128[],UInt16)							# add stochastic perturbation in [0,u)
    return reinterpret(BFloat16,(ui >> 16) % UInt16)	# round to zero and convert to BFloat16
end

# FLOAT16 + STOCHASTIC ROUNDING, DEFINE EVERYTHING SPECIFIC
export Float16sr
primitive type Float16sr <: AbstractStochasticFloat 16 end
Base.float(::Type{Float16sr}) = Float16         # corresponding deterministic float
stochastic_float(::Type{Float16}) = Float16sr   # and stochastic float
Float16sr(x::Float16) = stochastic_float(x)     # direct conversion
Base.uinttype(::Type{Float16sr}) = UInt16       # corresponding uint
Base.widen(::Type{Float16sr}) = Float32         # higher precision format for exact arithmetic

const FLOATMIN_F16 = Float32(floatmin(Float16))

"""
Stochastically round x::Float32 to Float16 with distance-proportional probabilities."""
function stochastic_round(T::Type{Float16},x::Float32)
    rbits = rand(Xor128[],UInt32)   # create random bits

    # subnormals are rounded with float-arithmetic for uniform stoch perturbation
    abs(x) < FLOATMIN_F16 && return Float16(x+rand_subnormal(rbits))
    
    # normals are stochastically rounded with integer arithmetic
    ui = reinterpret(UInt32,x)
    mask = 0x0000_1fff          # only mantissa bit 11-23 (the non-Float16 ones)
    ui += (rbits & mask)        # add perturbation in [0,u)
    ui &= ~mask                 # round to zero

    # via conversion to Float16 to adjust exponent bits
    return Float16(reinterpret(Float32,ui))
end

"""
    rand_subnormal(rbits::UInt32) -> Float32

Create a random perturbation for the Float16 subnormals for
stochastic rounding of Float32 -> Float16.
This function samples uniformly from [-2.980232f-8,2.9802319f-8].
= [-u/2,u/2].
This function is algorithmically similar to randfloat from RandomNumbers.jl"""
function rand_subnormal(rbits::UInt32)
    lz = leading_zeros(rbits)   # count leading zeros for correct probabilities of exponent
    e = ((101 - lz) % UInt32) << 23
    e |= (rbits << 31)          # use last bit for sign

    # combine exponent with random mantissa
    # the mask should be 0x007f_ffff but that can create a
    # Float16-representable number to be rounded away at very low chance
    # hence tweak the mask so that the largest perturbation is tiny bit smaller
    return reinterpret(Float32,e | (rbits & 0x007f_fdff))
end

# FLOAT32 + STOCHASTIC ROUNDING, DEFINE EVERYTHING SPECIFIC
export Float32sr
primitive type Float32sr <: AbstractStochasticFloat 32 end
Base.float(::Type{Float32sr}) = Float32
stochastic_float(::Type{Float32}) = Float32sr
Float32sr(x::Float32) = stochastic_float(x)
Base.uinttype(::Type{Float32sr}) = UInt32
Base.widen(::Type{Float32sr}) = Float64

const FLOATMIN_F32 = Float64(floatmin(Float32))

"""Stochastically round x::Float64 to Float32 with distance-proportional probabilities."""
function stochastic_round(T::Type{Float32},x::Float64)
    rbits = rand(Xor128[],UInt64)               # create random bits

    # subnormals are rounded with float-arithmetic for uniform stoch perturbation
    abs(x) < FLOATMIN_F32 && return Float32(x+rand_subnormal(rbits))

    # normals with integer arithmetic
    ui = reinterpret(UInt64,x)
    mask = 0x0000_0000_1fff_ffff
    ui += (rbits & mask)        # add stochastic perturbation in [0,u)
    ui &= ~mask                 # round to zero 
    return Float32(reinterpret(Float64,ui))
end

"""
    rand_subnormal(rbits::UInt64) -> Float64

Create a random perturbation for the Float16 subnormals for
stochastic rounding of Float32 -> Float16.
This function samples uniformly from [-7.0064923216240846e-46,7.006492321624084e-46].
This function is algorithmically similar to randfloat from RandomNumbers.jl"""
function rand_subnormal(rbits::UInt64)
    lz = leading_zeros(rbits)   # count leading zeros for probabilities of exponent
    e = ((872 - lz) % UInt64) << 52
    e |= (rbits << 63)          # use last bit for sign
    
    # combine exponent with random mantissa
    return reinterpret(Float64,e | (rbits & Base.significand_mask(Float64)))
end

# FLOAT32 + STOCHASTIC ROUNDING, DEFINE EVERYTHING SPECIFIC
export Float64sr
primitive type Float64sr <: AbstractStochasticFloat 64 end
Base.float(::Type{Float64sr}) = Float64
stochastic_float(::Type{Float64}) = Float64sr
Float64sr(x::Float64) = stochastic_float(x)
Base.uinttype(::Type{Float64sr}) = UInt64
Base.widen(::Type{Float64sr}) = Double64

"""Stochastically round x::Double64 to Float64 with distance-proportional probabilities."""
function stochastic_round(T::Type{Float64},x::Double64)
    rbits = rand(Xor128[],UInt64)   # create random bits
    
    # create [1,2)-1.5 = [-0.5,0.5)
    r = reinterpret(Float64,reinterpret(UInt64,one(Float64)) + (rbits >> 12)) - 1.5
    a = x.hi    # the more significant float64 in x
    b = x.lo    # the less significant float64 in x
    u = eps(a)  # = ulp

    return Float64(a + (b+u*r))    # (b+u*r) first as a+b would be rounded to a
end