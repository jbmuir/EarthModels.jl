#material parameter lookup always based on absolute coordinates, but object geometry may be based on transformed coordinates...

abstract type ModelElement end

abstract type StructuralModelElement <: ModelElement end

struct TransformedModelElement <: StructuralModelElement
    g::EarthGeometry
    a::Transformation
    ai::Transformation
    pm::PropertyModel
    TransformedModelElement(g, a, pm) = g.transformable == true ? new(g, a, inv(a), pm) : error("Supplied a non-transformable geometry to TransformedModelElement")
end

struct StaticModelElement <: StructuralModelElement
    g::EarthGeometry
    pm::PropertyModel
end

struct BackgroundModelElement <: StructuralModelElement
    pm::PropertyModel
end

function inelement(me::TransformedModelElement, xv)
    xvt = me.ai(xv)
    ingeometry(me.g, xvt)
end

function inelement(me::StaticModelElement, xv)
    ingeometry(me.g, xv)
end

function getα(me::StructuralModelElement, xv)
    getα(me.pm, xv)
end

function getβ(me::StructuralModelElement, xv)
    getβ(me.pm, xv)
end

function getρ(me::StructuralModelElement, xv)
    getρ(me.pm, xv)
end

struct ModelDeformation <: ModelElement
    g::EarthGeometry
    a::Transformation
    ai::Transformation
    ModelDeformation(mask, a) = g.transformable == true ? new(mas, a, inv(a)) : error("Supplied a non-transformable geometry to ModelDeformation")
end