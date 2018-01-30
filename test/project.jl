@testset "project" begin
    @test project((a=1, b=2.0), (:a,)) === (a=1,)
    @test @inferred(Project((:a,))((a=1, b=2.0))) === (a=1,)
end
