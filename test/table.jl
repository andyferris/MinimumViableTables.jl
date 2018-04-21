@testset "Unindexed table basics" begin 
    va = [1,   2,   3]
    vb = [2.0, 4.0, 6.0]
    t = Table{(:a, :b), NamedTuple{(:a,:b), Tuple{Int, Float64}}, Tuple{Vector{Int}, Vector{Float64}}, Tuple{}}((va, vb), ())

    @test Table(a = va, b = vb) === t
    @test Table((a = va, b = vb)) === t
    @test Table((a = va, b = vb), ()) === t
    @test Table{(:a, :b)}(b = vb, a = va) === t
    @test Table{(:a, :b)}((b = vb, a = va)) === t
    @test Table{(:a, :b)}((b = vb, a = va), ()) === t

    @test colnames(t) === (:a, :b)
    @test columns(t) === (a = va, b = vb)
    @test MinimumViableTables.getdata(t) === (va, vb)
    @test t.a === va
    @test t.b === vb
    @test_throws ErrorException t.c
    @test length(t) === 3
    @test size(t) === (3,)
    @test axes(t) === (Base.OneTo(3),)
    @test keys(t) === Base.OneTo(3)

    @test @inferred(t[1]) === (a = 1, b = 2.0)
    @test @inferred(t[2]) === (a = 2, b = 4.0)
    @test @inferred(t[3]) === (a = 3, b = 6.0)

    @test @inferred(first(t)) === (a = 1, b = 2.0)

    @test @inferred(similar(t)) isa typeof(t)
    @test @inferred(copy(t)) == t
    @test !(copy(t) === t)

    @test project(t, (:a,)) === Table(a = va)
    @test project(t, (:b,)) === Table(b = vb)
    @test project(t, (:b, :a)) === Table(b = vb, a = va)

    @test @inferred(Project((:a,))(t)) === Table(a = va)
    @test @inferred(Project((:b,))(t)) === Table(b = vb)
    @test @inferred(Project((:b, :a))(t)) === Table(b = vb, a = va)
end
