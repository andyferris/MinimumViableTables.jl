broadcast(::typeof(identity), t::Table) = copy(t) # output shouldn't alias input
map(::typeof(identity), t::Table) = copy(t)

broadcast(::typeof(merge), t::Table) = copy(t) # output shouldn't alias input
map(::typeof(merge), t::Table) = copy(t)

function broadcast(::typeof(merge), t1::Table, t2::Table)
    map(merge, t1, t2)
end

function map(::typeof(merge), t1::Table, t2::Table)
    # TODO merge can overwrite a column. Need to invalidate the appropriate acceleration
    # indexes in this case
    return Table(merge(columns(t1), columns(t2)), (getindexes(t1)..., getindexes(t2)...))
end

# TODO broadcast/map Project (and stop doing autovectorization?)
# TODO broadcast/map Rename (and stop doing autovectorization?)

# TODO should we intercept all `map`s and `broadcast`s that map rows to rows (NamedTuples)?
# (we would need to rely on inference...)

