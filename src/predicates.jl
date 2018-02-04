# Predicates on rows which can hopefully take advantage of acceleration indexes

abstract type Predicate{names} <: Function; end # Intention to add `!`, `&`, `|` on `Predicate`s.
# TODO: logical not, and, or, etc for predicates

# Predicates are useful for filtering, etc:

function map(pred::Predicate{names}, t::Table) where {names}
    # First get the indices using the acceleration indices
    t_projected = Project(names)(t)
    index = promote_index(getindexes(t_projected)...)
    return _map(pred, t_projected, promote_index(getindexes(t_projected)...))
end

function _map(pred::Predicate{names}, t::Table{names}, ::AbstractIndex) where {names}
    return map(row -> pred(row), t) # Use Julia's default algorithm
end

function findall(pred::Predicate{names}, t::Table) where {names}
    # First get the indices using the acceleration indices
    t_projected = Project(names)(t)
    index = promote_index(getindexes(t_projected)...)
    return _findall(pred, t_projected, promote_index(getindexes(t_projected)...))
end

function _findall(pred::Predicate{names}, t::Table{names}, ::AbstractIndex) where {names}
    findall(row -> pred(row), t) # Use Julia's default algorithm
end

function filter(pred::Predicate{names}, t::Table) where {names}
    # First get the indices using the acceleration indices
    t_projected = Project(names)(t)
    index = promote_index(getindexes(t_projected)...)
    inds = _filter_indices(pred, t_projected, index) # Uses `map` or `findall` depending on available acceleration indices
    @inbounds return t[inds]
end

function _filter_indices(pred::Predicate{names}, t::Table{names}, index::AbstractIndex) where {names}
    return _map(pred, t, index) # Like Julia, default to map
end

# TODO similarly for findfirst, findlast, findnext, findprev, findmin, findmax

"""
    IsEqual(namedtuple)
    IsEqual(name = value, ...)

Creates an `IsEqual` function, which returns true on any named tuple whose fields of the
given name(s) are `isequal` to those specified.

See also `Equals` for comparing two columns of the same table.
"""
struct IsEqual{names, D <: Tuple} <: Predicate{names}
    data::D
end
IsEqual(;kwargs...) = IsEqual(kwargs.data)
IsEqual(nt::NamedTuple{names}) where {names} = IsEqual{names}(_values(nt))
IsEqual{names}(t::T) where {names, T <: Tuple} = IsEqual{names, T}(t)

function (pred::IsEqual{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isequal(pred.data, _values(x))
    else
        return pred(Project(names)(x))
    end
end

# map for IsEqual

function _map(pred::IsEqual{names}, t::Table{names}, ::UniqueIndex) where {names}
    out = fill(false, length(t))
    i = findfirst(pred, t)
    if i === nothing
        return out
    else
        @inbounds out[i] = true
        return out
    end
end

function _map(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    range = searchsorted(t, searchrow)
    @inbounds out[range] = true
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    range = searchsorted(t_projected, searchrow)
    @inbounds @simd for i ∈ range
         out[range] = pred(t[i])
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    n = length(t)
    out = fill(false, n)

    searchrow = NamedTuple{names}(pred.data)
    first_greater_or_equal = searchsortedfirst(t, searchrow)
    if first_greater_or_equal <= n
        @inbounds out[first_greater_or_equal] = pred(t[first_greater_or_equal])
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    n = length(t)
    out = fill(false, n)

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    first_greater_or_equal = searchsortedfirst(t_projected, searchrow)
    if first_greater_or_equal <= n
        @inbounds out[first_greater_or_equal] = pred(t[first_greater_or_equal])
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    out = fill(false, length(t))

    key = NamedTuple{names}(pred.data)
    if haskey(index.dict, key) # TODO make faster
        inds = index.dict[key]
        @inbounds out[inds] = true
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    key = Project(names2)(NamedTuple{names}(pred.data))
    if haskey(index.dict, key)
        inds = index.dict[key] # TODO make faster
        @inbounds for i in inds
            if pred(t[i])
                out[i] = true
            end
        end
    end

    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names}) where {names}
    out = fill(false, length(t))

    key = NamedTuple{names}(pred.data)
    if haskey(index.dict, key) # TODO make faster
        i = index.dict[key]
        @inbounds out[i] = true
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names2}) where {names, names2}
    out = fill(false, length(t))
    key = Project(names2)(NamedTuple{names}(pred.data))

    if haskey(index.dict, key) # TODO make faster
        i = index.dict[key]
        @inbounds out[i] = pred(t[i])
    end
    
    return out
end

# findall for IsEqual

function _findall(pred::IsEqual{names}, t::Table{names}, ::UniqueIndex) where {names}
    i = findfirst(pred, t)
    if i === nothing
        return Int[]
    else
        return Int[i]
    end
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    return searchsorted(t, searchrow)
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    searchrow = Project(names2)(NamedTuple{names}(pred.data))
    t_projected = Project(names2)(t)
    range = searchsorted(t_projected, searchrow)
    out = Int[]
    @inbounds for i ∈ range
        if pred(t[i])
            push!(out, i)
        end
    end

    return out
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    n = length(t)
    searchrow = NamedTuple{names}(pred.data)
    first_greater_or_equal = searchsortedfirst(t, searchrow)
    if first_greater_or_equal <= n && pred(t[first_greater_or_equal])
        return Int[first_greater_or_equal]
    else
        return Int[]
    end
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    n = length(t)
    searchrow = Project(names2)(NamedTuple{names}(pred.data))
    t_projected = Project(names2)(t)
    first_greater_or_equal = searchsortedfirst(t_projected, searchrow)
    if first_greater_or_equal <= n && pred(t[first_greater_or_equal])
        return Int[first_greater_or_equal]
    else
        return Int[]
    end
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    return get(() -> Int[], index.dict, searchrow)
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names2}) where {names, names2}
    searchrow = Project(names2)(NamedTuple{names}(pred.data))
    inds = get(() -> Int[], index.dict, searchrow)
    if length(inds) == 0
        return inds
    end
    return filter(i -> @inbounds(pred(t[i])), inds)
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    i = get(() -> 0, index.dict, searchrow)
    if i > 0
        return Int[i]
    else
        return Int[]
    end
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names2}) where {names, names2}
    searchrow = Project(names2)(NamedTuple{names}(pred.data))
    i = get(() -> 0, index.dict, searchrow)
    if i > 0 && @inbounds(pred(t[i]))
        return Int[i]
    else
        return Int[]
    end
end

function _filter_indices(pred::IsEqual{names}, t::Table{names}, index::AbstractUniqueIndex) where {names}
    return _findall(pred, t, index)
end

function _filter_indices(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    return _findall(pred, t, index)
end

function _filter_indices(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    return _findall(pred, t, index)
end

# TODO: Other "statisfies some comparison to a constant" like `IsLess`, `IsGreater`, `In`

"""
    Equals(name1, name2)

Creates an `Equals` function, which returns true on any named tuple whose fields of the
two given names are `isequal` to each other.

See also `IsEqual` for comparing one or more columns of a table to a fixed value.
"""
struct Equals{names} <: Predicate{names}
end
@inline Equals(n1::Symbol, n2::Symbol) = Equals{(n1, n2)}()
@inline Equals(names::Tuple{Symbol,Symbol}) = Equals{names}()

function (pred::Equals{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isequal(getproperty(x, names[1]), getproperty(x, names[2]))
    else
        return pred(Project(names)(x))
    end
end

function _map(pred::Equals{names}, t::Table{names}, index::SortIndex{names}) where {names}
    # TODO sort-merge join algorithm could benefit from `searchsortednext`

    # TODO finish this!
    return _map(pred, t, SortIndex{(names[2],)}())

    # out = fill(false, length(t))
    # if length(t) == 0
    #     return out
    # end

    # cols = columns(t)
    # v1 = getproperty(cols, names[1])
    # v2 = getproperty(cols, names[2])

    # # The sort-merge join algorithm
    # i1 = 1
    # i2 = 0
    # n = length(t)
    # @inbounds x = v1[1]
    # while i1 < n && i2 < n
    #     if i2 == i1
    #         @inbounds out[i1] = true
    #         i1 += 1
    #     elseif i2 < i1
    #         i2 = searchsortedfirst(v2, x)
    #         @inbounds x = v2[i2]
    #     else

    #     end
        
    #     @inbounds x = v2[1]
    
    # end
    
    # return out
end

function _map(pred::Equals{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    if length(names2) !== 0 && length(names2) !== 1
        if names2[1] === names[2] && names2[2] === names[1]
            p = Project((names[2], names[1]))
            _map(Equals(names[2], names[1]), p(t), index)
        end
    end

    return _map(pred, t, NoIndex())
end


# TODO: Other comparison-based relations like `LessThan{:a, :b}` (values in column `a` are less than column `b`)
