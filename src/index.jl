# Acceleration index types for one or more columns

abstract type AbstractIndex{names}; end
abstract type AbstractUniqueIndex{names} <: AbstractIndex{names}; end

# TODO rename this pun
isunique(::AbstractUniqueIndex) = true
isunique(::AbstractIndex) = false

# IPO doesn't seem to like this :( We'll have to abondon that API for now...
#@inline project(index::AbstractIndex{names}, n::Symbol...) where {names} = project(index, n)
@inline project(index::AbstractIndex{names}, n::Symbol) where {names} = project(index, (n,))

# By default, indices will be invalidated if some of the indexed columns are removed
@inline function project(i::AbstractIndex{names}, n::Tuple{Vararg{Symbol}}) where names
    if _issubset(names, n)
        return i
    else
        return NoIndex()
    end
end

struct NoIndex <: AbstractIndex{()}
end

# This index states that the indicated columns have unique values according to `isequal`
struct UniqueIndex{names} <: AbstractIndex{names}
end

# Lexicographically ordered
struct SortIndex{names, V <: AbstractVector{Int}} <: AbstractIndex{names}
    order::V # The row indices in sort order
end
SortIndex{names}(v::V) where {names, V} = SortIndex{names, V}(v)

@inline function project(i::SortIndex{names}, n::Tuple{Vararg{Symbol}}) where names
    ns = _headsubset(names, n)
    if ns === ()
        return NoIndex()
    else # We retain lexicographical ordering
        return SortIndex{ns}(i.order)
    end
end

# Lexicographically ordered and unique
struct UniqueSortIndex{names, V <: AbstractVector{Int}} <: AbstractUniqueIndex{names}
    order::V # The row indices in sort order
end
UniqueSortIndex{names}(v::V) where {names, V} = UniqueSortIndex{names, V}(v)

@inline function project(i::UniqueSortIndex{names}, n::Tuple{Vararg{Symbol}}) where names
    ns = _headsubset(names, n)
    if ns === ()
        return NoIndex()
    elseif ns === names
        return i
    else # We drop uniqueness, but maintain lexicographical ordering
        return SortIndex{ns}(i.order)
    end
end

# Hash table acceleration index to unknown number of rows
struct HashIndex{names, D <: AbstractDict{<:Any, <:AbstractVector{Int}}} <: AbstractIndex{names}
    dict::D # Mapping from column values to list of matching indices
end
HashIndex{names}(d::D) where {names, D} = HashIndex{names, D}(d)

# Hash table acceleration index to unique rows
struct UniqueHashIndex{names, D <: AbstractDict{<:Any, Int}} <: AbstractUniqueIndex{names}
    dict::D # Mapping from column values to unique matching index
end
UniqueHashIndex{names}(d::D) where {names, D} = UniqueHashIndex{names, D}(d)
