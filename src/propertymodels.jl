abstract type PropertyModel end

# UNIFORM MODELS #

struct UniformModel{T<:Real} <: PropertyModel
    α::T
    β::T
    ρ::T
end

UniformModel(α::T, β::T, ρ::T) where T = UniformModel{T}(α,β,ρ)

for prop = (:α, :β, :ρ)
    @eval $prop(pm::UniformModel{T}, x::T, z::T) where T = pm.$prop
    @eval $prop(pm::UniformModel{T}, x::T, y::T, z::T) where T = pm.$prop
end

# DEPTH GRADIENT MODELS #

struct DepthGradientModel{T<:Real} <: PropertyModel
    α0::T
    αg::T
    β0::T
    βg::T
    ρ0::T
    ρg::T
end

DepthGradientModel(α0::T, αg::T, β0::T, βg::T, ρ0::T, ρg::T) where T = DepthGradientModel{T}(α0, αg, β0, βg, ρ0, ρg)

#=
    The 0 is value of parameter at the surface if the layer was continued upwards
    These gradient models do not rescale if the model element rescales (ie if the element translates down)
    The velocity will tend to go up in the element rather than staying the same
    This is easier to compute...might also be more physically meaningful but that is yet to be seen
=#

for prop = (:α, :β, :ρ)
    p0 = Symbol(prop, :0)
    pg = Symbol(prop, :g)
    @eval $prop(pm::DepthGradientModel{T}, x::T, z::T) where T = pm.$p0 + pm.$pg*z
    @eval $prop(pm::DepthGradientModel{T}, x::T, y::T, z::T) where T = pm.$p0 + pm.$pg*z
end

# Depth Interpolated Models # 

struct DepthInterpolatedModel{T<:Real} <: PropertyModel
    zp::Array{T,1}
    αp::Array{T,1}
    βp::Array{T,1}
    ρp::Array{T,1}
    αintrp::LinearInterpolation{T,1}
    βintrp::LinearInterpolation{T,1}
    ρintrp::LinearInterpolation{T,1}
end

DepthInterpolatedModel(zp::Array{T,1}, 
                       αp::Array{T,1}, 
                       βp::Array{T,1}, 
                       ρp::Array{T,1}) where T = DepthInterpolatedModel{T}(zp, αp, βp, ρp, 
                                                                   LinearInterpolation(zp, αp, extrapolation_bc = Line()), 
                                                                   LinearInterpolation(zp, βp, extrapolation_bc = Line()),
                                                                   LinearInterpolation(zp, ρp, extrapolation_bc = Line()))

                                                                   
for prop = (:α, :β, :ρ)
    pintrp = Symbol(prop, :intrp)
    @eval $prop(pm::DepthInterpolatedModel{T}, x::T, z::T) where T = pm.$pintrp(z)
    @eval $prop(pm::DepthInterpolatedModel{T}, x::T, y::T, z::T) where T = pm.$pintrp(z)
end

#=
    A model that uniformly perturbs the velocities/densities of another background model
    Useful for tomography
    Doesn't actually ``look up'' model underneath so have to be sure that it is the same one
    This restriction makes the code a lot easier...
=#

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
    DepthInterpolatedModel(zp, αp, βp, ρp) = new(zp, αp, βp, ρp, LinearInterpolation((zp,), αp, extrapolation_bc = Line()), 
                                                                 LinearInterpolation((zp,), βp, extrapolation_bc = Line()),
                                                                 LinearInterpolation((zp,), ρp, extrapolation_bc = Line()))
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