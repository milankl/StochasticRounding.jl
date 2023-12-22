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
    da = Base.abs(d)
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