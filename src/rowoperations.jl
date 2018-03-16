# Code to implement common AbstractVector operations, such as concatenation and resizing

function Base.empty(t::Table)
    return Table(map(empty, columns(t)))
end

function Base.empty!(t::Table)
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(empty!, columns(t))
    return t
end

function Base.resize!(t::Table, n::Integer)
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(col -> resize!(col, n), columns(t))
    return t
end

function Base.vcat(t1::Table{names}, t2::Table{names}) where {names}
    c1 = columns(t1)
    c2 = columns(t2)
    c3 = map(vcat, c1, c2)
    return Table(c3)
end

function Base.push!(t::Table{names}, row::NamedTuple{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(push!, columns(t), row)
    return t
end

function Base.pop!(t::Table)
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return map(pop!, columns(t), row)
end

function Base.pushfirst!(t::Table{names}, row::NamedTuple{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(pushfirst!, columns(t), row)
    return t
end

function Base.popfirst!(t::Table{names})
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return map(popfirst!, columns(t), row)
end

function Base.append!(t1::Table{names}, t2::Table{names}) where {names}
    if getindexes(t1) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(append!, columns(t1), columns(t2))
    return t1
end

function Base.prepend!(t1::Table{names}, t2::Table{names}) where {names}
    if getindexes(t1) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(prepend!, columns(t1), columns(t2))
    return t1
end

function Base.deleteat!(t::Table, i)
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map(col -> deleteat!(col, i), columns(t))
    return t
end

function Base.insert!(t::Table{names}, i, row::NamedTuple{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    map((col, value) -> insert!(col, i, value), columns(t), row)
    return t
end

function Base.splice!(t::Table, index::Integer)
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return map(col -> splice!(col, index), columns(t))
end

function Base.splice!(t::Table{names}, index::Integer, row::NamedTuple{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return map((col, value) -> splice!(col, index, value), columns(t), row)
end

function Base.splice!(t::Table{names}, index::Integer, t2::Table{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return map((col, values) -> splice!(col, index, values), columns(t), columns(t2))
end

function Base.splice!(t::Table, inds::UnitRange)
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return Table(map(col -> splice!(col, inds), columns(t)))
end

function Base.splice!(t::Table{names}, inds::UnitRange, row::NamedTuple{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return Table(map((col, value) -> splice!(col, inds, value), columns(t), row))
end

function Base.splice!(t::Table{names}, inds::UnitRange, t2::Table{names}) where {names}
    if getindexes(t) !== ()
        error("Mutating tables with acceleration indexes currently unsupported")
    end
    return Table(map((col, values) -> splice!(col, inds, values), columns(t), columns(t2)))
end
