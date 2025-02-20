using Test
using Modland

# Test latlon_to_sinusoidal
@testset "latlon_to_sinusoidal tests" begin
    # Test with valid latitude and longitude
    @test latlon_to_sinusoidal(0.0, 0.0) == (0.0, 0.0)
    @test latlon_to_sinusoidal(45.0, 45.0) == (3.538204887918666e6, 5.003777338949354e6)
    
    # Test with out-of-bounds latitude
    @test_throws ErrorException latlon_to_sinusoidal(-91.0, 0.0)
    @test_throws ErrorException latlon_to_sinusoidal(91.0, 0.0)
    
    # Test with out-of-bounds longitude
    @test_throws ErrorException latlon_to_sinusoidal(0.0, -181.0)
    @test_throws ErrorException latlon_to_sinusoidal(0.0, 181.0)
end

# Test sinusoidal_to_modland
@testset "sinusoidal_to_modland tests" begin
    # Test with valid sinusoidal coordinates
    @test sinusoidal_to_modland(0.0, 0.0) == "h18v09"
    @test sinusoidal_to_modland(3.538204887918666e6, 5.003777338949354e6) == "h21v04"
    
    # Test with out-of-bounds sinusoidal coordinates
    @test_throws ErrorException sinusoidal_to_modland(UPPER_LEFT_X_METERS - 1, 0.0)
    @test_throws ErrorException sinusoidal_to_modland(LOWER_RIGHT_X_METERS + 1, 0.0)
    @test_throws ErrorException sinusoidal_to_modland(0.0, LOWER_RIGHT_Y_METERS - 1)
    @test_throws ErrorException sinusoidal_to_modland(0.0, UPPER_LEFT_Y_METERS + 1)
end