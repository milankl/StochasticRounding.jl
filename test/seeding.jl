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