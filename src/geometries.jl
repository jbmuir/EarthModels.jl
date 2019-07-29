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
    transformable::Bool
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
    InterpolatedZeroLevelSet2D(xs,zs,f) = new(false, LinearInterpolation((xs, zs), f, extrapolation_bc = Line()))
end

struct InterpolatedZeroLevelSet3D <: InterpolatedZeroLevelSet
    transformable::Bool
    intrpfun
    InterpolatedZeroLevelSet3D(xs,ys,zs,f) = new(false, LinearInterpolation((xs, ys, zs), f, extrapolation_bc = Line()))
end

function ingeometry(g::InterpolatedZeroLevelSet, xv)
    g.intrpfun(xv...) > 0
end





###############################################################################

#True / False Functions (useful for topography)

###############################################################################

struct TrueFalseFunction <: EarthGeometry 
    transformable::Bool
    tffun
    TrueFalseFunction(tffun) = new(false, tffun)
end

function ingeometry(g::TrueFalseFunction, xv)
    g.tffun(xv)
end


###############################################################################

#Signed Planes (Useful for Faults) + helper functions

###############################################################################
abstract type SignedPlane <: EarthGeometry end

struct SignedPlane3D <: SignedPlane
    transformable::Bool
    point::Array{Float64,1}
    #Normal points into the "true" side of plane
    normal::Array{Float64,1}
    SignedPlane3D(point, normal) = (length(point) == length(normal) == 3) ? new(false, point, normal) : error("Point and Normal must both have dimension 3")
end

function SignedPlane3D(point::Array{Float64,1}, strike::Float64, dip::Float64)
    @assert length(point) == 3 "Only supply Strike and Dip to 3D planes"
    @assert 0 <= strike <= 360 "Strike must be between 0 & 360 degrees"
    @assert 0 <= dip <= 90 "Dip must be between 0 & 90 degrees for the 3D plane"
    #Note that Z is down for this case
    SignedPlane3D(point, [cos(deg2rad(strike))*sin(deg2rad(dip)),-sin(deg2rad(strike))*sin(deg2rad(dip)), -cos(deg2rad(dip))])
end

#CHECK THIS NOT FINISHED
struct Signed2DVerticalPlane <: SignedPlane
    transformable::Bool
    point::Array{Float64, 1}
    normal::Array{Float64, 1}
    strike::Float64
    function Signed2DVerticalPlane(point::Array{Float64,1}, strike::Float64)
        """
        This normal points 90 to the right of the given strike; ie if this plane were the San Andreas, 
        and we gave the strike as being 330 degrees, then the pacific plate would be in the geometry defined by the plane
        and the north american plate would be out
        """
        @assert length(point) == 2 "This function only supports 2D planes"
        @assert 0 <= strike <= 360 "Strike must be between 0 & 360 degrees"
        new(false, point, [cos(deg2rad(strike)), -sin(deg2rad(strike))], strike)
    end
end

struct Signed2DDippingPlane <: SignedPlane
    transformable::Bool
    point::Array{Float64, 1}
    normal::Array{Float64, 1}
    dip::Float64
    function Signed2DDippingPlane(point::Array{Float64,1}, dip::Float64)
        """
        Dip is measured clockwise from the x direction. 
        Given the restriction on the dip, this function defines a plane such that the hanging wall of a 
        subvertical fault will be in the geometry defined by the plane, and the footwall will be out.
        Note that the Z axis is positive downward.
        """
        @assert length(point) == 2 "This function only supports 2D planes"
        @assert 0 <= dip <= 180 "Dip must be between 0 & 180 degrees for the 2D dipping plane"
        new(false, point, [sin(deg2rad(dip)), -cos(deg2rad(dip))], dip)
    end
end

function ingeometry(g::SignedPlane, xv)
    dot(g.normal, xv - g.point) > 0 
end

function faultslipvector(fault::SignedPlane3D, rake::Float64, offset::Float64)
    #Direction of vector follows Aki-Richards convention for strike/dip/rake
    @assert -180.0 <= rake <= 180.0 "Rake must be between -180 and 180 degrees"
end

function faultslipvector(fault::Signed2DVerticalPlane, offset::Float64; sense=:left)
    if sense == :left
        return Translation(offset*sin(deg2rad(fault.strike)), offset*cos(deg2rad(fault.strike)))
    elseif sense == :right
        return Translation(-offset*sin(deg2rad(fault.strike)), -offset*cos(deg2rad(fault.strike)))
    else
        error("Sense of fault must be :left or :right for a strike-slip fault in 2D")
    end
end

function faultslipvector(fault::Signed2DDippingPlane, offset::Float64; sense=:normal)
    if sense == :normal
        return Translation( offset*cos(deg2rad(fault.dip)), offset*sin(deg2rad(fault.dip)))
    elseif sense == :reverse
        return Translation( -offset*cos(deg2rad(fault.dip)), -offset*sin(deg2rad(fault.dip)))
    else
        error("Sense of fault must be :normal or :reverse for a dipping fault in 2D")
    end
end
