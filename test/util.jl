@testset "util" begin
    @testset "_issubset" begin
        @test _issubset((), ())
        @test _issubset((), (:a,))
        @test _issubset((:a,), (:a,))
        @test !_issubset((:a,), (:b,))
        @test !_issubset((:a,), ())
        @test _issubset((:a,:b), (:a,:b))
        @test _issubset((:a,:b), (:b,:a))
        @test !_issubset((:a,:b), (:a,))
        @test !_issubset((:a,:b), (:b,))
        @test _issubset((:a,), (:a,:b))
        @test _issubset((:b,), (:a,:b))
        @test !_issubset((:a,:b,:c), (:a,:b))
        @test _issubset((:a,:b), (:a,:b,:c))
    end

    @testset "_issetequal" begin
        @test _issetequal((), ())
        @test !_issetequal((), (:a,))
        @test _issetequal((:a,), (:a,))
        @test !_issetequal((:a,), (:b,))
        @test !_issetequal((:a,), ())
        @test _issetequal((:a,:b), (:a,:b))
        @test _issetequal((:a,:b), (:b,:a))
        @test !_issetequal((:a,:b), (:a,))
        @test !_issetequal((:a,:b), (:b,))
        @test !_issetequal((:a,), (:a,:b))
        @test !_issetequal((:b,), (:a,:b))
    end

    @testset "_headsubset" begin
        @test _headsubset((), ()) === ()
        @test _headsubset((), (:a,)) === ()
        @test _headsubset((), (:a, :b)) === ()

        @test _headsubset((:a,), ()) === ()
        @test _headsubset((:a,), (:a,)) === (:a,)
        @test _headsubset((:a,), (:b,)) === ()
        @test _headsubset((:a,), (:a, :b)) === (:a,)
        @test _headsubset((:a,), (:b, :a)) === (:a,)

        @test _headsubset((:a, :b), ()) === ()
        @test _headsubset((:a, :b), (:a,)) === (:a,)
        @test _headsubset((:a, :b), (:b,)) === ()
        @test _headsubset((:a, :b), (:a, :b)) === (:a, :b)
        @test _headsubset((:a, :b), (:b, :a)) === (:a, :b)
        @test _headsubset((:a, :b), (:a, :c)) === (:a,)
        @test _headsubset((:a, :b), (:b, :c)) === ()
        @test _headsubset((:a, :b), (:a, :b, :c)) === (:a, :b)
    end

    @testset "_makevectors" begin
        @test _makevectors(Tuple{Int, Float64}, (3,)) isa Tuple{Vector{Int}, Vector{Float64}}
        @test length(_makevectors(Tuple{Int, Float64}, (3,))[1]) === 3 
        @test length(_makevectors(Tuple{Int, Float64}, (3,))[2]) === 3 
    end

    @testset "_values" begin
        @test @inferred(_values((a=1,))) === (1,)
        @test @inferred(_values((a=1, b=2.0))) === (1, 2.0)
    end

    @testset "searchsorted" begin
        # Test both even and odd length vectors to ensure bitshift logic works in all cases
        @test searchsortedlastless([1,2,3], 0) === 0
        @test searchsortedlastless([1,2,3], 1) === 0
        @test searchsortedlastless([1,2,3], 2) === 1
        @test searchsortedlastless([1,2,3], 3) === 2
        @test searchsortedlastless([1,2,3], 4) === 3

        @test searchsortedlastless([1,2,3,4], 0) === 0
        @test searchsortedlastless([1,2,3,4], 1) === 0
        @test searchsortedlastless([1,2,3,4], 2) === 1
        @test searchsortedlastless([1,2,3,4], 3) === 2
        @test searchsortedlastless([1,2,3,4], 4) === 3
        @test searchsortedlastless([1,2,3,4], 5) === 4

        @test searchsortedfirstgreater([1,2,3], 0) === 1
        @test searchsortedfirstgreater([1,2,3], 1) === 2
        @test searchsortedfirstgreater([1,2,3], 2) === 3
        @test searchsortedfirstgreater([1,2,3], 3) === 4
        @test searchsortedfirstgreater([1,2,3], 4) === 4

        @test searchsortedfirstgreater([1,2,3,4], 0) === 1
        @test searchsortedfirstgreater([1,2,3,4], 1) === 2
        @test searchsortedfirstgreater([1,2,3,4], 2) === 3
        @test searchsortedfirstgreater([1,2,3,4], 3) === 4
        @test searchsortedfirstgreater([1,2,3,4], 4) === 5
        @test searchsortedfirstgreater([1,2,3,4], 5) === 5
    end

    @testset "_all" begin
        @test _all(&, (), ())
        @test _all(&, (true,), (true,))
        @test !_all(&, (false,), (true,))
        @test !_all(&, (true,), (false,))
        @test !_all(&, (false,), (false,))
        @test _all(&, (true, true), (true, true))
        @test !_all(&, (true, true, false), (true, true, true))
    end

    @testset "_valuetype" begin
        @test @inferred(_valuetype(NamedTuple{(:a,), Tuple{Int}})) == Tuple{Int}
        @test @inferred(_valuetype((a=1,))) == Tuple{Int}
    end

    @testset "_cat_types" begin
        @test @inferred(_cat_types(Tuple{Int, String}, Tuple{Float64, Nothing})) == Tuple{Int, String, Float64, Nothing}
end
