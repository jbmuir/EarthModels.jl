function UCVM1D()
    zp = [0.0, 1.0, 5.0, 6.0, 10.0, 15.5, 16.5, 22.0, 31.0, 33.0]
    αp = [5.0, 5.0, 5.5, 6.3, 6.3, 6.4, 6.7, 6.75, 6.8, 7.8]
    ρp = ucvm1d_ρ.(αp)
    βp = ucvm1d_β.(αp, ρp)
    DepthInterpolatedModel(zp, αp, βp, ρp)
end


