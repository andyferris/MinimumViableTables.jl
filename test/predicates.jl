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

        va = [1,   2,   3]
        vb = [2.0, 4.0, 6.0]
        t = Table{(:a, :b), NamedTuple{(:a,:b), Tuple{Int, Float64}}, Tuple{Vector{Int}, Vector{Float64}}, Tuple{}}((va, vb), ())
        
        @test map(ie, t) == [true, false, false]
        @test findall(ie, t) == [1]
        @test filter(ie, t) == Table(a = [1], b = [2.0])

        t2a = addindex(t, UniqueIndex{(:a,)})
        @test map(ie, t2a) == [true, false, false]
        @test findall(ie, t2a) == [1]
        @test filter(ie, t2a) == Table(a = [1], b = [2.0])
        t2b = addindex(t, UniqueIndex{(:b,)})
        @test map(ie, t2b) == [true, false, false]
        @test findall(ie, t2b) == [1]
        @test filter(ie, t2b) == Table(a = [1], b = [2.0])
        t2ab = addindex(t, UniqueIndex{(:a,:b)})
        @test map(ie, t2ab) == [true, false, false]
        @test findall(ie, t2ab) == [1]
        @test filter(ie, t2ab) == Table(a = [1], b = [2.0])
        t2ba = addindex(t, UniqueIndex{(:b,:a)})
        @test map(ie, t2ba) == [true, false, false]
        @test findall(ie, t2ba) == [1]
        @test filter(ie, t2ba) == Table(a = [1], b = [2.0])
        
        t3a = addindex(t, SortIndex{(:a,)})
        @test map(ie, t3a) == [true, false, false]
        @test findall(ie, t3a) == [1]
        @test filter(ie, t3a) == Table(a = [1], b = [2.0])
        t3b = addindex(t, SortIndex{(:b,)})
        @test map(ie, t3b) == [true, false, false]
        @test findall(ie, t3b) == [1]
        @test filter(ie, t3b) == Table(a = [1], b = [2.0])
        t3ab = addindex(t, SortIndex{(:a,:b)})
        @test map(ie, t3ab) == [true, false, false]
        @test findall(ie, t3ab) == [1]
        @test filter(ie, t3ab) == Table(a = [1], b = [2.0])
        t3ba = addindex(t, SortIndex{(:b,:a)})
        @test map(ie, t3ba) == [true, false, false]
        @test findall(ie, t3ba) == [1]
        @test filter(ie, t3ba) == Table(a = [1], b = [2.0])
        
        t4a = addindex(t, UniqueSortIndex{(:a,)})
        @test map(ie, t4a) == [true, false, false]
        @test findall(ie, t4a) == [1]
        @test filter(ie, t4a) == Table(a = [1], b = [2.0])
        t4b = addindex(t, UniqueSortIndex{(:b,)})
        @test map(ie, t4b) == [true, false, false]
        @test findall(ie, t4b) == [1]
        @test filter(ie, t4b) == Table(a = [1], b = [2.0])
        t4ab = addindex(t, UniqueSortIndex{(:a,:b)})
        @test map(ie, t4ab) == [true, false, false]
        @test findall(ie, t4ab) == [1]
        @test filter(ie, t4ab) == Table(a = [1], b = [2.0])
        t4ba = addindex(t, UniqueSortIndex{(:b,:a)})
        @test map(ie, t4ba) == [true, false, false]
        @test findall(ie, t4ba) == [1]
        @test filter(ie, t4ba) == Table(a = [1], b = [2.0])
        
        t5a = addindex(t, HashIndex{(:a,)})
        @test map(ie, t5a) == [true, false, false]
        @test findall(ie, t5a) == [1]
        @test filter(ie, t5a) == Table(a = [1], b = [2.0])
        t5b = addindex(t, HashIndex{(:b,)})
        @test map(ie, t5b) == [true, false, false]
        @test findall(ie, t5b) == [1]
        @test filter(ie, t5b) == Table(a = [1], b = [2.0])
        t5ab = addindex(t, HashIndex{(:a,:b)})
        @test map(ie, t5ab) == [true, false, false]
        @test findall(ie, t5ab) == [1]
        @test filter(ie, t5ab) == Table(a = [1], b = [2.0])
        t5ba = addindex(t, HashIndex{(:b,:a)})
        @test map(ie, t5ba) == [true, false, false]
        @test findall(ie, t5ba) == [1]
        @test filter(ie, t5ba) == Table(a = [1], b = [2.0])
        
        t6a = addindex(t, UniqueHashIndex{(:a,)})
        @test map(ie, t6a) == [true, false, false]
        @test findall(ie, t6a) == [1]
        @test filter(ie, t6a) == Table(a = [1], b = [2.0])
        t6b = addindex(t, UniqueHashIndex{(:b,)})
        @test map(ie, t6b) == [true, false, false]
        @test findall(ie, t6b) == [1]
        @test filter(ie, t6b) == Table(a = [1], b = [2.0])
        t6ab = addindex(t, UniqueHashIndex{(:a,:b)})
        @test map(ie, t6ab) == [true, false, false]
        @test findall(ie, t6ab) == [1]
        @test filter(ie, t6ab) == Table(a = [1], b = [2.0])
        t6ba = addindex(t, UniqueHashIndex{(:b,:a)})
        @test map(ie, t6ba) == [true, false, false]
        @test findall(ie, t6ba) == [1]
        @test filter(ie, t6ba) == Table(a = [1], b = [2.0])
    end
end
