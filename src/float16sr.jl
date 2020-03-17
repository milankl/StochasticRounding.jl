

Float16(x::Integer) = convert(Float16, convert(Float32, x))

for t in (Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128)
    @eval promote_rule(::Type{Float16}, ::Type{$t}) = Float16
end

promote_rule(::Type{Float16}, ::Type{Bool}) = Float16

(::Type{T})(x::Float16) where {T<:Integer} = T(Float32(x))

# Float32 -> Float16 algorithm from:
#   "Fast Half Float Conversion" by Jeroen van der Zijp
#   ftp://ftp.fox-toolkit.org/pub/fasthalffloatconversion.pdf
#
# With adjustments for round-to-nearest, ties to even.
#
let _basetable = Vector{UInt16}(undef, 512),
    _shifttable = Vector{UInt8}(undef, 512)
    for i = 0:255
        e = i - 127
        if e < -25  # Very small numbers map to zero
            _basetable[i|0x000+1] = 0x0000
            _basetable[i|0x100+1] = 0x8000
            _shifttable[i|0x000+1] = 25
            _shifttable[i|0x100+1] = 25
        elseif e < -14  # Small numbers map to denorms
            _basetable[i|0x000+1] = 0x0000
            _basetable[i|0x100+1] = 0x8000
            _shifttable[i|0x000+1] = -e-1
            _shifttable[i|0x100+1] = -e-1
        elseif e <= 15  # Normal numbers just lose precision
            _basetable[i|0x000+1] = ((e+15)<<10)
            _basetable[i|0x100+1] = ((e+15)<<10) | 0x8000
            _shifttable[i|0x000+1] = 13
            _shifttable[i|0x100+1] = 13
        elseif e < 128  # Large numbers map to Infinity
            _basetable[i|0x000+1] = 0x7C00
            _basetable[i|0x100+1] = 0xFC00
            _shifttable[i|0x000+1] = 24
            _shifttable[i|0x100+1] = 24
        else  # Infinity and NaN's stay Infinity and NaN's
            _basetable[i|0x000+1] = 0x7C00
            _basetable[i|0x100+1] = 0xFC00
            _shifttable[i|0x000+1] = 13
            _shifttable[i|0x100+1] = 13
        end
    end
    global const shifttable = (_shifttable...,)
    global const basetable = (_basetable...,)
end

function Float16(val::Float32)
    f = reinterpret(UInt32, val)
    if isnan(val)
        t = 0x8000 ⊻ (0x8000 & ((f >> 0x10) % UInt16))
        return reinterpret(Float16, t ⊻ ((f >> 0xd) % UInt16))
    end
    i = ((f & ~significand_mask(Float32)) >> significand_bits(Float32)) + 1
    @inbounds sh = shifttable[i]
    f &= significand_mask(Float32)
    # If `val` is subnormal, the tables are set up to force the
    # result to 0, so the significand has an implicit `1` in the
    # cases we care about.
    f |= significand_mask(Float32) + 0x1
    @inbounds h = (basetable[i] + (f >> sh) & significand_mask(Float16)) % UInt16
    # round
    # NOTE: we maybe should ignore NaNs here, but the payload is
    # getting truncated anyway so "rounding" it might not matter
    nextbit = (f >> (sh-1)) & 1
    if nextbit != 0 && (h & 0x7C00) != 0x7C00
        # Round halfway to even or check lower bits
        if h&1 == 1 || (f & ((1<<(sh-1))-1)) != 0
            h += UInt16(1)
        end
    end
    reinterpret(Float16, h)
end

function Float32(val::Float16)
Float16(x::Float64) = Float16(Float32(x))
Bool(x::Float16) = x==0 ? false : x==1 ? true : throw(InexactError(:Bool, Bool, x))

round(x::Float16, r::RoundingMode{:ToZero}) = Float16(round(Float32(x), r))
round(x::Float16, r::RoundingMode{:Down}) = Float16(round(Float32(x), r))
round(x::Float16, r::RoundingMode{:Up}) = Float16(round(Float32(x), r))
round(x::Float16, r::RoundingMode{:Nearest}) = Float16(round(Float32(x), r))

promote_rule(::Type{Float32}, ::Type{Float16}) = Float32
promote_rule(::Type{Float64}, ::Type{Float16}) = Float64

-(x::Float16) = reinterpret(Float16, reinterpret(UInt16, x) ⊻ 0x8000)


widen(::Type{Float16}) = Float32

function ==(x::Float16, y::Float16)
    ix = reinterpret(UInt16,x)
    iy = reinterpret(UInt16,y)
    if (ix|iy)&0x7fff > 0x7c00 #isnan(x) || isnan(y)
        return false
    end
    if (ix|iy)&0x7fff == 0x0000
        return true
    end
    return ix == iy
end

for op in (:<, :<=, :isless)
    @eval ($op)(a::Float16, b::Float16) = ($op)(Float32(a), Float32(b))
end

abs(x::Float16) = reinterpret(Float16, reinterpret(UInt16, x) & 0x7fff)

isnan(x::Float16) = reinterpret(UInt16,x)&0x7fff > 0x7c00
isfinite(x::Float16) = reinterpret(UInt16,x)&0x7c00 != 0x7c00

precision(::Type{Float16}) = 11

nextfloat
prevfloat

typemin
typemax
floatmin
floatmax
eps
