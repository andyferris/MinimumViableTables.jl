@testset "Index" begin
    @testset "NoIndex" begin
        @test project(NoIndex(), ()) === NoIndex()
        @test project(NoIndex(), (:a,)) === NoIndex()
        @test project(NoIndex(), (:a, :b)) === NoIndex()
    end

    @testset "UniqueIndex" begin
        @test project(UniqueIndex{(:a, :b)}(), (:a, :b)) === UniqueIndex{(:a, :b)}()
        @test project(UniqueIndex{(:a, :b)}(), (:b, :a)) === UniqueIndex{(:a, :b)}()
        @test project(UniqueIndex{(:a, :b)}(), (:a,)) === NoIndex()
        @test project(UniqueIndex{(:a, :b)}(), (:b,)) === NoIndex()
    end

    @testset "SortIndex" begin
        v = [3,2,1]
        @test project(SortIndex{(:a, :b)}(v), (:a, :b)) === SortIndex{(:a, :b)}(v)
        @test project(SortIndex{(:a, :b)}(v), (:b, :a)) === SortIndex{(:a, :b)}(v)
        @test project(SortIndex{(:a, :b)}(v), (:a,)) === SortIndex{(:a,)}(v)
        @test project(SortIndex{(:a, :b)}(v), (:b,)) === NoIndex()
    end

    @testset "UniqueSortIndex" begin
        v = [3,2,1]
        @test project(UniqueSortIndex{(:a, :b)}(v), (:a, :b)) === UniqueSortIndex{(:a, :b)}(v)
        @test project(UniqueSortIndex{(:a, :b)}(v), (:b, :a)) === UniqueSortIndex{(:a, :b)}(v)
        @test project(UniqueSortIndex{(:a, :b)}(v), (:a,)) === SortIndex{(:a,)}(v)
        @test project(UniqueSortIndex{(:a, :b)}(v), (:b,)) === NoIndex()
    end

    @testset "HashIndex" begin
        d = Dict((3, 2.0) => [1, 3], (4, 1.0) => [2])
        @test project(HashIndex{(:a, :b)}(d), (:a, :b)) === HashIndex{(:a, :b)}(d)
        @test project(HashIndex{(:a, :b)}(d), (:b, :a)) === HashIndex{(:a, :b)}(d)
        @test project(HashIndex{(:a, :b)}(d), (:a,)) === NoIndex()
        @test project(HashIndex{(:a, :b)}(d), (:b,)) === NoIndex()
    end

    @testset "UniqueHashIndex" begin
        d = Dict((3, 2.0) => 1, (4, 1.0) => 2)
        @test project(UniqueHashIndex{(:a, :b)}(d), (:a, :b)) === UniqueHashIndex{(:a, :b)}(d)
        @test project(UniqueHashIndex{(:a, :b)}(d), (:b, :a)) === UniqueHashIndex{(:a, :b)}(d)
        @test project(UniqueHashIndex{(:a, :b)}(d), (:a,)) === NoIndex()
        @test project(UniqueHashIndex{(:a, :b)}(d), (:b,)) === NoIndex()
    end
end

@testset "Multiple indexes" begin
    @testset "Removing NoIndex" begin
        @test clean(()) === ()
        @test clean((NoIndex(),)) === ()
        @test clean((UniqueIndex{:a}(),)) === (UniqueIndex{:a}(),)
        @test clean((NoIndex(), UniqueIndex{:a}(), NoIndex(), UniqueIndex{:b}())) === (UniqueIndex{:a}(), UniqueIndex{:b}())
    end

    @testset "Projecting multiple indexes" begin
        p = Project{(:a,)}()
        
        @test p(()) === ()
        @test p((NoIndex(),)) === ()
        @test p((UniqueIndex{(:a,)}(),)) === (UniqueIndex{(:a,)}(),)
        @test p((UniqueIndex{(:b,)}(),)) === ()
        @test p((UniqueIndex{(:a,:b)}(),)) === ()
        @test p((UniqueIndex{(:a,)}(), UniqueIndex{(:b,)}())) === (UniqueIndex{(:a,)}(),)
    end
end
