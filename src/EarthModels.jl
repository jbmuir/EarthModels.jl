module EarthModels

using CoordinateTransformations, Interpolations

#primitives - shapes of objects
export EarthPrimitive
export EarthPrimitive2D, EarthPrimitive3D
export SuperEllipse2D, SuperEllipsoid3D, Cuboid, ZeroLevelSet
#relationships - some inbuilt parametrizations of seismic parameters 
export nd_ρ, br_β, ucvm1d_ρ, ucvm1d_β
#models - ways to describe the seismic parameters for a primitive
export PropertyModel
export UniformModel, DepthGradientModel, BrocherModel, UniformPerturbationModel, DepthInterpolatedModel
#reference models (concrete examples using models/primitives/relationships that come up alot)
export UCVM1D
#assembly - build up primitives and property models into an assembled final model
export ModelElement
export ModelAssembly
export inelement
export getα, getβ, getρ


include("primitives.jl")
include("relationships.jl")
include("propertymodels.jl")
include("referencemodels.jl")
include("assembly.jl")

end