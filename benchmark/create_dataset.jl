# Adapted from https://github.com/xofbd/pandas_vs_PostgreSQL/blob/master/create_dataset.py
# (which was released under MIT license: Copyright (c) 2018 Don Bruce Fox)
# See also: https://blog.thedataincubator.com/2018/01/pandas-vs-postgresql/

using MinimumViableTables

using Random

function create_dataset(n = 1000)
    Random.srand(1)

    id = randperm(n)
    section = rand(['A', 'B', 'C', 'D'], n)
    score_1 = rand(n)
    score_2 = rand(n)
    score_3 = rand(n)

    t_a = Table(id = id, section = section, score_1 = score_1, score_2 = score_2)
    t_b = Table(id2 = id, score_3 = score_3)

    return (t_a, t_b)
end
