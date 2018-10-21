abstract type PropertyModel end

struct UniformModel <: PropertyModel
    α::Float64
    β::Float64
    ρ::Float64
end

function getα(pm::UniformModel, xv)
    pm.α
end

function getβ(pm::UniformModel, xv)
    pm.β
end

function getρ(pm::UniformModel, xv)
    pm.ρ
end

struct DepthGradientModel <: PropertyModel
    α0::Float64
    αg::Float64
    β0::Float64
    βg::Float64
    ρ0::Float64
    ρg::Float64
end

#The 0 is value of parameter at the surface if the layer was continued upwards
#These gradient models do not rescale if the model element rescales (ie if the element translates down)
#The velocity will tend to go up in the element rather than staying the same
#This is easier to compute...might also be more physically meaningful but that is yet to be seen

function getα(pm::DepthGradientModel, xv)
    z = last(xv)
    pm.α0 + pm.αg*z
end

function getβ(pm::DepthGradientModel, xv)
    z = last(xv)
    pm.β0 + pm.βg*z
end

function getρ(pm::DepthGradientModel, xv)
    z = last(xv)
    pm.ρ0 + pm.ρg*z
end

# function getα(pm::DepthGradientModel, xv)
#     z = last(xv)
#     (-pm.α0 + pm.α1)*z
# end

# function getβ(pm::DepthGradientModel, xv)
#     z = last(xv)
#     (-pm.β0 + pm.β1)*z
# end

# function getρ(pm::DepthGradientModel, xv)
#     z = last(xv)
#     (-pm.ρ0 + pm.ρ1)*z
# end

#Models based on Brocher's Relationship parametrized by vp/\alpha

struct BrocherUniformModel <: PropertyModel
    α::Float64
end

function getα(pm::BrocherUniformModel, xv)
    pm.α
end

function getβ(pm::BrocherUniformModel, xv)
    br_β(pm.α)
end

function getρ(pm::BrocherUniformModel, xv)
    nd_ρ(pm.α)
end

struct BrocherGradientModel <: PropertyModel
    α0::Float64
    αg::Float64
end

function getα(pm::BrocherGradientModel, xv)
    z = last(xv)
    pm.α0 + pm.αg*z
end

function getβ(pm::BrocherGradientModel, xv)
    z = last(xv)
    br_β(pm.α0 + pm.αg*z)
end

function getρ(pm::BrocherGradientModel, xv)
    z = last(xv)
    nd_ρ(pm.α0 + pm.αg*z)
end

# Models parametrized by linear interpolation of fixed values at depth

struct DepthInterpolatedModel <: PropertyModel
    zp::Array{Float64,1}
    αp::Array{Float64,1}
    βp::Array{Float64,1}
    ρp::Array{Float64,1}
    αintrp
    βintrp
    ρintrp
    # DepthInterpolatedModel(zp, αp, βp, ρp) = new(zp, αp, βp, ρp, interpolate((zp,), αp, Gridded(Linear())), 
    #                                                              interpolate((zp,), βp, Gridded(Linear())),
    #                                                              interpolate((zp,), ρp, Gridded(Linear())))
    DepthInterpolatedModel(zp, αp, βp, ρp) = new(zp, αp, βp, ρp, LinearInterpolation((zp,), αp, extrapolation_bc = Interpolations.Linear()), 
                                                                 LinearInterpolation((zp,), βp, extrapolation_bc = Interpolations.Linear()),
                                                                 LinearInterpolation((zp,), ρp, extrapolation_bc = Interpolations.Linear()))
end

function getα(pm::DepthInterpolatedModel, xv)
    z = last(xv)
    pm.αintrp[z]
end

function getβ(pm::DepthInterpolatedModel, xv)
    z = last(xv)
    pm.βintrp[z]
end

function getρ(pm::DepthInterpolatedModel, xv)
    z = last(xv)
    pm.ρintrp[z]
end

# A model that uniformly perturbs the velocities/densities of another background model
# Useful for tomography
# Doesn't actually ``look up'' model underneath so have to be sure that it is the same one
# This restriction makes the code a lot easier...

struct UniformPerturbationModel <: PropertyModel
    dα::Float64
    dβ::Float64
    dρ::Float64
    background::PropertyModel
end

function getα(pm::UniformPerturbationModel, xv)
    (1+pm.dα)*getα(pm.background, xv)
end

function getβ(pm::UniformPerturbationModel, xv)
    (1+pm.dβ)*getβ(pm.background, xv)
end

function getρ(pm::UniformPerturbationModel, xv)
    (1+pm.dρ)*getρ(pm.background, xv)
end