# Filters are predicates on rows which can hopefully take advantage of acceleration indexes

struct IsEqual{names, D <: Tuple} <: Function
    data::D
end
IsEqual(;kwargs...) = IsEqual(kwargs.data)
IsEqual(nt::NamedTuple{names}) where {names} = IsEqual{names}(_values(nt))
IsEqual{names}(t::T) where {names, T <: Tuple} = IsEqual{names, T}(t)

#function (ie::IsEqual{names})(x::NamedTuple{names}) where {names}
    #return isequal(ie.data, _values(x))
#end
function (ie::IsEqual{names})(x::NamedTuple{names2}) where {names, names2}
    if names === names2
        return isequal(ie.data, _values(x))
    else
        return ie(project(x, names))
    end
end

promote_indexes(t::Tuple{Vararg{AbstractIndex}}) = t[1]
promote_indexes(t::Tuple{}) = NoIndex()
promote_index(indexes...) = promote_indexes(indexes)

# map for IsEqual

function map(ie::IsEqual{names}, t::Table) where {names}
    # First get the indices using the acceleration indices
    t_projected = Project(names)(t)
    index = promote_index(t_projected.indexes...)
    return _map(ie, t_projected, promote_index(t_projected.indexes...))
end

function _map(ie::IsEqual{names}, t::Table{names}, ::NoIndex) where {names}
    map(row -> isequal(_values(row), ie.data), t)::AbstractVector{Bool}
end

function _map(ie::IsEqual{names}, t::Table{names}, ::UniqueIndex) where {names}
    out = fill(false, length(t))
    i = findfirst(ie, t)
    if i === nothing
        return out
    else
        @inbounds out[i] = true
        return out
    end
end

function _map(ie::IsEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    out = fill(false, length(t))

    searchrow = NamedTuple{names}(ie.data)
    range = searchsorted(t, searchrow)
    @inbounds out[range] = true
    
    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    searchrow = Project{names2}()(NamedTuple{names}(ie.data))
    t_projected = Project{names2}()(t)
    range = searchsorted(t_projected, searchrow)
    @inbounds @simd for i ∈ range
         out[range] = ie(t[i])
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    n = length(t)
    out = fill(false, n)

    searchrow = NamedTuple{names}(ie.data)
    first_greater_or_equal = searchsortedfirst(t, searchrow)
    if first_greater_or_equal <= n
        @inbounds out[first_greater_or_equal] = ie(t[first_greater_or_equal])
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    n = length(t)
    out = fill(false, n)

    searchrow = Project{names2}()(NamedTuple{names}(ie.data))
    t_projected = Project{names2}()(t)
    first_greater_or_equal = searchsortedfirst(t_projected, searchrow)
    if first_greater_or_equal <= n
        @inbounds out[first_greater_or_equal] = ie(t[first_greater_or_equal])
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    out = fill(false, length(t))

    key = NamedTuple{names}(ie.data)
    if haskey(index.dict, key) # TODO make faster
        inds = index.dict[key]
        @inbounds out[inds] = true
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::HashIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    key = project(NamedTuple{names}(ie.data), names2)
    if haskey(index.dict, key)
        inds = index.dict[key] # TODO make faster
        @inbounds for i in inds
            if ie(t[i])
                out[i] = true
            end
        end
    end

    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names}) where {names}
    out = fill(false, length(t))

    key = NamedTuple{names}(ie.data)
    if haskey(index.dict, key) # TODO make faster
        i = index.dict[key]
        @inbounds out[i] = true
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names2}) where {names, names2}
    out = fill(false, length(t))
    key = project(NamedTuple{names}(ie.data), names2)

    if haskey(index.dict, key) # TODO make faster
        i = index.dict[key]
        @inbounds out[i] = ie(t[i])
    end
    
    return out
end

# findall for IsEqual

function findall(ie::IsEqual{names}, t::Table) where {names}
    # First get the indices using the acceleration indices
    t_projected = Project(names)(t)
    index = promote_index(t_projected.indexes...)
    return _findall(ie, t_projected, promote_index(t_projected.indexes...))
end

function _findall(ie::IsEqual{names}, t::Table{names}, ::NoIndex) where {names}
    findall(row -> isequal(_values(row), ie.data), t)::AbstractVector{<:Int}
end

function _findall(ie::IsEqual{names}, t::Table{names}, ::UniqueIndex) where {names}
    i = findfirst(ie, t)
    if i === nothing
        return Int[]
    else
        return Int[i]
    end
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::SortIndex{names}) where {names}
    searchrow = NamedTuple{names}(ie.data)
    return searchsorted(t, searchrow)
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::SortIndex{names2}) where {names, names2}
    searchrow = Project{names2}()(NamedTuple{names}(ie.data))
    t_projected = Project{names2}()(t)
    range = searchsorted(t_projected, searchrow)
    out = Int[]
    @inbounds for i ∈ range
        if ie(t[i])
            push!(out, i)
        end
    end

    return out
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names}) where {names}
    n = length(t)
    searchrow = NamedTuple{names}(ie.data)
    first_greater_or_equal = searchsortedfirst(t, searchrow)
    if first_greater_or_equal <= n && ie(t[first_greater_or_equal])
        return Int[first_greater_or_equal]
    else
        return Int[]
    end
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::UniqueSortIndex{names2}) where {names, names2}
    n = length(t)
    searchrow = Project{names2}()(NamedTuple{names}(ie.data))
    t_projected = Project{names2}()(t)
    first_greater_or_equal = searchsortedfirst(t_projected, searchrow)
    if first_greater_or_equal <= n && ie(t[first_greater_or_equal])
        return Int[first_greater_or_equal]
    else
        return Int[]
    end
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::HashIndex{names}) where {names}
    searchrow = NamedTuple{names}(ie.data)
    return get(() -> Int[], index.dict, searchrow)
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::HashIndex{names2}) where {names, names2}
    searchrow = Project{names2}()(NamedTuple{names}(ie.data))
    inds = get(() -> Int[], index.dict, searchrow)
    if length(inds) == 0
        return inds
    end
    return filter(i -> @inbounds(ie(t[i])), inds)
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names}) where {names}
    searchrow = NamedTuple{names}(ie.data)
    i = get(() -> 0, index.dict, searchrow)
    if i > 0
        return Int[i]
    else
        return Int[]
    end
end

function _findall(ie::IsEqual{names}, t::Table{names}, index::UniqueHashIndex{names2}) where {names, names2}
    searchrow = Project{names2}()(NamedTuple{names}(ie.data))
    i = get(() -> 0, index.dict, searchrow)
    if i > 0 && @inbounds(ie(t[i]))
        return Int[i]
    else
        return Int[]
    end
end

# TODO similarly for findfirst, findlast, findnext, findprev, findmin, findmax

# TODO filter for IsEqual
