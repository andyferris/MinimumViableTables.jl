# Predicates on rows which can hopefully take advantage of acceleration indexes

abstract type Predicate{names} <: Function; end # Intention to add `!`, `&`, `|` on `Predicate`s.
# TODO: logical not, and, or, etc for predicates?

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
IsEqual(nt::NamedTuple{names}) where {names} = IsEqual{names}(Tuple(nt))
IsEqual{names}(t::T) where {names, T <: Tuple} = IsEqual{names, T}(t)

function (pred::IsEqual{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isequal(pred.data, Tuple(x))
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
    @inbounds range = searchsorted(view(t, index.order), searchrow)
    @inbounds out[index.order[range]] = true
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds out[index.order[range]] = true
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    n = length(t)
    out = fill(false, n)

    searchrow = NamedTuple{names}(pred.data)
    @inbounds first_greater_or_equal = searchsortedfirst(view(t, index.order), searchrow)
    if first_greater_or_equal <= n
        @inbounds out[index.order[first_greater_or_equal]] = pred(t[index.order[first_greater_or_equal]])
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    n = length(t)
    out = fill(false, n)

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds first_greater_or_equal = searchsortedfirst(view(t_projected, index.order), searchrow)
    if first_greater_or_equal <= n
        @inbounds out[index.order[first_greater_or_equal]] = pred(t[index.order[first_greater_or_equal]])
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    out = fill(false, length(t))

    key = pred.data
    if haskey(index.dict, key) # TODO make faster
        inds = index.dict[key]
        @inbounds out[inds] = true
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    key = Tuple(Project(names2)(NamedTuple{names}(pred.data)))
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

    key = pred.data
    if haskey(index.dict, key) # TODO make faster
        i = index.dict[key]
        @inbounds out[i] = true
    end
    
    return out
end

function _map(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names2}) where {names, names2}
    out = fill(false, length(t))
    key = Tuple(Project(names2)(NamedTuple{names}(pred.data)))

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
    return @inbounds index.order[searchsorted(view(t, index.order), searchrow)]
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    searchrow = Project(names2)(NamedTuple{names}(pred.data))
    t_projected = Project(names2)(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    out = Int[]
    @inbounds for i ∈ range
        j = index.order[i]
        if pred(t[j])
            push!(out, j)
        end
    end

    return out
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    n = length(t)
    searchrow = NamedTuple{names}(pred.data)
    @inbounds first_greater_or_equal = searchsortedfirst(view(t, index.order), searchrow)
    @inbounds if first_greater_or_equal <= n
        i = index.order[first_greater_or_equal]
        if pred(t[i])
            return Int[i]
        end
    end
    return Int[]
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    n = length(t)
    searchrow = Project(names2)(NamedTuple{names}(pred.data))
    t_projected = Project(names2)(t)
    @inbounds first_greater_or_equal = searchsortedfirst(view(t_projected, index.order), searchrow)
    @inbounds if first_greater_or_equal <= n 
        i = index.order[first_greater_or_equal]
        if pred(t[i])
            return Int[i]
        end
    end
    return Int[]
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    searchrow = pred.data
    return get(() -> Int[], index.dict, searchrow)
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::HashIndex{names2}) where {names, names2}
    searchrow = Tuple(Project(names2)(NamedTuple{names}(pred.data)))
    inds = get(() -> Int[], index.dict, searchrow)
    if length(inds) == 0
        return inds
    end
    return filter(i -> @inbounds(pred(t[i])), inds)
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names}) where {names}
    searchrow = pred.data
    i = get(() -> 0, index.dict, searchrow)
    if i > 0
        return Int[i]
    else
        return Int[]
    end
end

function _findall(pred::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names2}) where {names, names2}
    searchrow = Tuple(Project(names2)(NamedTuple{names}(pred.data)))
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

"""
    IsLess(namedtuple)
    IsLess(name = value, ...)

Creates an `IsLess` function, which returns true on any named tuple whose fields of the
given name(s) are `isless` to those specified.
"""
struct IsLess{names, D <: Tuple} <: Predicate{names}
    data::D
end
IsLess(;kwargs...) = IsLess(kwargs.data)
IsLess(nt::NamedTuple{names}) where {names} = IsLess{names}(Tuple(nt))
IsLess{names}(t::T) where {names, T <: Tuple} = IsLess{names, T}(t)

function (pred::IsLess{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isless(Tuple(x), pred.data)
    else
        return pred(Project(names)(x))
    end
end

# map for IsLess

function _map(pred::IsLess{names}, t::Table{names}, index::SortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlastless(view(t, index.order), searchrow)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsLess{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order))
    end

    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds out[index.order[1:range.start-1]] = true
    @inbounds for i ∈ range
        j = index.order[i]
        out[j] = pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
    end
  
    return out
end

function _map(pred::IsLess{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlastless(view(t, index.order), searchrow)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsLess{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedfirst(view(t_projected, index.order), searchrow)
    @inbounds if i > n || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i - 1
    end
    @inbounds out[index.order[1:i]] = true

    return out
end

# findall for IsLess

function _findall(pred::IsLess{names}, t::Table{names}, index::SortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlastless(view(t, index.order), searchrow)
    
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsLess{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order))
    end

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds out = index.order[1:range.start-1]
    @inbounds for i ∈ range
        j = index.order[i]
        if pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
            push!(out, j)
        end
    end

    sort!(out)
    return out
end

function _findall(pred::IsLess{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlastless(view(t, index.order), searchrow)
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsLess{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedfirst(view(t_projected, index.order), searchrow)
    @inbounds if i > n || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i - 1
    end
    @inbounds return sort(view(index.order, 1:i))
end

# filter for IsLess - use default `map` method

"""
    IsLessEqual(namedtuple)
    IsLessEqual(name = value, ...)

Creates an `IsLessEqual` function, which returns true on any named tuple whose fields of the
given name(s) are `isless` or `isequal` to those specified.
"""
struct IsLessEqual{names, D <: Tuple} <: Predicate{names}
    data::D
end
IsLessEqual(;kwargs...) = IsLessEqual(kwargs.data)
IsLessEqual(nt::NamedTuple{names}) where {names} = IsLessEqual{names}(Tuple(nt))
IsLessEqual{names}(t::T) where {names, T <: Tuple} = IsLessEqual{names, T}(t)

function (pred::IsLessEqual{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return !isless(pred.data, Tuple(x))
    else
        return pred(Project(names)(x))
    end
end

# map for IsLessEqual

function _map(pred::IsLessEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlast(view(t, index.order), searchrow)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsLessEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order))
    end

    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds out[index.order[1:range.start-1]] = true
    @inbounds for i ∈ range
        j = index.order[i]
        out[j] = pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
    end
  
    return out
end

function _map(pred::IsLessEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlast(view(t, index.order), searchrow)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsLessEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedfirst(view(t_projected, index.order), searchrow)
    @inbounds if i > n || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i - 1
    end
    @inbounds out[index.order[1:i]] = true

    return out
end

# findall for IsLessEqual

function _findall(pred::IsLessEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlast(view(t, index.order), searchrow)
    
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsLessEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order))
    end

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds out = index.order[1:range.start-1]
    @inbounds for i ∈ range
        j = index.order[i]
        if pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
            push!(out, j)
        end
    end

    sort!(out)
    return out
end

function _findall(pred::IsLessEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = 1:searchsortedlast(view(t, index.order), searchrow)
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsLessEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedfirst(view(t_projected, index.order), searchrow)
    @inbounds if i > n || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i - 1
    end
    @inbounds return sort(view(index.order, 1:i))
end

"""
    IsGreater(namedtuple)
    IsGreater(name = value, ...)

Creates an `IsGreater` function, which returns true on any named tuple whose fields of the
given name(s) are not `isless` or `isequal` to those specified.
"""
struct IsGreater{names, D <: Tuple} <: Predicate{names}
    data::D
end
IsGreater(;kwargs...) = IsGreater(kwargs.data)
IsGreater(nt::NamedTuple{names}) where {names} = IsGreater{names}(Tuple(nt))
IsGreater{names}(t::T) where {names, T <: Tuple} = IsGreater{names, T}(t)

function (pred::IsGreater{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isless(pred.data, Tuple(x))
    else
        return pred(Project(names)(x))
    end
end

# map for IsGreater

function _map(pred::IsGreater{names}, t::Table{names}, index::SortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirstgreater(view(t, index.order), searchrow):length(t)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsGreater{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order))
    end

    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds for i ∈ range
        j = index.order[i]
        out[j] = pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
    end
    @inbounds out[index.order[range.stop+1:length(t)]] = true
  
    return out
end

function _map(pred::IsGreater{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirstgreater(view(t, index.order), searchrow):length(t)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsGreater{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedlast(view(t_projected, index.order), searchrow)
    @inbounds if i == 0 || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i + 1
    end
    @inbounds out[index.order[i:n]] = true

    return out
end

# findall for IsGreater

function _findall(pred::IsGreater{names}, t::Table{names}, index::SortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirstgreater(view(t, index.order), searchrow):length(t)
    
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsGreater{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order))
    end

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    out = Int[]
    @inbounds for i ∈ range
        j = index.order[i]
        if pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
            push!(out, j)
        end
    end
    @inbounds append!(out, index.order[range.stop+1:length(t)])

    sort!(out)
    return out
end

function _findall(pred::IsGreater{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirstgreater(view(t, index.order), searchrow):length(t)
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsGreater{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedlast(view(t_projected, index.order), searchrow)
    @inbounds if i == 0 || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i + 1
    end
    @inbounds return sort(view(index.order, i:n))
end

"""
    IsGreaterEqual(namedtuple)
    IsGreaterEqual(name = value, ...)

Creates an `IsGreaterEqual` function, which returns true on any named tuple whose fields of the
given name(s) are not `isless` to those specified.
"""
struct IsGreaterEqual{names, D <: Tuple} <: Predicate{names}
    data::D
end
IsGreaterEqual(;kwargs...) = IsGreaterEqual(kwargs.data)
IsGreaterEqual(nt::NamedTuple{names}) where {names} = IsGreaterEqual{names}(Tuple(nt))
IsGreaterEqual{names}(t::T) where {names, T <: Tuple} = IsGreaterEqual{names, T}(t)

function (pred::IsGreaterEqual{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return !isless(Tuple(x), pred.data)
    else
        return pred(Project(names)(x))
    end
end

# map for IsGreaterEqual

function _map(pred::IsGreaterEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirst(view(t, index.order), searchrow):length(t)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsGreaterEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order))
    end

    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    @inbounds for i ∈ range
        j = index.order[i]
        out[j] = pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
    end
    @inbounds out[index.order[range.stop+1:length(t)]] = true
  
    return out
end

function _map(pred::IsGreaterEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirst(view(t, index.order), searchrow):length(t)
    @inbounds out[view(index.order, range)] = true
    
    return out
end

function _map(pred::IsGreaterEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _map(pred, t, NoIndex())
    elseif names3 !== names2
        return _map(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedlast(view(t_projected, index.order), searchrow)
    @inbounds if i == 0 || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i + 1
    end
    @inbounds out[index.order[i:n]] = true

    return out
end

# findall for IsGreaterEqual

function _findall(pred::IsGreaterEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirst(view(t, index.order), searchrow):length(t)
    
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsGreaterEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order))
    end

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds range = searchsorted(view(t_projected, index.order), searchrow)
    out = Int[]
    @inbounds for i ∈ range
        j = index.order[i]
        if pred(t[j]) # TODO: Make faster by comparing only columns setdiff(names, names2)
            push!(out, j)
        end
    end
    @inbounds append!(out, index.order[range.stop+1:length(t)])

    sort!(out)
    return out
end

function _findall(pred::IsGreaterEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    searchrow = NamedTuple{names}(pred.data)
    @inbounds range = searchsortedfirst(view(t, index.order), searchrow):length(t)
    @inbounds return sort(view(index.order, range))
end

function _findall(pred::IsGreaterEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    # Be careful about what index you accept - TODO perhaps `promote_index` needs to know the predicate rather than do this here
    names3 = _headsubset(names, names2)
    if names3 === ()
        return _findall(pred, t, NoIndex())
    elseif names3 !== names2
        return _findall(pred, t, SortIndex{names3}(index.order)) # potentially looses uniqueness
    end

    n = length(t)

    searchrow = Project{names2}()(NamedTuple{names}(pred.data))
    t_projected = Project{names2}()(t)
    @inbounds i = searchsortedlast(view(t_projected, index.order), searchrow)
    @inbounds if i == 0 || !pred(t[index.order[i]]) # TODO: Make faster by comparing only columns setdiff(names, names2)
        i = i + 1
    end
    @inbounds return sort(view(index.order, i:n))
end

"""
    In(namedtuple)
    In(name = collection, ...)

Creates an `In` function, which returns true on any named tuple whose field(s) of the
given name(s) is `in` the collection(s) specified.
"""
struct In{names, T <: Tuple} <: Predicate{names}
    data::T
end
In(;kwargs...) = In(kwargs.data)
In(nt::NamedTuple{names}) where {names} = In{names}(Tuple(nt))
In{names}(t::T) where {names, T <: Tuple} = In{names, T}(t)

function (pred::In{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return _all(in, Tuple(x), pred.data)
    else
        return pred(Project(names)(x))
    end
end

# map for `In` of `Interval`

function _map(pred::In{names, Tuple{<:Interval}}, t::Table{names}, index::SortIndex{names}) where {names}
    # TODO Currently expects a single column here - generalize
    # TODO The generalized solution could use a generalized search tree like k-d tree
    out = fill(false, length(t))

    startrow = NamedTuple{names}(pred.data[1].start)
    @inbounds start = searchsortedfirst(view(t, index.order), startrow)

    stoprow = NamedTuple{names}(pred.data[1].start)
    @inbounds stop = searchsortedlast(view(t, index.order), stoprow)

    @inbounds out[view(index.order, start:stop)] = true
    
    return out
end

function _map(pred::In{names, Tuple{<:Interval}}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    # TODO Currently expects a single column here - generalize
    # TODO The generalized solution could use a generalized search tree like k-d tree
    out = fill(false, length(t))

    startrow = NamedTuple{names}(pred.data[1].start)
    @inbounds start = searchsortedfirst(view(t, index.order), startrow)

    stoprow = NamedTuple{names}(pred.data[1].start)
    @inbounds stop = searchsortedlast(view(t, index.order), stoprow)

    @inbounds out[view(index.order, start:stop)] = true
    
    return out
end

# findall for `In` of `Interval`

function _findall(pred::In{names, Tuple{<:Interval}}, t::Table{names}, index::SortIndex{names}) where {names}
    # TODO Currently expects a single column here - generalize
    # TODO The generalized solution could use a generalized search tree like k-d tree
    startrow = NamedTuple{names}(pred.data[1].start)
    @inbounds start = searchsortedfirst(view(t, index.order), startrow)

    stoprow = NamedTuple{names}(pred.data[1].start)
    @inbounds stop = searchsortedlast(view(t, index.order), stoprow)

    @inbounds return index.order[start:stop]
end

function _findall(pred::In{names, Tuple{<:Interval}}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    # TODO Currently expects a single column here - generalize
    # TODO The generalized solution could use a generalized search tree like k-d tree
    startrow = NamedTuple{names}(pred.data[1].start)
    @inbounds start = searchsortedfirst(view(t, index.order), startrow)

    stoprow = NamedTuple{names}(pred.data[1].start)
    @inbounds stop = searchsortedlast(view(t, index.order), stoprow)

    @inbounds return index.order[start:stop]
end

# filter for `In` of `Interval`

function _filter_indices(pred::IsEqual{names, Tuple{<:Interval}}, t::Table{names}, index::SortIndex{names}) where {names}
    return _findall(pred, t, index)
end

function _filter_indices(pred::IsEqual{names, Tuple{<:Interval}}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    return _findall(pred, t, index)
end

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

# function _map(pred::Equals{names}, t::Table{names}, index::SortIndex{names}) where {names}
#     # TODO sort-merge join algorithm could benefit from `searchsortednext`

#     # TODO finish this!
#     return _map(pred, t, SortIndex{(names[2],)}())

#     # out = fill(false, length(t))
#     # if length(t) == 0
#     #     return out
#     # end

#     # cols = columns(t)
#     # v1 = getproperty(cols, names[1])
#     # v2 = getproperty(cols, names[2])

#     # # The sort-merge join algorithm
#     # i1 = 1
#     # i2 = 0
#     # n = length(t)
#     # @inbounds x = v1[1]
#     # while i1 < n && i2 < n
#     #     if i2 == i1
#     #         @inbounds out[i1] = true
#     #         i1 += 1
#     #     elseif i2 < i1
#     #         i2 = searchsortedfirst(v2, x)
#     #         @inbounds x = v2[i2]
#     #     else

#     #     end
        
#     #     @inbounds x = v2[1]
    
#     # end
    
#     # return out
# end

# function _map(pred::Equals{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
#     if length(names2) !== 0 && length(names2) !== 1
#         if names2[1] === names[2] && names2[2] === names[1]
#             p = Project((names[2], names[1]))
#             _map(Equals(names[2], names[1]), p(t), index)
#         end
#     end

#     return _map(pred, t, NoIndex())
# end

"""
    LessThan(name1, name2)

Creates an `LessThan` function, which returns true on any named tuple whose field `name1`
is `isless` to the field `name2`.

See also `IsLess` for comparing one or more columns of a table to a fixed value.
"""
struct LessThan{names} <: Predicate{names}
end
@inline LessThan(n1::Symbol, n2::Symbol) = LessThan{(n1, n2)}()
@inline LessThan(names::Tuple{Symbol,Symbol}) = LessThan{names}()

function (pred::LessThan{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isless(getproperty(x, names[1]), getproperty(x, names[2]))
    else
        return pred(Project(names)(x))
    end
end

"""
    LessEqualThan(name1, name2)

Creates an `LessEqualThan` function, which returns true on any named tuple whose field `name1`
is `isless` or `isequal` to the field `name2`.

See also `IsLessEqual` for comparing one or more columns of a table to a fixed value.
"""
struct LessEqualThan{names} <: Predicate{names}
end
@inline LessEqualThan(n1::Symbol, n2::Symbol) = LessEqualThan{(n1, n2)}()
@inline LessEqualThan(names::Tuple{Symbol,Symbol}) = LessEqualThan{names}()

function (pred::LessEqualThan{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return !isless(getproperty(x, names[2]), getproperty(x, names[1]))
    else
        return pred(Project(names)(x))
    end
end

"""
    GreaterThan(name1, name2)

Creates an `GreaterThan` function, which returns true on any named tuple whose field `name2`
is `isless` to the field `name1`.

See also `IsGreater` for comparing one or more columns of a table to a fixed value.
"""
struct GreaterThan{names} <: Predicate{names}
end
@inline GreaterThan(n1::Symbol, n2::Symbol) = GreaterThan{(n1, n2)}()
@inline GreaterThan(names::Tuple{Symbol,Symbol}) = GreaterThan{names}()

function (pred::GreaterThan{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isless(getproperty(x, names[2]), getproperty(x, names[1]))
    else
        return pred(Project(names)(x))
    end
end

"""
    GreaterEqualThan(name1, name2)

Creates an `GreaterEqualThan` function, which returns true on any named tuple whose field `name2`
is `isless` or `isequal` to the field `name1`.

See also `IsGreaterEqual` for comparing one or more columns of a table to a fixed value.
"""
struct GreaterEqualThan{names} <: Predicate{names}
end
@inline GreaterEqualThan(n1::Symbol, n2::Symbol) = GreaterEqualThan{(n1, n2)}()
@inline GreaterEqualThan(names::Tuple{Symbol,Symbol}) = GreaterEqualThan{names}()

function (pred::GreaterEqualThan{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return !isless(getproperty(x, names[1]), getproperty(x, names[2]))
    else
        return pred(Project(names)(x))
    end
end

"""
    Within(name1, name2, distance)

Creates an `Within` function, which returns true on any named tuple whose field `name1`
is within `±distance` of `name2` (inclusive).

See also `In` for determining if one or more columns of a table is within a given `Interval`.
"""
struct Within{names, T} <: Predicate{names}
    distance::T
end
@inline Within(n1::Symbol, n2::Symbol, distance::T) where {T} = Within{(n1, n2), T}(distance)
@inline Within(names::Tuple{Symbol,Symbol}, distance::T) where {T} = Within{names, T}(distance)

function (pred::Within{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        x0 = getproperty(x, names[1])
        interval = (x0 - pred.distance) .. (x0 + pred.distance)
        return getproperty(x, names[2]) ∈ interval
    else
        return pred(Project(names)(x))
    end
end

# TODO: Perhaps instead of Equals, etc, we can have some kind of theta-join-generator.
#       Given the values in column :a, make sure IsEqual(b = value in :a)
#       This could then simply be lambda, we can construct a custom `In` for example.
#       Need to have a nice system to organize dispatch in order to support sort-merge joins... 

# TODO: Some way of dealing with multiple indexes on one table. E.g. two sort indexes and sort-merge filter.

# TODO: Implement Cartesian outer product between tables, then faster filters with above
#       indexes, to make efficient Join operations
