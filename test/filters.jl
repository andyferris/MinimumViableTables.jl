@testset "filters" begin
    @testset "IsEqual" begin
        ie = IsEqual{(:a, :b), Tuple{Int, Float64}}((1, 2.0))
        @test IsEqual(a=1, b=2.0) === ie

        @test ie((a=1, b=2.0)) === true
        @test ie((a=1, b=2.1)) === false
        @test ie((b=2.0, a=1)) === true
        @test ie((b=2.0, a=2)) === false
        @test ie((a=1, b=2.0, c=false)) === true
        @test ie((a=1, b=2.1, c=false)) === false
        @test_throws Exception ie((a=1))
    end
end
