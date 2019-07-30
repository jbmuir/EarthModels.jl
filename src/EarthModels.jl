module EarthModels

using CoordinateTransformations, Interpolations
if VERSION > v"0.7"
    using LinearAlgebra: dot
end

#primitives - shapes of objects
#Transformable geometries
export SuperEllipse2D, SuperEllipsoid3D, Cuboid 
#Static geometries
export InterpolatedZeroLevelSet2D, InterpolatedZeroLevelSet3D
export TrueFalseFunction
export SignedPlane, Signed2DVerticalPlane, Signed2DDippingPlane, faultslipvector

#relationships - some inbuilt parametrizations of seismic parameters 
export nd_ρ, br_β, ucvm1d_ρ, ucvm1d_β
#models - ways to describe the seismic parameters for a primitive
export UniformModel, DepthGradientModel, UniformPerturbationModel, DepthInterpolatedModel
#reference models (concrete examples using models/primitives/relationships that come up alot)
export UCVM1D
#assembly - build up primitives and property models into an assembled final model
export TransformedModelElement, StaticModelElement, BackgroundModelElement, ModelDeformation
export ModelAssembly
export inelement
export α, β, ρ

include("relationships.jl")
include("propertymodels.jl")
include("referencemodels.jl")
include("geometries.jl")
include("elements.jl")
include("assembly.jl")

end