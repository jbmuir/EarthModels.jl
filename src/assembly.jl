struct ModelAssembly
    background::BackgroundModelElement
    foreground::Array{ModelElement,1}
end

#+(a::ModelAssembly, b::ModelAssembly) = ModelAssembly(b.background, vcat(a.foreground, b.forground))

#material parameter lookup always based on absolute coordinates, but object geometry may be based on transformed coordinates...

abstract type ModelElement end

struct TransformedModelElement <: ModelElement
    g::EarthGeometry
    a::Transformation
    ai::Transformation
    pm::PropertyModel
    TransformedModelElement(g, a, pm) = g.transformable = true ? new(g, a, inv(a), pm) : error("Supplied a non-transformable geometry to TransformedModelElement")
end

struct StaticModelElement <: ModelElement
    g::EarthGeometry
    pm::PropertyModel
end

struct BackgroundModelElement <: ModelElement
    pm::PropertyModel
end


function inelement(me::TransformedModelElement, xv)
    xvt = me.ai(xv)
    ingeometry(me.g, xvt)
end

function inelement(me::StaticModelElement, xv)
    ingeometry(me.g, xv)
end

function getα(me::ModelElement, xv)
    getα(me.pm, xv)
end

function getβ(me::ModelElement, xv)
    getβ(me.pm, xv)
end

function getρ(me::ModelElement, xv)
    getρ(me.pm, xv)
end

function getα(m::ModelAssembly, xv)
    for me in m.foreground
        if inelement(me, xv)
            return getα(me, xv)
            break
        end
    end
    return getα(m.background, xv)
end

function getβ(m::ModelAssembly, xv)
    for me in m.foreground
        if inelement(me, xv)
            return getβ(me, xv)
            break
        end
    end
    return getβ(m.background, xv)
end

function getρ(m::ModelAssembly, xv)
    for me in m.foreground
        if inelement(me, xv)
            return getρ(me, xv)
            break
        end
    end
    return getρ(m.background, xv)
end

