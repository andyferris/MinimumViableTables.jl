@testset "predicates" begin
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

        va = [2,   3,   1]
        vb = [4.0, 6.0, 2.0]
        t = Table{(:a, :b), NamedTuple{(:a,:b), Tuple{Int, Float64}}, Tuple{Vector{Int}, Vector{Float64}}, Tuple{}}((va, vb), ())
        
        @test map(ie, t) == [false, false, true]
        @test findall(ie, t) == [3]
        @test filter(ie, t) == Table(a = [1], b = [2.0])

        t2a = addindex(t, UniqueIndex{(:a,)})
        @test map(ie, t2a) == [false, false, true]
        @test findall(ie, t2a) == [3]
        @test filter(ie, t2a) == Table(a = [1], b = [2.0])
        t2b = addindex(t, UniqueIndex{(:b,)})
        @test map(ie, t2b) == [false, false, true]
        @test findall(ie, t2b) == [3]
        @test filter(ie, t2b) == Table(a = [1], b = [2.0])
        t2ab = addindex(t, UniqueIndex{(:a,:b)})
        @test map(ie, t2ab) == [false, false, true]
        @test findall(ie, t2ab) == [3]
        @test filter(ie, t2ab) == Table(a = [1], b = [2.0])
        t2ba = addindex(t, UniqueIndex{(:b,:a)})
        @test map(ie, t2ba) == [false, false, true]
        @test findall(ie, t2ba) == [3]
        @test filter(ie, t2ba) == Table(a = [1], b = [2.0])
        
        t3a = addindex(t, SortIndex{(:a,)})
        @test map(ie, t3a) == [false, false, true]
        @test findall(ie, t3a) == [3]
        @test filter(ie, t3a) == Table(a = [1], b = [2.0])
        t3b = addindex(t, SortIndex{(:b,)})
        @test map(ie, t3b) == [false, false, true]
        @test findall(ie, t3b) == [3]
        @test filter(ie, t3b) == Table(a = [1], b = [2.0])
        t3ab = addindex(t, SortIndex{(:a,:b)})
        @test map(ie, t3ab) == [false, false, true]
        @test findall(ie, t3ab) == [3]
        @test filter(ie, t3ab) == Table(a = [1], b = [2.0])
        t3ba = addindex(t, SortIndex{(:b,:a)})
        @test map(ie, t3ba) == [false, false, true]
        @test findall(ie, t3ba) == [3]
        @test filter(ie, t3ba) == Table(a = [1], b = [2.0])
        
        t4a = addindex(t, UniqueSortIndex{(:a,)})
        @test map(ie, t4a) == [false, false, true]
        @test findall(ie, t4a) == [3]
        @test filter(ie, t4a) == Table(a = [1], b = [2.0])
        t4b = addindex(t, UniqueSortIndex{(:b,)})
        @test map(ie, t4b) == [false, false, true]
        @test findall(ie, t4b) == [3]
        @test filter(ie, t4b) == Table(a = [1], b = [2.0])
        t4ab = addindex(t, UniqueSortIndex{(:a,:b)})
        @test map(ie, t4ab) == [false, false, true]
        @test findall(ie, t4ab) == [3]
        @test filter(ie, t4ab) == Table(a = [1], b = [2.0])
        t4ba = addindex(t, UniqueSortIndex{(:b,:a)})
        @test map(ie, t4ba) == [false, false, true]
        @test findall(ie, t4ba) == [3]
        @test filter(ie, t4ba) == Table(a = [1], b = [2.0])
        
        t5a = addindex(t, HashIndex{(:a,)})
        @test map(ie, t5a) == [false, false, true]
        @test findall(ie, t5a) == [3]
        @test filter(ie, t5a) == Table(a = [1], b = [2.0])
        t5b = addindex(t, HashIndex{(:b,)})
        @test map(ie, t5b) == [false, false, true]
        @test findall(ie, t5b) == [3]
        @test filter(ie, t5b) == Table(a = [1], b = [2.0])
        t5ab = addindex(t, HashIndex{(:a,:b)})
        @test map(ie, t5ab) == [false, false, true]
        @test findall(ie, t5ab) == [3]
        @test filter(ie, t5ab) == Table(a = [1], b = [2.0])
        t5ba = addindex(t, HashIndex{(:b,:a)})
        @test map(ie, t5ba) == [false, false, true]
        @test findall(ie, t5ba) == [3]
        @test filter(ie, t5ba) == Table(a = [1], b = [2.0])
        
        t6a = addindex(t, UniqueHashIndex{(:a,)})
        @test map(ie, t6a) == [false, false, true]
        @test findall(ie, t6a) == [3]
        @test filter(ie, t6a) == Table(a = [1], b = [2.0])
        t6b = addindex(t, UniqueHashIndex{(:b,)})
        @test map(ie, t6b) == [false, false, true]
        @test findall(ie, t6b) == [3]
        @test filter(ie, t6b) == Table(a = [1], b = [2.0])
        t6ab = addindex(t, UniqueHashIndex{(:a,:b)})
        @test map(ie, t6ab) == [false, false, true]
        @test findall(ie, t6ab) == [3]
        @test filter(ie, t6ab) == Table(a = [1], b = [2.0])
        t6ba = addindex(t, UniqueHashIndex{(:b,:a)})
        @test map(ie, t6ba) == [false, false, true]
        @test findall(ie, t6ba) == [3]
        @test filter(ie, t6ba) == Table(a = [1], b = [2.0])
    end
end
