abstract type EarthGeometry end
abstract type EarthGeometry2D{T<:Real} <: EarthGeometry end
abstract type EarthGeometry3D{T<:Real} <: EarthGeometry end


###############################################################################

#Basic Geometric Primitives for Simple Shapes

###############################################################################

#See Wikipedia Definitions
#Regular ellipse/ellipsoid is n,r,t = 1
struct SuperEllipse2D{T} <: EarthGeometry2D{T}
    transformable::Bool
    n::T
end

SuperEllipse2D(n) = SuperEllipse2D(true, n)

function ingeometry(p::SuperEllipse2D{T}, xv::AbstractVector{T}) where T
    (x, z) = xv
    abs(x)^p.n + abs(z)^p.n <= 1
end

struct SuperEllipsoid3D{T} <: EarthGeometry3D{T}
    transformable::Bool
    r::T
    t::T
end

SuperEllipsoid3D(r, t) = SuperEllipsoid3D(true, r, t)

function ingeometry(p::SuperEllipsoid3D{T}, xv::AbstractVector{T}) where T
    (x, y, z) = xv
    (abs(x)^p.r + abs(y)^p.r)^(p.t/p.r) + abs(z)^p.t <= 1
end


struct Cuboid <: EarthGeometry
    transformable::Bool
end

Cuboid() = Cuboid(true) 

function ingeometry(p::Cuboid, xv)
    all(0 .<= xv .<= 1)
end

struct NoGeometry <: EarthGeometry
    transformable::Bool
end

NoGeometry() = NoGeometry(true)

ingeometry(p::NoGeometry, xv::AbstractVector{T}) where T = false

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


abstract type InterpolatedZeroLevelSet{T<:Real} <: EarthGeometry end


struct InterpolatedZeroLevelSet2D{T, IT} <: InterpolatedZeroLevelSet{T}
    transformable::Bool
    xs::Array{T,1}
    zs::Array{T,1}
    intrpfun::IT
end

InterpolatedZeroLevelSet2D(xs, zs, f) = InterpolatedZeroLevelSet2D(false, xs, zs,
                                                                   LinearInterpolation((xs, zs), f, 
                                                                                       extrapolation_bc = Line()))


struct InterpolatedZeroLevelSet3D{T, IT} <: InterpolatedZeroLevelSet{T}
    transformable::Bool
    xs::Array{T,1}
    ys::Array{T,1}
    zs::Array{T,1}
    intrpfun::IT
end

InterpolatedZeroLevelSet3D(xs, ys, zs, f) = InterpolatedZeroLevelSet3D(false, xs, ys, zs,
                                                                   LinearInterpolation((xs, ys, zs), f, 
                                                                                       extrapolation_bc = Line()))

function ingeometry(g::InterpolatedZeroLevelSet{T}, xv::AbstractVector{T}) where T
    g.intrpfun(xv...) > zero(T)
end





###############################################################################

#True / False Functions (useful for topography)

###############################################################################

struct TrueFalseFunction{F<:Function} <: EarthGeometry
    transformable::Bool
    tffun::F
end

TrueFalseFunction(tffun) = TrueFalseFunction(false, tffun)

function ingeometry(g::TrueFalseFunction, xv::AbstractVector{T}) where T
    g.tffun(xv)
end


###############################################################################

#Signed Planes (Useful for Faults) + helper functions

###############################################################################
abstract type SignedPlane{T<:Real} <: EarthGeometry end

struct SignedPlane3D{T} <: SignedPlane{T}
    transformable::Bool
    point::Array{T,1}
    #Normal points into the "true" side of plane
    normal::Array{T,1}
end

SignedPlane3D(point, normal) = (length(point) == length(normal) == 3) ? SignedPlane3D(false, point, normal) : error("Point and Normal must both have dimension 3")

function SignedPlane3D(point::Array{T,1}, strike::T, dip::T) where T
    @assert length(point) == 3 "Only supply Strike and Dip to 3D planes"
    @assert 0 <= strike <= 360 "Strike must be between 0 & 360 degrees"
    @assert 0 <= dip <= 90 "Dip must be between 0 & 90 degrees for the 3D plane"
    #Note that Z is down for this case
    SignedPlane3D(point, [cos(deg2rad(strike))*sin(deg2rad(dip)),-sin(deg2rad(strike))*sin(deg2rad(dip)), -cos(deg2rad(dip))])
end

#CHECK THIS NOT FINISHED
struct Signed2DVerticalPlane{T} <: SignedPlane{T}
    transformable::Bool
    point::Array{T, 1}
    normal::Array{T, 1}
    strike::T
end

function Signed2DVerticalPlane(point::Array{T,1}, strike::T) where T
    """
    This normal points 90 to the right of the given strike; ie if this plane were the San Andreas, 
    and we gave the strike as being 330 degrees, then the pacific plate would be in the geometry defined by the plane
    and the north american plate would be out
    """
    @assert length(point) == 2 "This function only supports 2D planes"
    @assert 0 <= strike <= 360 "Strike must be between 0 & 360 degrees"
    Signed2DVerticalPlane(false, point, [cos(deg2rad(strike)), -sin(deg2rad(strike))], strike)
end

struct Signed2DDippingPlane{T} <: SignedPlane{T}
    transformable::Bool
    point::Array{T, 1}
    normal::Array{T, 1}
    dip::T
end

function Signed2DDippingPlane(point::Array{T,1}, dip::T) where T
    """
    Dip is measured clockwise from the x direction. 
    Given the restriction on the dip, this function defines a plane such that the hanging wall of a 
    subvertical fault will be in the geometry defined by the plane, and the footwall will be out.
    Note that the Z axis is positive downward.
    """
    @assert length(point) == 2 "This function only supports 2D planes"
    @assert 0 <= dip <= 180 "Dip must be between 0 & 180 degrees for the 2D dipping plane"
    Signed2DDippingPlane(false, point, [sin(deg2rad(dip)), -cos(deg2rad(dip))], dip)
end

function ingeometry(g::SignedPlane{T}, xv::AbstractVector{T}) where T
    dot(g.normal, xv - g.point) > 0 
end

function faultslipvector(fault::SignedPlane3D{T}, rake::T, offset::T) where T
    #Direction of vector follows Aki-Richards convention for strike/dip/rake
    @assert -180 <= rake <= 180 "Rake must be between -180 and 180 degrees"
end

function faultslipvector(fault::Signed2DVerticalPlane{T}, offset::T; sense=:left) where T
    if sense == :left
        return Translation(offset*sin(deg2rad(fault.strike)), offset*cos(deg2rad(fault.strike)))
    elseif sense == :right
        return Translation(-offset*sin(deg2rad(fault.strike)), -offset*cos(deg2rad(fault.strike)))
    else
        error("Sense of fault must be :left or :right for a strike-slip fault in 2D")
    end
end

function faultslipvector(fault::Signed2DDippingPlane{T}, offset::T; sense=:normal) where T
    if sense == :normal
        return Translation( offset*cos(deg2rad(fault.dip)), offset*sin(deg2rad(fault.dip)))
    elseif sense == :reverse
        return Translation( -offset*cos(deg2rad(fault.dip)), -offset*sin(deg2rad(fault.dip)))
    else
        error("Sense of fault must be :normal or :reverse for a dipping fault in 2D")
    end
end
