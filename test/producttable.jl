@testset "ProductTable" begin
    t1 = Table(a=[1, 2])
    t2 = Table(b=[3.0, 4.0])

    t = ProductTable(t1, t2)
    @test ProductTable(t1, t2) === ProductTable{(:a, :b), NamedTuple{(:a, :b), Tuple{Int, Float64}}, typeof(t1), typeof(t2)}(t1, t2)
    
    @test t[1,1] === (a=1, b=3.0)
    @test t[2,1] === (a=2, b=3.0)
    @test t[1,2] === (a=1, b=4.0)
    @test t[2,2] === (a=2, b=4.0)

    @testset "Simple filtering of ProductTables" begin
    
    end

    @testset "Accelerated filtering of ProductTables" begin
        t1 = Table(id = [1,2,3], height = [1.78, 1.59, 1.90], age)

    end
end