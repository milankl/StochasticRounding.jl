BFloat16s.BFloat16(x::BigFloat) = BFloat16(Float32(x))
Base.BigFloat(x::BFloat16) = BigFloat(Float32(x))