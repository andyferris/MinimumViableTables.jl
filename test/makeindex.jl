@testset "Index creation" begin
    t = Table(a = [11,12,12], b = [2,3,1], c = ["a", "b", "c"])

    @test NoIndex(t) === NoIndex()

    @test UniqueIndex{(:b,)}(t) === UniqueIndex{(:b,)}()

    @test (SortIndex{(:a,)}(t)::SortIndex{(:a,)}).order == [1, 2, 3]
    @test (SortIndex{(:a,:b)}(t)::SortIndex{(:a,:b)}).order == [1, 3, 2]

    @test (UniqueSortIndex{(:b,)}(t)::UniqueSortIndex{(:b,)}).order == [3, 1, 2]

    @test (HashIndex{(:a,)}(t)::HashIndex{(:a,)}).dict == Dict((11,) => [1], (12,) => [2, 3])
    @test (HashIndex{(:a,:b)}(t)::HashIndex{(:a,:b)}).dict == Dict((11, 2) => [1], (12, 3) => [2], (12, 1) => [3])

    @test (UniqueHashIndex{(:c,)}(t)::UniqueHashIndex{(:c,)}).dict == Dict(("a",) => 1, ("b",) => 2, ("c",) => 3)

    t2 = addindex(t, SortIndex{(:b,)})
    @test t2.indexes isa Tuple{SortIndex{(:b,)}}
    @test t2.indexes[1].order == [3, 1, 2]
end