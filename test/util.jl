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
end
