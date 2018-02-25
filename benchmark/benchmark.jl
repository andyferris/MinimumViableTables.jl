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

#join_times_unique_sorted = zeros(n_ns)
join_times_unique_hashed = zeros(n_ns)
#join_times_sorted = zeros(n_ns)
#join_times_hashed = zeros(n_ns)
#join_times_merge = zeros(n_ns)

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

    bm = @benchmark filter(IsEqual(section = 'A'), $t_a)
    time_ns = median(bm.times)
    filter_times[i] = time_ns * 1e-9
    println("Filter column: t = $(printtime(time_ns))")

    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a_sorted)
    time_ns = median(bm.times)
    filter_times_sorted[i] = time_ns * 1e-9
    println("Filter column (sort index): t = $(printtime(time_ns))")

    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a_primary_sorted)
    time_ns = median(bm.times)
    filter_times_primary_sorted[i] = time_ns * 1e-9
    println("Filter column (primary sort index): t = $(printtime(time_ns))")

    bm = @benchmark filter($(IsEqual(section = 'A')), $t_a_hashed)
    time_ns = median(bm.times)
    filter_times_hashed[i] = time_ns * 1e-9
    println("Filter column (hash index): t = $(printtime(time_ns))")

    bm = @benchmark groupreduce($(Project{(:section,)}()), $identity, $((cum, row) -> (cum[1] + row.score_1, max(cum[2], row.score_2))), $((0.0, 0.0)), $(Project{(:section, :score_1, :score_2)}()(t_a)))
    time_ns = median(bm.times)
    groupreduce_times[i] = time_ns * 1e-9
    println("Group reduction: t = $(printtime(time_ns))")

    t_b_unique_hashed = addindex(t_b, UniqueHashIndex{(:id2,)})
    t_product = ProductTable(t_a, t_b_unique_hashed)
    bm = @benchmark filter($(Equals{(:id, :id2)}()), $t_product)
    time_ns = median(bm.times)
    join_times_unique_hashed[i] = time_ns * 1e-9
    println("Join (unique hash): t = $(printtime(time_ns))")

    println()
end

#using UnicodePlots

#plot = UnicodePlots.scatterplot(log10.(ns), log10.(filter_times))
#UnicodePlots.scatterplot!(plot, log10.(ns), log10.(filter_times_sorted))
#UnicodePlots.scatterplot!(plot, log10.(ns), log10.(filter_times_hashed))