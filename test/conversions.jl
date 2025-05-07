@testset "Deterministic conversion of Stochastic FP to BFloat16sr" begin
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

@testset "Deterministic conversion of  Stochastic FP to Float16sr" begin
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

@testset "Deterministic conversion of  Stochastic FP to Float32sr" begin
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


@testset "Stochastic conversion of Float64 to $(SR)" for SR in [Float16sr, BFloat16sr, Float32sr]

    # corresponding FP type
    FP = float(SR)

    for k in 1:100
        trueVal = randn(Float64)

        # make sure that this is not representable by FP
        if trueVal == FP(trueVal)
            trueVal = nextfloat(trueVal)
        end

        roundedVal = SR(trueVal)

        # check that rounding is not deterministic
        is_stochastic = false
        for l in 1:10000
            if roundedVal != SR(trueVal)
                is_stochastic = true
                break
            end
        end

        # the redundant "== true" produces a better error message in the test log
        @test is_stochastic == true
    end
end
