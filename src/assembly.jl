
struct ModelAssembly
    deformations::Array{ModelDeformation,1}
    foreground::Array{ModelElement,1}
    background::BackgroundModelElement
end

#+(a::ModelAssembly, b::ModelAssembly) = ModelAssembly(b.background, vcat(a.foreground, b.forground))


function getα(m::ModelAssembly, xv)
    for md in m.deformations
        if inelement(md, xv)
            xv = md.ai(xv)
        end
    end
    for me in m.foreground
        if inelement(me, xv)
            return getα(me, xv)
            break
        end
    end
    return getα(m.background, xv)
end

function getβ(m::ModelAssembly, xv)
    for md in m.deformations
        if inelement(md, xv)
            xv = md.ai(xv)
        end
    end
    for me in m.foreground
        if inelement(me, xv)
            return getβ(me, xv)
            break
        end
    end
    return getβ(m.background, xv)
end

function getρ(m::ModelAssembly, xv)
    for md in m.deformations
        if inelement(md, xv)
            xv = md.ai(xv)
        end
    end
    for me in m.foreground
        if inelement(me, xv)
            return getρ(me, xv)
            break
        end
    end
    return getρ(m.background, xv)
end