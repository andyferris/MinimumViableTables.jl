@testset "Column operations" begin
    @test identity.(Table(a=[1,2,3]))::Table == Table(a=[1,2,3])
    @test map(identity, Table(a=[1,2,3]))::Table == Table(a=[1,2,3])

    @testset "merge" begin
        @test merge.(Table(a=[1,2,3], b=[3,4,5]))::Table == Table(a=[1,2,3], b=[3,4,5])
        @test merge.(Table(a=[1,2,3], b=[3,4,5]), Table(c = [5,6,7]))::Table == Table(a=[1,2,3], b=[3,4,5], c=[5,6,7])
    end
end