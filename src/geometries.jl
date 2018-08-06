abstract type EarthGeometry end
abstract type EarthGeometry2D <: EarthGeometry end
abstract type EarthGeometry3D <: EarthGeometry end

#See Wikipedia Definitions
#Regular ellipse/ellipsoid is n,r,t = 1
struct SuperEllipse2D <: EarthGeometry2D
    transformable::Bool
    n::Float64
    SuperEllipse2D(n) = new(true, n)
end

struct SuperEllipsoid3D <: EarthGeometry3D
    r::Float64
    t::Float64
    SuperEllipsoid3D(r, t) = new(true, r, t)
end

struct Cuboid <: EarthGeometry
    transformable::Bool
    Cuboid() = new(true)
end

function ingeometry(p::SuperEllipse2D, xv)
    (x, z) = xv
    abs(x)^p.n + abs(z)^p.n <= 1.0
end

function ingeometry(p::SuperEllipsoid3D, xv)
    (x, y, z) = xv
    (abs(x)^p.r + abs(y)^p.r)^(p.t/p.r) + abs(z)^p.t <= 1.0
end

function ingeometry(p::Cuboid, xv)
    all((0).<=xv.<=1)
end

# struct UnitZeroLevelSet <: EarthGeometry
#     transformable::Bool
#     f::Array{Float64}
#     UnitZeroLevelSet(f) = new(true, f)
# end

# function ingeometry(g::ZeroLevelSet, xv)
#     #xv in range 0<=xv<=1
#     R = CartesianRange(size(g.f))
#     I1 = first(R); Iend = last(R)
#     Ixv = CartesianIndex(convert.(Int,floor.(collect(size(g.f)).*xv))...)
#     xvi = true
#     for J in CartesianRange(max(I1,Ixv), min(Iend, Ixv+I1))
#         if g.f[J] < 0 
#             xvi = false
#         end
#     end
#     xvi
# end

abstract type InterpolatedZeroLevelSet <: EarthGeometry end

struct InterpolatedZeroLevelSet2D <: InterpolatedZeroLevelSet
    intrpfun
    InterpolatedZeroLevelSet2D(xs,zs,f) = new(CubicSplineInterpolation((xs, zs), f))
end

struct InterpolatedZeroLevelSet3D <: InterpolatedZeroLevelSet
    intrpfun
    InterpolatedZeroLevelSet3D(xs,ys,zs,f) = new(CubicSplineInterpolation((xs, ys, zs), f))
end

function ingeometry(g::InterpolatedZeroLevelSet, xv)
    g.intrpfun[xv...] > 0
end
