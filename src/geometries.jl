abstract type EarthGeometry end
abstract type EarthGeometry2D <: EarthGeometry end
abstract type EarthGeometry3D <: EarthGeometry end


###############################################################################

#Basic Geometric Primitives for Simple Shapes

###############################################################################

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

###############################################################################

#Level Sets for Complicated Interfaces

###############################################################################


abstract type InterpolatedZeroLevelSet <: EarthGeometry end

struct InterpolatedZeroLevelSet2D <: InterpolatedZeroLevelSet
    transformable::Bool
    intrpfun
    InterpolatedZeroLevelSet2D(xs,zs,f) = new(false, CubicSplineInterpolation((xs, zs), f))
end

struct InterpolatedZeroLevelSet3D <: InterpolatedZeroLevelSet
    transformable::Bool
    intrpfun
    InterpolatedZeroLevelSet3D(xs,ys,zs,f) = new(false, CubicSplineInterpolation((xs, ys, zs), f))
end

function ingeometry(g::InterpolatedZeroLevelSet, xv)
    g.intrpfun[xv...] > 0
end

###############################################################################

#Signed Planes (Useful for Faults) + helper functions

###############################################################################

struct SignedPlane
    transformable::Bool
    point::Array{Float64,1}
    #Normal points into the "true" side of plane
    normal::Array{Float64,1}
    SignedPlane(point, normal) = length(point) == length(normal) ? new(false, point, normal) : error("Point and Normal must have same number of dimensions")
end

function SignedPlane(point::Array{Float64,1}, strike::Float64, dip::Float64)
    @assert length(point) == 3 "Only supply Strike and Dip to 3D planes"
    @assert 0 <= strike <= 360 "Strike must be between 0 & 360 degrees"
    @assert 0 <= dip <= 90 "Dip must be between 0 & 90 degrees"

end


function Signed2DVerticalPlane(point::Array{Float64,1}, strike::Float64)
    """
    This normal points 90 to the right of the given strike; ie if this plane were the San Andreas, 
    and we gave the strike as being 330 degrees, then the pacific plate would be in the geometry defined by the plane
    and the north american plate would be out
    """
    @assert length(point) == 2 "This function only supports 2D planes"
    @assert 0 <= strike <= 360 "Strike must be between 0 & 360 degrees"
    SignedPlane(point, [cos(deg2rad(strike), -sin(deg2rad(strike)))])
end

function Signed2DDippingPlane(point::Array{Float64,1}, dip::Float64)
    """
    Given the restriction on the dip, this function defines a plane such that the hanging wall of a 
    subvertical fault will be in the geometry defined by the plane, and the footwall will be out
    """
    @assert length(point) == 2 "This function only supports 2D planes"
    @assert 0 <= dip <= 90 "Dip must be between 0 & 90 degrees"
end

function ingeometry(g::SignedPlane, xv)
    dot(g.normal, xv - g.point) > 0 
end

function faultslip(fault::SignedPlane, rake::Float64, offset::Float64)
    if length(fault.normal) == 2
        rake = rake/abs(rake) #only sign will matter for 2D planes through 2D models (ie lines)
    end
end
