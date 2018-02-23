@testset "ProductArray" begin
    a = ProductArray(tuple, [1,2], [3.0,4.0])

    @test a isa ProductArray{Tuple{Int,Float64}, 2, typeof(tuple), Vector{Int}, Vector{Float64}}
    @test size(a) == (2,2)
    @test axes(a) === (Base.OneTo(2), Base.OneTo(2))
    @test a == [(1,3.0) (1,4.0); (2,3.0) (2,4.0)]
end
