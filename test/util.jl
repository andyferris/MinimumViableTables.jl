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
end
