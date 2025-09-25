module EnzymeExt

using Enzyme
using StochasticRounding
import StochasticRounding: stochastic_round

function Enzyme.typetree_inner(::Type{Float64sr}, ctx, dl, seen::Enzyme.Compiler.TypeTreeTable)
    return Enzyme.TypeTree(Enzyme.API.DT_Double, -1, ctx)
end

function Enzyme.get_offsets(::Type{Float64sr})
    return ((Enzyme.API.DT_Double, 0),)
end

function Enzyme.typetree_inner(::Type{Float32sr}, ctx, dl, seen::Enzyme.Compiler.TypeTreeTable)
    return Enzyme.TypeTree(Enzyme.API.DT_Float, -1, ctx)
end

function Enzyme.get_offsets(::Type{Float32sr})
    return ((Enzyme.API.DT_Float, 0),)
end

function Enzyme.typetree_inner(::Type{Float16sr}, ctx, dl, seen::Enzyme.Compiler.TypeTreeTable)
    return Enzyme.TypeTree(Enzyme.API.DT_Half, -1, ctx)
end

function Enzyme.get_offsets(::Type{Float16sr})
    return ((Enzyme.API.DT_Half, 0),)
end

import Enzyme: EnzymeRules
import Enzyme: Const, Duplicated

function EnzymeRules.forward(config, ::Const{typeof(stochastic_round)}, ::Type{<:DuplicatedNoNeed}, ::Const{Type{T}}, x::Duplicated) where T
    stochastic_round(T, x.dval)
end

function EnzymeRules.forward(config, ::Const{typeof(stochastic_round)}, ::Type{<:Duplicated}, ::Const{Type{T}}, x::Duplicated) where T
    Duplicated(
        stochastic_round(T, x.val),
        stochastic_round(T, x.dval)
    )
end

end # module
