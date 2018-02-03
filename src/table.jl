# A table presents itself as a vector of named tuple

struct Table{names, T <: NamedTuple{names}, Vs <: Tuple{Vararg{AbstractVector}}, Is <: Tuple{Vararg{AbstractIndex}}} <: AbstractVector{T}
    data::Vs
    indexes::Is
end

Table(;kwargs...) = Table(kwargs.data) # TODO `index` keyword argument?
Table(nt::NamedTuple{names}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names} = Table{names}(_values(nt), index)

Table{names}(;kwargs...) where {names} = Table{names}(kwargs.data) # TODO `index` keyword argument?

function Table{names}(data::Tuple{Vararg{AbstractVector}}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names}
    T = _eltypes(data)
    return Table{names, NamedTuple{names, T}, typeof(data), typeof(index)}(data, index)
end

function Table{names}(nt::NamedTuple{names, <:Tuple{Vararg{AbstractVector}}}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names}
    Table{names}(_values(nt), index)
end

function Table{names}(nt::NamedTuple{names2, <:Tuple{Vararg{AbstractVector}}}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names, names2}
    if _issetequal(names, names2)
        data = getindices(nt, names)
        return Table{names}(data, index)
    else
        error("Table column names $names do not match input data with names $names2")
    end
end

colnames(::Table{names}) where {names} = names
columns(t::Table{names}) where {names} = NamedTuple{names}(t.data)

getindexes(::AbstractVector{<:NamedTuple}) = ()
getindexes(t::Table) = Core.getfield(t, :indexes) # Do we want `getproperty(t, name) = columns(t).name`?

@inline size(t::Table) = size(first(t.data))
@inline axes(t::Table) = axes(first(t.data))

@generated function getindex(t::Table{names}, i::Int) where {names}
    exprs = [:($(names[j]) = t.data[$j][i]) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        $(Expr(:tuple, exprs...))
    end
end

@generated function getindex(t::Table{names}, i::AbstractVector{Int}) where {names}
    exprs = [:(t.data[$j][i]) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        return Table{names}($(Expr(:tuple, exprs...)), ())  # Indexing always removes acceleration indexes, for now
    end
end

function getindex(t::Table{names}, ::Colon) where {names}
    return Table{names}(copy.(t.data), ()) # Indexing always removes acceleration indexes, for now (compare with `copy`)
end

@generated function setindex!(t::Table{names}, v::NamedTuple{names2}, i) where {names, names2}
    if !issetequal(names, names2)
        return quote
            error("Attempted to assign named tuple with names $names2 to table with names $names")
        end
    end

    # TODO - rebuild indices? or make them immutable? or let the user "use with care"?

    exprs = [:(t.data[$j][i] = getproperty(v, $(Expr(:quote, names[j])))) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        $(Expr(:block, exprs...))
        return v
    end
end

function show(io::IO, ::MIME"text/plain", table::Table)
    n = length(table)
    n_index = length(getindexes(table))
    println(io, "Table with $n $(n == 1 ? "row" : "rows") and $n_index acceleration $(n_index == 1 ? "index" : "indexes")")
    for i = 1:min(n, 5)
        print(io, " ", table[i])
        if i != min(n, 5)
            print(io, "\n")
        end
    end
    if n > 5
        print(io, "\n ...")
    end
end

function similar(t::Table, ::Type{NamedTuple{names, Ts}}, dims::Tuple{Int}) where {names, Ts}
    data = _makevectors(Ts, dims)
    return Table{names}(data)
end

function copy(t::Table{names}) where {names}
    return Table{names}(copy.(t.data), copy.(getindexes(t)))
end

@inline function project(t::Table, names::Tuple{Vararg{Symbol}})
    data = getindices(NamedTuple{colnames(t)}(t.data), names)
    indexes = project(getindexes(t), names)
    return Table{names}(data, indexes)
end
