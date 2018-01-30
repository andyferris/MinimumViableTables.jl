# Filters are predicates on rows which can hopefully take advantage of acceleration indexes

struct IsEqual{names, D <: Tuple}
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

promote_indexes(t::Tuple{Vararg{Indexes}}) = t[1]
promote_indexes(t::Tuple{}) = NoIndex()

function map(ie::IsEqual{names}, t::Table) where {names}
    # First get the indices using the acceleration indices
    t_projected = Project(names)(t)
    index = promote_index(t_projected.indexes...)
    return _map(ie, t_projected, promote_index(t_projected.indexes...))
end

function _map(ie::IsEqual{names}, t::Table, ::NoIndex) where {names}
    map(row -> isequal(_vales(row), ie.data), t)::AbstractVector{Bool}
end

function _map(ie::IsEqual{names}, t::Table, ::UniqueIndex) where {names}
    out = fill(false, length(t))
    i = findfirst(ie, t)
    if i === nothing
        return out
    else
        @inbounds out[i] = true
        return out
    end
end

# TODO sorted indices

function _map(ie::IsEqual{names}, t::Table, index::HashIndex{names}) where {names}
    out = fill(false, length(t))

    if haskey(index.d, ie.data) # TODO make faster
        inds = index.d[ie.data]
        @inbounds out[inds] = true
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table, index::HashIndex{names2}) where {names, names2}
    out = fill(false, length(t))

    if haskey(index.d, project(ie.data, names2))
        inds = index.d[ie.data] # TODO make faster
        @inbounds for i in inds
            if ie(t[i])
                out[i] = true
            end
        end
    end

    return out
end

function _map(ie::IsEqual{names}, t::Table, index::UniqueHashIndex{names}) where {names}
    out = fill(false, length(t))

    if haskey(index.d, ie.data) # TODO make faster
        i = index.d[ie.data]
        @inbounds out[i] = true
    end
    
    return out
end

function _map(ie::IsEqual{names}, t::Table, index::UniqueHashIndex{names2}) where {names, names2}
    out = fill(false, length(t))
    key = project(ie.data, names2)

    if haskey(index.d, key) # TODO make faster
        i = index.d[key]
        @inbounds out[i] = ie(t[i])
    end
    
    return out
end
