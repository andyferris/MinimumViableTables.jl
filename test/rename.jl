@testset "Rename" begin
    @testset "Rename named tuples" begin
        @test rename((a = 1,), :a, :b) === (b = 1,)
        @test rename((a = 1,), :a, :a) === (a = 1,)
        @test rename((a = 1, c = 2.0), :a, :b) === (b = 1, c = 2.0)
        @test rename((a = 1, c = 2.0), (:a, :c), (:aa, :cc)) === (aa = 1, cc = 2.0)
        @test rename((a = 1, c = 2.0), (:a, :c), (:c, :a)) === (c = 1, a = 2.0)

        # Not sure if this one is correct or should throw an error...
        @test rename((a = 1,), :b, :a) === (a = 1,)

        @test_throws ErrorException rename((a = 1, c = 2.0), :a, :c)
    end

    @testset "Rename tables" begin
        va = [2,   3,   1]
        vb = [4.0, 6.0, 2.0]
        t = Table{(:a, :b), NamedTuple{(:a,:b), Tuple{Int, Float64}}, Tuple{Vector{Int}, Vector{Float64}}, Tuple{}}((va, vb), ())
        r = Rename(:a, :c)
        
        @test r(addindex(t, UniqueIndex{(:a,)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueIndex{(:b,)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueIndex{(:a,:b)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueIndex{(:b,:a)})) == Table(c = va, b = vb)

        @test r(addindex(t, SortIndex{(:a,)})) == Table(c = va, b = vb)
        @test r(addindex(t, SortIndex{(:b,)})) == Table(c = va, b = vb)
        @test r(addindex(t, SortIndex{(:a,:b)})) == Table(c = va, b = vb)
        @test r(addindex(t, SortIndex{(:b,:a)})) == Table(c = va, b = vb)

        @test r(addindex(t, UniqueSortIndex{(:a,)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueSortIndex{(:b,)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueSortIndex{(:a,:b)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueSortIndex{(:b,:a)})) == Table(c = va, b = vb)

        @test r(addindex(t, HashIndex{(:a,)})) == Table(c = va, b = vb)
        @test r(addindex(t, HashIndex{(:b,)})) == Table(c = va, b = vb)
        @test r(addindex(t, HashIndex{(:a,:b)})) == Table(c = va, b = vb)
        @test r(addindex(t, HashIndex{(:b,:a)})) == Table(c = va, b = vb)

        @test r(addindex(t, UniqueHashIndex{(:a,)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueHashIndex{(:b,)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueHashIndex{(:a,:b)})) == Table(c = va, b = vb)
        @test r(addindex(t, UniqueHashIndex{(:b,:a)})) == Table(c = va, b = vb)
    end
end