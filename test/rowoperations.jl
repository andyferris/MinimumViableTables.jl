@testset "Row operations" begin
    t = Table(a = [1,2,3])

    @test vcat(t,t)::Table == Table(a = [1,2,3,1,2,3])
    @test empty(t)::Table == Table(a = Int[])

    @test (empty!(t); t == Table(a = Int[]))
    @test (push!(t, (a=2,)); t == Table(a = [2]))
    @test (pushfirst!(t, (a=1,)); t == Table(a = [1,2]))
    @test (append!(t, Table(a=[3])); t == Table(a = [1,2,3]))
    @test (prepend!(t, copy(t)); t == Table(a = [1,2,3,1,2,3]))
    @test (deleteat!(t, 2); t == Table(a = [1,3,1,2,3]))
    @test (insert!(t, 2, (a=0,)); t == Table(a = [1,0,3,1,2,3]))
    
    @test splice!(t, 2, (a=-1,)) == (a=0,)
    @test t == Table(a = [1,-1,3,1,2,3])
    @test splice!(t, 2, Table(a = [-2])) == (a=-1,)
    @test t == Table(a = [1,-2,3,1,2,3])
    @test splice!(t, 2) == (a=-2,)
    @test t == Table(a = [1,3,1,2,3])
    
    @test splice!(t, 2:1, (a=-1,)) == Table(a = Int[])
    @test t == Table(a = [1,-1,3,1,2,3])
    @test splice!(t, 2:2, Table(a = [-2])) == Table(a = [-1])
    @test t == Table(a = [1,-2,3,1,2,3])
    @test splice!(t, 1:3) == Table(a=[1,-2,3])
    @test t == Table(a = [1,2,3])
    
    @test (resize!(t, 10); length(t) == 10)

end
