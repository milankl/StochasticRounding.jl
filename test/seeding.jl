@testset "BFloat16sr seeding" begin
    StochasticRounding.seed(12312311)
    O = ones(BFloat16sr,10000)
    one_third = O/3

    # now reseed
    StochasticRounding.seed(12312311)
    @test O/3 == one_third
end

@testset "Float16sr seeding" begin
    StochasticRounding.seed(12312311)
    O = ones(Float16sr,10000)
    one_third = O/3

    # now reseed
    StochasticRounding.seed(12312311)
    @test O/3 == one_third
end

@testset "Float32sr seeding" begin
    StochasticRounding.seed(12312311)
    O = ones(Float32sr,10000)
    one_third = O/3

    # now reseed
    StochasticRounding.seed(12312311)
    @test O/3 == one_third
end
