struct ModelElement
    p::EarthPrimitive
    a::Transformation
    ai::Transformation
    pm::PropertyModel
    ModelElement(p, a, pm) = new(p, a, inv(a), pm)
end

struct ModelAssembly
    mel::Array{ModelElement,1}
end


function inelement(me::ModelElement, xv)
    xvp = me.ai(xv)
    inprimitive(me.p, xvp)
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
    for me in m.mel
        if inelement(me, xv)
            return getα(me, xv)
            break
        end
    end
    error("getα called for coordinates outside of model")
end

function getβ(m::ModelAssembly, xv)
    for me in m.mel
        if inelement(me, xv)
            return getβ(me, xv)
            break
        end
    end
    error("getβ called for coordinates outside of model")
end

function getρ(m::ModelAssembly, xv)
    for me in m.mel
        if inelement(me, xv)
            return getρ(me, xv)
            break
        end
    end
    error("getρ called for coordinates outside of model")
end

