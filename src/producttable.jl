struct ProductTable{names, T <: NamedTuple{names}, T1 <: AbstractVector{<:NamedTuple}, T2 <: AbstractVector{<:NamedTuple}} <: AbstractMatrix{T}
    t1::T1
    t2::T2
    # TODO: Extra acceleration indices, like foreign keys / 1-to-1 relationships / etc
end

function ProductTable(t1::AbstractVector{NamedTuple{names1,T1}}, t2::AbstractVector{NamedTuple{names2,T2}}) where {names1, T1, names2, T2}
    names = (names1..., names2...)
    T = NamedTuple{names, _cat_types(T1, T2)}
    return ProductTable{names, T, typeof(t1), typeof(t2)}(t1, t2)
end

size(table::ProductTable) = (size(table.t1)..., size(table.t2)...)
axes(table::ProductTable) = (axes(table.t1)..., axes(table.t2)...)
@propagate_inbounds function getindex(table::ProductTable, i1::Int, i2::Int)
    return merge(table.t1[i1], table.t2[i2])
end

colnames(::ProductTable{names}) where {names} = names
#columns(t::ProductTable{names}) where {names} = NamedTuple{names}(columns(t.t1)..., columns(t.t2)...)
#getindexes(t::ProductTable) = (getindexes(t.t1)..., getindexes(t.t2)...)

@inline function project(t::ProductTable, names::Tuple{Vararg{Symbol}})
    ProductTable(project(t.t1, names), project(t.t2, names))
end

@inline function (r::Rename{oldnames, newnames})(t::ProductTable{names}) where {oldnames, newnames, names}
    names2 = _rename(Val(oldnames), Val(newnames), Val(names))
    return ProductTable{names2}(r(t.t1), r(t.t2))
end

cross(t1::AbstractVector{<:NamedTuple}, t2::AbstractVector{<:NamedTuple}) = ProductTable(t1, t2)

function similar(t::ProductTable, ::Type{NamedTuple{names, Ts}}, dims::Tuple{Int}) where {names, Ts}
    data = _makevectors(Ts, dims)
    return Table{names}(data)
end

function filter(pred::Predicate{names}, t::ProductTable{<:Any, <:Any, <:AbstractVector{<:NamedTuple{n1}}, <:AbstractVector{<:NamedTuple{n2}}}) where {names, n1, n2}
    if _issubset(names, n1)
        return ProductTable(filter(pred, t.t1), t.t2)
    elseif _issubset(names, n2)
        return ProductTable(t.t1, filter(pred, t.t2))
    end
    return @inbounds t[map(pred, t)]
end

# TODO map and findall... need some other lazy containers...

# TODO fast filter on predicates which span tables like Equals, LessThan (etc), Within
