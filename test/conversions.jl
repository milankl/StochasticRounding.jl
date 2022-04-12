import BFloat16s.BFloat16
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

@testset "Converting Arrays of Floating Points to BFloat16sr" begin
    # Note: All single conversions must work properly before this will
    # We iterate over a few dimensions (although small) to test differing sizes
    ngrid = 100:100:100000
    for n in ngrid
        trueList = randn(Float64,n)
        # Just as above, convert amongst the deterministic types to ensure representable in all
        # Use the builtin "." type conversions of arrays
        trueList = Float16.(Float32.(BFloat16.(trueList)))
        # Construct lists of differing Floating Points
        # Stochastic
        bfloatsrList = zeros(BFloat16sr,n)
        float16srList = zeros(Float16sr,n)
        float32srList = zeros(Float32sr,n)
        # Deterministic
        float16List = zeros(Float16,n)
        float32List = zeros(Float32,n)
        float64List = zeros(Float64,n)
        # Manually convert trueList to be the same type as the 6 previous lists of zeros
        for k in 1:n
            # Stochastic
            bfloatsrList[k] = BFloat16sr(trueList[k])
            float16srList[k] = Float16sr(trueList[k])
            float32srList[k] = Float32sr(trueList[k])
            # Deterministic
            float16List[k] = Float16(trueList[k])
            float32List[k] = Float32(trueList[k])
            float64List[k] = Float64(trueList[k])
        end
        # Now, we test if all the manually converted arrays are the same as the ones we defined
        @test bfloatsrList == BFloat16sr(trueList)
        @test bfloatsrList == BFloat16sr(float16srList)
        @test bfloatsrList == BFloat16sr(float32srList)
        @test bfloatsrList == BFloat16sr(float16List)
        @test bfloatsrList == BFloat16sr(float32List)
        @test bfloatsrList == BFloat16sr(float64List)
    end
end

@testset "Converting Arrays of Floating Points to Float16sr" begin
    # Note: All single conversions must work properly before this will
    # We iterate over a few dimensions (although small) to test differing sizes
    ngrid = 100:100:100000
    for n in ngrid
        trueList = randn(Float64,n)
        # Just as above, convert amongst the deterministic types to ensure representable in all
        # Use the builtin "." type conversions of arrays
        trueList = Float16.(Float32.(BFloat16.(trueList)))
        # Construct lists of differing Floating Points
        # Stochastic
        bfloatsrList = zeros(BFloat16sr,n)
        float16srList = zeros(Float16sr,n)
        float32srList = zeros(Float32sr,n)
        # Deterministic
        float16List = zeros(Float16,n)
        float32List = zeros(Float32,n)
        float64List = zeros(Float64,n)
        # Manually convert trueList to be the same type as the 6 previous lists of zeros
        for k in 1:n
            # Stochastic
            bfloatsrList[k] = BFloat16sr(trueList[k])
            float16srList[k] = Float16sr(trueList[k])
            float32srList[k] = Float32sr(trueList[k])
            # Deterministic
            float16List[k] = Float16(trueList[k]) # Float16(::BFloat16) is not defined
            float32List[k] = Float32(trueList[k])
            float64List[k] = Float64(trueList[k])
        end
        # Now, we test if all the manually converted arrays are the same as the ones we defined
        @test float16srList == Float16sr(bfloatsrList)
        @test float16srList == Float16sr(trueList)
        @test float16srList == Float16sr(float32srList)
        @test float16srList == Float16sr(float16List)
        @test float16srList == Float16sr(float32List)
        @test float16srList == Float16sr(float64List)
    end
end
@testset "Converting Arrays of Floating Points to Float32sr" begin
    # Note: All single conversions must work properly before this will
    # We iterate over a few dimensions (although small) to test differing sizes
    ngrid = 100:100:100000
    for n in ngrid
        trueList = randn(Float64,n)
        # Just as above, convert amongst the deterministic types to ensure representable in all
        # Use the builtin "." type conversions of arrays
        trueList = Float16.(Float32.(BFloat16.(trueList)))
        # Construct lists of differing Floating Points
        # Stochastic
        bfloatsrList = zeros(BFloat16sr,n)
        float16srList = zeros(Float16sr,n)
        float32srList = zeros(Float32sr,n)
        # Deterministic
        float16List = zeros(Float16,n)
        float32List = zeros(Float32,n)
        float64List = zeros(Float64,n)
        # Manually convert trueList to be the same type as the 6 previous lists of zeros
        for k in 1:n
            # Stochastic
            bfloatsrList[k] = BFloat16sr(trueList[k])
            float16srList[k] = Float16sr(trueList[k])
            float32srList[k] = Float32sr(trueList[k])
            # Deterministic
            float16List[k] = Float16(Float32(trueList[k])) # Float16(::BFloat16) is not defined
            float32List[k] = Float32(trueList[k])
            float64List[k] = Float64(trueList[k])
        end
        # Now, we test if all the manually converted arrays are the same as the ones we defined
        @test float32srList == Float32sr(bfloatsrList)
        @test float32srList == Float32sr(float16srList)
        @test float32srList == Float32sr(trueList)
        @test float32srList == Float32sr(float16List)
        @test float32srList == Float32sr(float32List)
        @test float32srList == Float32sr(float64List)
    end
end
