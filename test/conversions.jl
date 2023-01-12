@testset "Converting Stochastic FP to BFloat16sr" begin
    for k in 1:100000
        trueVal = randn(Float64)
        # Convert to each deterministic type to ensure the result is 
        # representable in all precisions
        trueVal=Float16(Float32(BFloat16(trueVal)))
        bfloatVal = BFloat16sr(trueVal)
        float16Val = Float16sr(trueVal)
        float32Val = Float32sr(trueVal)
        # Since we are expanding out the floating point, there should be no
        # rounding so all these 3 should be the exact same numerically
        @test bfloatVal == BFloat16sr(float16Val)
        @test bfloatVal == BFloat16sr(float32Val)
    end
end

@testset "Converting Stochastic FP to Float16sr" begin
    for k in 1:100000
        trueVal = randn(Float64)
        # Convert to each deterministic type to ensure the result is 
        # representable in all precisions
        trueVal=Float16(Float32(BFloat16(trueVal)))
        bfloatVal = BFloat16sr(trueVal)
        float16Val = Float16sr(trueVal)
        float32Val = Float32sr(trueVal)
        # Since we are expanding out the floating point, there should be no
        # rounding so all these 3 should be the exact same numerically
        @test float16Val == Float16sr(bfloatVal)
        @test float16Val == Float16sr(float32Val)
    end
end

@testset "Converting Stochastic FP to Float32sr" begin
    for k in 1:100000
        trueVal = randn(Float64)
        # Convert to each deterministic type to ensure the result is 
        # representable in all precisions
        trueVal=Float16(Float32(BFloat16(trueVal)))
        bfloatVal = BFloat16sr(trueVal)
        float16Val = Float16sr(trueVal)
        float32Val = Float32sr(trueVal)
        # Since we are expanding out the floating point, there should be no
        # rounding so all these 3 should be the exact same numerically
        @test float32Val == Float32sr(bfloatVal)
        @test float32Val == Float32sr(float16Val)
    end
end
