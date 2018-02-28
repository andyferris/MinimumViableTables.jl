# Benchmark some basic operations of `Table`

# Choice of benchmarks drawn from: https://blog.thedataincubator.com/2018/01/pandas-vs-postgresql/

using MinimumViableTables
using BenchmarkTools
using SplitApplyCombine

include("create_dataset.jl")

function printtime(t)
    if t < 10^3
        return "$t ns"
    elseif t < 10^6
        t = 1e-3 * t
        return "$t μs" 
    elseif t < 10^9
        t = 1e-6 * t
        return "$t ms" 
    else
        t = 1e-9 * t
        return "$t s" 
    end
end

ns = [10, 100, 1000, 10_000, 100_000, 1_000_000, 10_000_000]
n_ns = length(ns)

select_times = zeros(n_ns)

filter_times = zeros(n_ns)
filter_times_sorted = zeros(n_ns)
filter_times_primary_sorted = zeros(n_ns)
filter_times_hashed = zeros(n_ns)

groupreduce_times = zeros(n_ns)

join_times_unique_sorted = zeros(n_ns)
join_times_unique_hashed = zeros(n_ns)
join_times_sorted = zeros(n_ns)
join_times_hashed = zeros(n_ns)
join_times_merge = zeros(n_ns)
join_times_merge_unique1 = zeros(n_ns)
join_times_merge_unique2 = zeros(n_ns)
join_times_merge_unique12 = zeros(n_ns)

global bm
for (i, n) in enumerate(ns)
    println("n = $n")
    (t_a, t_b) = create_dataset(n)

    bm = @benchmark $(Project{(:score_1,)}())($t_a)
    time_ns = median(bm.times)
    select_times[i] = time_ns * 1e-9
    println("Select column: t = $(printtime(time_ns))")

    perm = sortperm(columns(t_a).section)
    t_a_sorted = Table(columns(t_a), (SortIndex{(:section,)}(perm),))
    tmp = t_a[perm]
    t_a_primary_sorted = Table(columns(tmp), (SortIndex{(:section,)}(Base.OneTo(n)),))
    t_a_hashed = addindex(t_a, HashIndex{(:section,)})

    n = length(filter(IsEqual(section = 'A'), t_a))
    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a)
    time_ns = median(bm.times)
    filter_times[i] = time_ns * 1e-9
    println("Filter column: t = $(printtime(time_ns)) ($n rows)")

    n = length(filter(IsEqual(section = 'A'), t_a_sorted))
    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a_sorted)
    time_ns = median(bm.times)
    filter_times_sorted[i] = time_ns * 1e-9
    println("Filter column (sort index): t = $(printtime(time_ns)) ($n rows)")

    n = length(filter(IsEqual(section = 'A'), t_a_primary_sorted))
    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a_primary_sorted)
    time_ns = median(bm.times)
    filter_times_primary_sorted[i] = time_ns * 1e-9
    println("Filter column (primary sort index): t = $(printtime(time_ns)) ($n rows)")

    n = length(filter(IsEqual(section = 'A'), t_a_hashed))
    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a_hashed)
    time_ns = median(bm.times)
    filter_times_hashed[i] = time_ns * 1e-9
    println("Filter column (hash index): t = $(printtime(time_ns)) ($n rows)")

    n = length(groupreduce(Project{(:section,)}(), identity, (cum, row) -> (cum[1] + row.score_1, max(cum[2], row.score_2)), (0.0, 0.0), Project{(:section, :score_1, :score_2)}()(t_a)))
    bm = @benchmark groupreduce($(Project{(:section,)}()), $identity, $((cum, row) -> (cum[1] + row.score_1, max(cum[2], row.score_2))), $((0.0, 0.0)), $(Project{(:section, :score_1, :score_2)}()(t_a)))
    time_ns = median(bm.times)
    groupreduce_times[i] = time_ns * 1e-9
    println("Group reduction: t = $(printtime(time_ns)) ($n groups)")

    t_b_sorted = addindex(t_b, SortIndex{(:id2,)})
    t_product_sorted = ProductTable(t_a, t_b_sorted)
    n = length(filter(Equals{(:id, :id2)}(), t_product_sorted))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_sorted)
    time_ns = median(bm.times)
    join_times_sorted[i] = time_ns * 1e-9
    println("Join (sort): t = $(printtime(time_ns)) ($n rows)")

    t_b_unique_sorted = addindex(t_b, UniqueSortIndex{(:id2,)})
    t_product_unique_sorted = ProductTable(t_a, t_b_unique_sorted)
    n = length(filter(Equals{(:id, :id2)}(), t_product_unique_sorted))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_unique_sorted)
    time_ns = median(bm.times)
    join_times_unique_sorted[i] = time_ns * 1e-9
    println("Join (unique sort): t = $(printtime(time_ns)) ($n rows)")

    t_b_hashed = addindex(t_b, HashIndex{(:id2,)})
    t_product_hashed = ProductTable(t_a, t_b_hashed)
    n = length(filter(Equals{(:id, :id2)}(), t_product_hashed))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_hashed)
    time_ns = median(bm.times)
    join_times_hashed[i] = time_ns * 1e-9
    println("Join (hash): t = $(printtime(time_ns)) ($n rows)")

    t_b_unique_hashed = addindex(t_b, UniqueHashIndex{(:id2,)})
    t_product_unique_hashed = ProductTable(t_a, t_b_unique_hashed)
    n = length(filter(Equals{(:id, :id2)}(), t_product_unique_hashed))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_unique_hashed)
    time_ns = median(bm.times)
    join_times_unique_hashed[i] = time_ns * 1e-9
    println("Join (unique hash): t = $(printtime(time_ns)) ($n rows)")

    t_a_merge = addindex(t_a, SortIndex{(:id,)})
    t_product_merge = ProductTable(t_a_merge, t_b_sorted)
    n = length(filter(Equals{(:id, :id2)}(), t_product_merge))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_merge)
    time_ns = median(bm.times)
    join_times_merge[i] = time_ns * 1e-9
    println("Join (merge): t = $(printtime(time_ns)) ($n rows)")

    t_a_merge_unique = addindex(t_a, UniqueSortIndex{(:id,)})
    t_product_merge_unique1 = ProductTable(t_a_merge_unique, t_b_sorted)
    n = length(filter(Equals{(:id, :id2)}(), t_product_merge_unique1))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_merge_unique1)
    time_ns = median(bm.times)
    join_times_merge_unique1[i] = time_ns * 1e-9
    println("Join (merge unique/non-unique): t = $(printtime(time_ns)) ($n rows)")

    t_product_merge_unique2 = ProductTable(t_a_merge, t_b_unique_sorted)
    n = length(filter(Equals{(:id, :id2)}(), t_product_merge_unique2))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_merge_unique2)
    time_ns = median(bm.times)
    join_times_merge_unique2[i] = time_ns * 1e-9
    println("Join (merge non-unique/unique): t = $(printtime(time_ns)) ($n rows)")

    t_product_merge_unique12 = ProductTable(t_a_merge_unique, t_b_unique_sorted)
    n = length(filter(Equals{(:id, :id2)}(), t_product_merge_unique12))
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product_merge_unique12)
    time_ns = median(bm.times)
    join_times_merge_unique12[i] = time_ns * 1e-9
    println("Join (merge unique/unique): t = $(printtime(time_ns)) ($n rows)")

    println()
end

#using UnicodePlots

#plot = UnicodePlots.scatterplot(log10.(ns), log10.(filter_times))
#UnicodePlots.scatterplot!(plot, log10.(ns), log10.(filter_times_sorted))
#UnicodePlots.scatterplot!(plot, log10.(ns), log10.(filter_times_hashed))