module EarthModels

using CoordinateTransformations, Interpolations

#primitives - shapes of objects
#Transformable geometries
export SuperEllipse2D, SuperEllipsoid3D, Cuboid 
#Static geometries
export InterpolatedZeroLevelSet2D, InterpolatedZeroLevelSet3D
export SignedPlane, Signed2DVerticalPlane, Signed2DDippingPlane, faultslip

#relationships - some inbuilt parametrizations of seismic parameters 
export nd_ρ, br_β, ucvm1d_ρ, ucvm1d_β
#models - ways to describe the seismic parameters for a primitive
export UniformModel, DepthGradientModel, BrocherModel, UniformPerturbationModel, DepthInterpolatedModel
#reference models (concrete examples using models/primitives/relationships that come up alot)
export UCVM1D
#assembly - build up primitives and property models into an assembled final model
export TransformedModelElement, StaticModelElement, BackgroundModelElement
export ModelAssembly
export inelement
export getα, getβ, getρ

include("relationships.jl")
include("propertymodels.jl")
include("referencemodels.jl")
include("geometries.jl")
include("elements.jl")
include("assembly.jl")

end