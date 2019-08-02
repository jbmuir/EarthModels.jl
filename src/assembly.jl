struct ModelAssembly{T<:StaticModelElement, S<:ModelDeformation, U<:ModelElement, V<:BackgroundModelElement}
    topography::T
    deformations::Array{S,1}
    foreground::Array{U,1}
    background::V
end

ModelAssembly(background) = ModelAssembly(DummyStaticElement, [DummyDeformation], [DummyStaticElement], background)
ModelAssembly(topography, background) = ModelAssembly(topography, [DummyDeformation], [DummyStaticElement], background)
ModelAssembly(topography, foreground, background) = ModelAssembly(topography, [DummyDeformation], foreground, background)


#+(a::ModelAssembly, b::ModelAssembly) = ModelAssembly(b.background, vcat(a.foreground, b.forground))

for prop = (:α, :β, :ρ)
    @eval begin
        function $prop(m::ModelAssembly, xv::AbstractVector{T}) where T
            if inelement(m.topography, xv)
                return $prop(m.topography, xv)
            end
            for md in m.deformations
                if inelement(md, xv)
                    xv = md.di(xv)
                end
            end
            for me in m.foreground
                if inelement(me, xv)
                    return $prop(me, xv)
                    break
                end
            end
            return $prop(m.background, xv)
        end
    end
end
