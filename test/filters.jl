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

        va = [1,   2,   3]
        vb = [2.0, 4.0, 6.0]
        t = Table{(:a, :b), NamedTuple{(:a,:b), Tuple{Int, Float64}}, Tuple{Vector{Int}, Vector{Float64}}, Tuple{}}((va, vb), ())
        
        @test map(ie, t) == [true, false, false]

        t2a = addindex(t, UniqueIndex{(:a,)})
        @test map(ie, t2a) == [true, false, false]
        t2b = addindex(t, UniqueIndex{(:b,)})
        @test map(ie, t2b) == [true, false, false]
        t2ab = addindex(t, UniqueIndex{(:a,:b)})
        @test map(ie, t2ab) == [true, false, false]
        t2ba = addindex(t, UniqueIndex{(:b,:a)})
        @test map(ie, t2ba) == [true, false, false]

        t3a = addindex(t, SortIndex{(:a,)})
        @test map(ie, t3a) == [true, false, false]
        t3b = addindex(t, SortIndex{(:b,)})
        @test map(ie, t3b) == [true, false, false]
        t3ab = addindex(t, SortIndex{(:a,:b)})
        @test map(ie, t3ab) == [true, false, false]
        t3ba = addindex(t, SortIndex{(:b,:a)})
        @test map(ie, t3ba) == [true, false, false]

        t4a = addindex(t, UniqueSortIndex{(:a,)})
        @test map(ie, t4a) == [true, false, false]
        t4b = addindex(t, UniqueSortIndex{(:b,)})
        @test map(ie, t4b) == [true, false, false]
        t4ab = addindex(t, UniqueSortIndex{(:a,:b)})
        @test map(ie, t4ab) == [true, false, false]
        t4ba = addindex(t, UniqueSortIndex{(:b,:a)})
        @test map(ie, t4ba) == [true, false, false]

        t5a = addindex(t, HashIndex{(:a,)})
        @test map(ie, t5a) == [true, false, false]
        t5b = addindex(t, HashIndex{(:b,)})
        @test map(ie, t5b) == [true, false, false]
        t5ab = addindex(t, HashIndex{(:a,:b)})
        @test map(ie, t5ab) == [true, false, false]
        t5ba = addindex(t, HashIndex{(:b,:a)})
        @test map(ie, t5ba) == [true, false, false]

        t6a = addindex(t, UniqueHashIndex{(:a,)})
        @test map(ie, t5a) == [true, false, false]
        t6b = addindex(t, UniqueHashIndex{(:b,)})
        @test map(ie, t5b) == [true, false, false]
        t6ab = addindex(t, UniqueHashIndex{(:a,:b)})
        @test map(ie, t5ab) == [true, false, false]
        t6ba = addindex(t, UniqueHashIndex{(:b,:a)})
        @test map(ie, t5ba) == [true, false, false]
    end
end
