@testset "Row operations" begin
    t = Table(a = [1,2,3])

    @test vcat(t,t) == Table(a = [1,2,3,1,2,3])
    @test empty(t) == Table(a = Int[])

    @test (empty!(t); t == Table(a = Int[]))
    @test (push!(t, (a=2,)); t == Table(a = [2]))
    @test (pushfirst!(t, (a=1,)); t == Table(a = [1,2]))
    @test (append!(t, Table(a=[3])); t == Table(a = [1,2,3]))
    @test (prepend!(t, copy(t)); t == Table(a = [1,2,3,1,2,3]))
    @test (resize!(t, 10); length(t) == 10)
end
