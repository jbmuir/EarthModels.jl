abstract type PropertyModel{T<:Real} end

# UNIFORM MODELS #

struct UniformModel{T} <: PropertyModel{T}
    α::T
    β::T
    ρ::T
end

for prop = (:α, :β, :ρ)
    @eval $prop(pm::UniformModel{T}, xv::AbstractVector{T}) where T = pm.$prop
    @eval $prop(pm::UniformModel{T}, x::T, z::T) where T = pm.$prop
    @eval $prop(pm::UniformModel{T}, x::T, y::T, z::T) where T = pm.$prop
end

# DEPTH GRADIENT MODELS #

struct DepthGradientModel{T} <: PropertyModel{T}
    α0::T
    αg::T
    β0::T
    βg::T
    ρ0::T
    ρg::T
end

#=
    The 0 is value of parameter at the surface if the layer was continued upwards
    These gradient models do not rescale if the model element rescales (ie if the element translates down)
    The velocity will tend to go up in the element rather than staying the same
    This is easier to compute...might also be more physically meaningful but that is yet to be seen
=#

for prop = (:α, :β, :ρ)
    p0 = Symbol(prop, :0)
    pg = Symbol(prop, :g)
    @eval $prop(pm::DepthGradientModel{T}, xv::AbstractVector{T}) where T = pm.$p0 + pm.$pg*last(xv)
    @eval $prop(pm::DepthGradientModel{T}, x::T, z::T) where T = pm.$p0 + pm.$pg*z
    @eval $prop(pm::DepthGradientModel{T}, x::T, y::T, z::T) where T = pm.$p0 + pm.$pg*z
end

# Depth Power Law Models # 


struct DepthPowerLawModel{T} <: PropertyModel{T}
    z0::T
    α0::T
    αn::T
    β0::T
    βn::T
    ρ0::T
    ρn::T
end

for prop = (:α, :β, :ρ)
    p0 = Symbol(prop, :0)
    pn = Symbol(prop, :n)
    @eval $prop(pm::DepthGradientModel{T}, xv::AbstractVector{T}) where T = pm.$p0*(last(xv)/pm.z0)^$pn
    @eval $prop(pm::DepthGradientModel{T}, x::T, z::T) where T = pm.$p0*(z/pm.z0)^$pn
    @eval $prop(pm::DepthGradientModel{T}, x::T, y::T, z::T) where T = pm.$p0*(z/pm.z0)^$pn
end

# Depth Interpolated Models # 

struct DepthInterpolatedModel{T, IT} <: PropertyModel{T}
    zp::Array{T,1}
    αp::Array{T,1}
    βp::Array{T,1}
    ρp::Array{T,1}
    αintrp::IT
    βintrp::IT
    ρintrp::IT
end

DepthInterpolatedModel(zp, αp, βp, ρp) = DepthInterpolatedModel(zp, αp, βp, ρp, 
                                                                LinearInterpolation(zp, αp, extrapolation_bc = Line()), 
                                                                LinearInterpolation(zp, βp, extrapolation_bc = Line()),
                                                                LinearInterpolation(zp, ρp, extrapolation_bc = Line()))

                                                                   
for prop = (:α, :β, :ρ)
    pintrp = Symbol(prop, :intrp)
    @eval $prop(pm::DepthInterpolatedModel{T}, xv::AbstractVector{T}) where T = pm.$pintrp(last(xv))
    @eval $prop(pm::DepthInterpolatedModel{T}, x::T, z::T) where T = pm.$pintrp(z)
    @eval $prop(pm::DepthInterpolatedModel{T}, x::T, y::T, z::T) where T = pm.$pintrp(z)
end


# UNIFORM PERTURBATION MODELS # 

#=
    A model that uniformly perturbs the velocities/densities of another background model
    Useful for tomography
    Doesn't actually ``look up'' model underneath so have to be sure that it is the same one
    This restriction makes the code a lot easier...
=#

struct UniformPerturbationModel{T, PT<:PropertyModel{T}} <: PropertyModel{T}
    dα::T
    dβ::T
    dρ::T
    background::PT
end

for prop = (:α, :β, :ρ)
    dp = Symbol(:d, prop)
    @eval $prop(pm::UniformPerturbationModel{T}, xv::AbstractVector{T}) where T = (1+pm.$dp)*$prop(pm.background, xv)
    @eval $prop(pm::UniformPerturbationModel{T}, x::T, z::T) where T = (1+pm.$dp)*$prop(pm.background, x, z)
    @eval $prop(pm::UniformPerturbationModel{T}, x::T, y::T, z::T) where T = (1+pm.$dp)*$prop(pm.background, x, y, z)
end