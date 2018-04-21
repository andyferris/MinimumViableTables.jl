# A table presents itself as a vector of named tuple

struct Table{names, T <: NamedTuple{names}, Vs <: Tuple{Vararg{AbstractVector}}, As <: Tuple{Vararg{AbstractIndex}}} <: AbstractVector{T}
    data::Vs
    accelerators::As
end

Table(;kwargs...) = Table(kwargs.data) # TODO `index` keyword argument?
Table(nt::NamedTuple{names}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names} = Table{names}(Tuple(nt), index)

Table{names}(;kwargs...) where {names} = Table{names}(kwargs.data) # TODO `index` keyword argument?

function Table{names}(data::Tuple{Vararg{AbstractVector}}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names}
    T = _eltypes(data)
    return Table{names, NamedTuple{names, T}, typeof(data), typeof(index)}(data, index)
end

function Table{names}(nt::NamedTuple{names, <:Tuple{Vararg{AbstractVector}}}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names}
    Table{names}(Tuple(nt), index)
end

function Table{names}(nt::NamedTuple{names2, <:Tuple{Vararg{AbstractVector}}}, index::Tuple{Vararg{AbstractIndex}} = ()) where {names, names2}
    if _issetequal(names, names2)
        data = getindices(nt, names)
        return Table{names}(data, index)
    else
        error("Table column names $names do not match input data with names $names2")
    end
end

# Helpers to get the data directly from the Table struct
accelerators(::AbstractVector{<:NamedTuple}) = ()
accelerators(t::Table) = Core.getfield(t, :accelerators)
getdata(t::Table) = Core.getfield(t, :data)

# Simple column access via `table.columnname`
@inline Base.getproperty(t::Table, name::Symbol) = getdata(t)[_find(colnames(t), name)]

colnames(::AbstractArray{<:NamedTuple{names}}) where {names} = names
columns(t::Table{names}) where {names} = NamedTuple{names}(getdata(t))

@inline size(t::Table) = size(first(getdata(t)))
@inline axes(t::Table) = axes(first(getdata(t)))

@generated function getindex(t::Table{names}, i::Int) where {names}
    exprs = [:($(names[j]) = getdata(t)[$j][i]) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        $(Expr(:tuple, exprs...))
    end
end

@generated function getindex(t::Table{names}, i::AbstractVector{Int}) where {names}
    exprs = [:(getdata(t)[$j][i]) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        return Table{names}($(Expr(:tuple, exprs...)), ())  # Indexing always removes acceleration indexes, for now
    end
end

function getindex(t::Table{names}, ::Colon) where {names}
    return Table{names}(copy.(getdata(t)), ()) # Indexing always removes acceleration indexes, for now (compare with `copy`)
end

@generated function setindex!(t::Table{names}, v::NamedTuple{names2}, i) where {names, names2}
    if !issetequal(names, names2)
        return quote
            error("Attempted to assign named tuple with names $names2 to table with names $names")
        end
    end

    # TODO - rebuild indices? or make them immutable? or let the user "use with care"?

    exprs = [:(getdata(t)[$j][i] = getproperty(v, $(Expr(:quote, names[j])))) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        if accelerators(t) !== ()
            error("Mutating tables with acceleration indexes currently unsupported")
        end
        $(Expr(:block, exprs...))
        return v
    end
end

function similar(t::Table, ::Type{NamedTuple{names, Ts}}, dims::Tuple{Int}) where {names, Ts}
    data = _makevectors(Ts, dims)
    return Table{names}(data)
end

function copy(t::Table{names}) where {names}
    return Table{names}(copy.(getdata(t)), copy.(accelerators(t)))
end

@inline function (p::Project{names})(t::Table) where {names}
    data = p(columns(t))
    indexes = p(accelerators(t))
    return Table{names}(Tuple(data), indexes)
end

@inline function (r::Rename{oldnames, newnames})(t::Table{names}) where {oldnames, newnames, names}
    names2 = _rename(Val(oldnames), Val(newnames), Val(names))
    return Table{names2}(getdata(t), r(accelerators(t)))
end
