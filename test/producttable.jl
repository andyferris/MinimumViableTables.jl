@testset "ProductTable" begin
    t1 = Table(a=[1, 2])
    t2 = Table(b=[3.0, 4.0])

    t = ProductTable(t1, t2)
    @test ProductTable(t1, t2) === ProductTable{(:a, :b), NamedTuple{(:a, :b), Tuple{Int, Float64}}, typeof(t1), typeof(t2)}(t1, t2)
    @test t === t1 × t2
    @test length(t) === 4
    @test size(t) === (2, 2)

    @test t[1,1] === (a=1, b=3.0)
    @test t[2,1] === (a=2, b=3.0)
    @test t[1,2] === (a=1, b=4.0)
    @test t[2,2] === (a=2, b=4.0)

    @testset "Filtering of ProductTables (joins)" begin
        t1 = Table(id = [1,2,3], height = [1.59, 1.78, 1.90])
        t2 = Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"])
        t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

        @test issetequal(filter(row -> row.id == row.id2, t1 × t2), t_ans)
        @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)

        @testset "Unique join" begin
            t1 = Table(id = [1,2,3], height = [1.59, 1.78, 1.90])
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), UniqueIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Sort join" begin
            t1 = Table(id = [1,2,3], height = [1.59, 1.78, 1.90])
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), SortIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Unique sort join" begin
            t1 = Table(id = [1,2,3], height = [1.59, 1.78, 1.90])
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), UniqueSortIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Hash join" begin
            t1 = Table(id = [1,2,3], height = [1.59, 1.78, 1.90])
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), HashIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Unique hash join" begin
            t1 = Table(id = [1,2,3], height = [1.59, 1.78, 1.90])
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), UniqueHashIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Sort-merge join (non-unique/non-unique)" begin
            t1 = accelerate(Table(id = [1,2,3], height = [1.59, 1.78, 1.90]), SortIndex{(:id,)})
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), SortIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Sort-merge join (unique/non-unique)" begin
            t1 = accelerate(Table(id = [1,2,3], height = [1.59, 1.78, 1.90]), UniqueSortIndex{(:id,)})
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), SortIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Sort-merge join (non-unique/unique)" begin
            t1 = accelerate(Table(id = [1,2,3], height = [1.59, 1.78, 1.90]), SortIndex{(:id,)})
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), UniqueSortIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end

        @testset "Sort-merge join (unique/unique)" begin
            t1 = accelerate(Table(id = [1,2,3], height = [1.59, 1.78, 1.90]), UniqueSortIndex{(:id,)})
            t2 = accelerate(Table(id2 = [2,3,1], names = ["Alice", "Bob", "Charlie"]), UniqueSortIndex{(:id2,)})
            t_ans = Table(id = [1,2,3], height = [1.59, 1.78, 1.90], id2 = [1,2,3], names = ["Charlie", "Alice", "Bob"])

            @test issetequal(filter(Equals(:id, :id2), t1 × t2), t_ans)
        end
    end
end