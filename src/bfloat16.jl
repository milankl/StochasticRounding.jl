# from BFloat16s.jl#main (22/12/23) to be removed with next release of BFloat16s.jl
function Base.nextfloat(f::BFloat16, d::Integer)

    F = typeof(f)
    fumax = reinterpret(Base.uinttype(F), F(Inf))
    U = typeof(fumax)

    isnan(f) && return f
    fi = reinterpret(Int16, f)
    fneg = fi < 0
    fu = unsigned(fi & typemax(fi))

    dneg = d < 0
    da = Base.uabs(d)
    if da > typemax(U)
        fneg = dneg
        fu = fumax
    else
        du = da % U
        if fneg ⊻ dneg
            if du > fu
                fu = min(fumax, du - fu)
                fneg = !fneg
            else
                fu = fu - du
            end
        else
            if fumax - fu < du
                fu = fumax
            else
                fu = fu + du
            end
        end
    end
    if fneg
        fu |= Base.sign_mask(F)
    end
    reinterpret(F, fu)
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

BFloat16s.BFloat16(x::BigFloat) = BFloat16(Float32(x))