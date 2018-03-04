# Acceleration index types for one or more columns

abstract type AbstractIndex{names}; end
abstract type AbstractUniqueIndex{names} <: AbstractIndex{names}; end

# By default, indices will be invalidated if some of the indexed columns are removed
@inline function (::Project{n})(i::AbstractIndex{names}) where {names, n}
    if _issubset(names, n)
        return i
    else
        return NoIndex()
    end
end

struct NoIndex <: AbstractIndex{()}
end
copy(index::NoIndex) = index

(::Rename{oldnames, newnames})(::NoIndex) where {oldnames, newnames} = NoIndex()

# This index states that the indicated columns have unique values according to `isequal`
struct UniqueIndex{names} <: AbstractIndex{names}
end
copy(index::UniqueIndex) = index

function (::Rename{oldnames, newnames})(::UniqueIndex{names}) where {oldnames, newnames, names}
    return UniqueIndex{_rename(Val(oldnames), Val(newnames), Val(names))}()
end

# Lexicographically ordered
struct SortIndex{names, V <: AbstractVector{Int}} <: AbstractIndex{names}
    order::V # The row indices in sort order
end
SortIndex{names}(v::V) where {names, V} = SortIndex{names, V}(v)
copy(index::SortIndex{names}) where {names} = SortIndex{names}(copy(index.order))

function (::Rename{oldnames, newnames})(index::SortIndex{names}) where {oldnames, newnames, names}
    return SortIndex{_rename(Val(oldnames), Val(newnames), Val(names))}(index.order)
end

@inline function (::Project{n})(i::SortIndex{names}) where {names, n}
    ns = _headsubset(Val(names), Val(n))
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
copy(index::UniqueSortIndex{names}) where {names} = UniqueSortIndex{names}(copy(index.order))

function (::Rename{oldnames, newnames})(index::UniqueSortIndex{names}) where {oldnames, newnames, names}
    return UniqueSortIndex{_rename(Val(oldnames), Val(newnames), Val(names))}(index.order)
end

@inline function (::Project{n})(i::UniqueSortIndex{names}) where {names, n}
    ns = _headsubset(Val(names), Val(n))
    if ns === ()
        return NoIndex()
    elseif ns === names
        return i
    else # We drop uniqueness, but maintain lexicographical ordering
        return SortIndex{ns}(i.order)
    end
end

# Hash table acceleration index to unknown number of rows
struct HashIndex{names, D <: AbstractDict{<:Tuple, <:AbstractVector{Int}}} <: AbstractIndex{names}
    dict::D # Mapping from column values to list of matching indices
end
HashIndex{names}(d::D) where {names, D} = HashIndex{names, D}(d)
copy(index::HashIndex{names}) where {names} = HashIndex{names}(copy(index.d))

function (::Rename{oldnames, newnames})(index::HashIndex{names}) where {oldnames, newnames, names}
    return HashIndex{_rename(Val(oldnames), Val(newnames), Val(names))}(index.dict)
end

# Hash table acceleration index to unique rows
struct UniqueHashIndex{names, D <: AbstractDict{<:Tuple, Int}} <: AbstractUniqueIndex{names}
    dict::D # Mapping from column values to unique matching index
end
UniqueHashIndex{names}(d::D) where {names, D} = UniqueHashIndex{names, D}(d)
copy(index::UniqueHashIndex{names}) where {names} = UniqueHashIndex{names}(copy(index.d))

function (::Rename{oldnames, newnames})(index::UniqueHashIndex{names}) where {oldnames, newnames, names}
    return UniqueHashIndex{_rename(Val(oldnames), Val(newnames), Val(names))}(index.dict)
end
