abstract type EarthPrimitive end
abstract type EarthPrimitive2D <: EarthPrimitive end
abstract type EarthPrimitive3D <: EarthPrimitive end

#See Wikipedia Definitions
#Regular ellipse/ellipsoid is n,r,t = 1
struct SuperEllipse2D <: EarthPrimitive2D
    n::Float64
end

struct SuperEllipsoid3D <: EarthPrimitive3D
    r::Float64
    t::Float64
end

struct Cuboid <: EarthPrimitive
end

function inprimitive(p::SuperEllipse2D, xv)
    (x, z) = xv
    abs(x)^p.n + abs(z)^p.n <= 1.0
end

function inprimitive(p::SuperEllipsoid3D, xv)
    (x, y, z) = xv
    (abs(x)^p.r + abs(y)^p.r)^(p.t/p.r) + abs(z)^p.t <= 1.0
end

function inprimitive(p::Cuboid, xv)
    all((0).<=xv.<=1)
end

struct ZeroLevelSet <: EarthPrimitive
    f::Array{Float64}
end

function inprimitive(p::ZeroLevelSet, xv)
    #xv in range 0<=xv<=1
    R = CartesianRange(size(p.f))
    I1 = first(R); Iend = last(R)
    Ixv = CartesianIndex(convert.(Int,floor.(collect(size(p.f)).*xv))...)
    xvi = true
    for J in CartesianRange(max(I1,Ixv), min(Iend, Ixv+I1))
        if p.f[J] < 0 
            xvi = false
        end
    end
    xvi
end
