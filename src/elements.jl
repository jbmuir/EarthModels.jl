#material parameter lookup always based on absolute coordinates, but object geometry may be based on transformed coordinates...

abstract type ModelElement end

abstract type StructuralModelElement{T<:PropertyModel} <: ModelElement end

struct TransformedModelElement{T, G<:EarthGeometry, TR<:Transformation} <: StructuralModelElement{T}
    g::G
    a::TR
    ai::TR
    pm::T
end

TransformedModelElement(g, a, pm) = g.transformable == true ? TransformedModelElement(g, a, inv(a), pm) : error("Supplied a non-transformable geometry to TransformedModelElement")

struct StaticModelElement{T, G<:EarthGeometry} <: StructuralModelElement{T}
    g::G
    pm::T
end

DummyStaticElement = StaticModelElement(NoGeometry(),UniformModel(0.0,0.0,0.0))

struct BackgroundModelElement{T} <: StructuralModelElement{T}
    pm::T
end

function inelement(me::TransformedModelElement, xv::AbstractVector{T}) where T
    xvt = me.ai(xv)
    ingeometry(me.g, xvt)
end

function inelement(me::StaticModelElement, xv::AbstractVector{T}) where T
    ingeometry(me.g, xv)
end

for prop = (:α, :β, :ρ)
    @eval $prop(me::StructuralModelElement, xv::AbstractVector{T}) where T = $prop(me.pm, xv)
    @eval $prop(me::StructuralModelElement, x::T, z::T) where T = $prop(me.pm, x, z)
    @eval $prop(me::StructuralModelElement, x::T, y::T, z::T) where T = $prop(me.pm, x, y, z)
end

struct ModelDeformation{G<:EarthGeometry, TR<:Transformation} <: ModelElement
    g::G
    d::TR
    di::TR
end

ModelDeformation(g, d) = g.transformable == true ? ModelDeformation(g, d, inv(d)) : error("Supplied a static geometry to ModelDeformation")

function inelement(me::ModelDeformation, xv::AbstractVector{T}) where T
    ingeometry(me.g, xv)
end

DummyDeformation = ModelDeformation(NoGeometry(), IdentityTransformation(), IdentityTransformation())
