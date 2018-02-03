@testset "Index creation" begin
    t = Table(a = [11,12,12], b = [2,3,1], c = ["a", "b", "c"])

    @test NoIndex(t) === NoIndex()

    @test UniqueIndex{(:b,)}(t) === UniqueIndex{(:b,)}()

    @test (SortIndex{(:a,)}(t)::SortIndex{(:a,)}).order == [1, 2, 3]
    @test (SortIndex{(:a,:b)}(t)::SortIndex{(:a,:b)}).order == [1, 3, 2]

    @test (UniqueSortIndex{(:b,)}(t)::UniqueSortIndex{(:b,)}).order == [3, 1, 2]

    @test (HashIndex{(:a,)}(t)::HashIndex{(:a,)}).dict == Dict((a = 11,) => [1], (a = 12,) => [2, 3])
    @test (HashIndex{(:a,:b)}(t)::HashIndex{(:a,:b)}).dict == Dict((a = 11, b = 2) => [1], (a = 12, b = 3) => [2], (a = 12, b = 1) => [3])

    @test (UniqueHashIndex{(:c,)}(t)::UniqueHashIndex{(:c,)}).dict == Dict((c = "a",) => 1, (c = "b",) => 2, (c = "c",) => 3)

    t2 = addindex(t, SortIndex{(:b,)})
    @test getindexes(t2) isa Tuple{SortIndex{(:b,)}}
    @test getindexes(t2)[1].order == [3, 1, 2]
end