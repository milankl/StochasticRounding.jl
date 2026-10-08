@testset "Seeding" begin
    @testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
        StochasticRounding.seed(12312311)
        O = ones(T,10000)
        one_third = O/3

        # now reseed
        StochasticRounding.seed(12312311)
        @test O/3 == one_third
    end
end
@testset "Seeding with threads" begin
    @testset for T in (BFloat16sr, Float16sr, Float32sr, Float64sr)
        function thirds()
            O = ones(T, 1000, 16)
            Threads.@threads :static for j in axes(O, 2)
                O[:, j] ./= 3
            end
            return O
        end
        StochasticRounding.seed(12312311)
        one_third = thirds()
        StochasticRounding.seed(12312311)
        @test thirds() == one_third
        # every task draws its own random bits
        @test length(unique(eachcol(one_third))) > 1
    end
end
