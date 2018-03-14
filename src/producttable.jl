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
#columns(t::ProductTable{names}) where {names} = NamedTuple{names}(map(name ->)
#getindexes(t::ProductTable) = (getindexes(t.t1)..., getindexes(t.t2)...)

@inline function (p::Project{names})(t::ProductTable{<:Any, <:Any, <:AbstractVector{<:NamedTuple{n1}}, <:AbstractVector{<:NamedTuple{n2}}}) where {n1, n2, names}
    p1 = Project{_intersect(Val(names), Val(n1))}()
    p2 = Project{_intersect(Val(names), Val(n2))}()
    # TODO ensure no other names left over
    ProductTable(p1(t.t1), p2(t.t2))
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

# Filter - seperate case where predicate applies just to one part of the product table
function filter(pred::Predicate{names}, t::ProductTable{<:Any, <:Any, <:AbstractVector{<:NamedTuple{n1}}, <:AbstractVector{<:NamedTuple{n2}}}) where {names, n1, n2}
    if _issubset(names, n1)
        return ProductTable(filter(pred, t.t1), t.t2)
    elseif _issubset(names, n2)
        return ProductTable(t.t1, filter(pred, t.t2))
    end
    return @inbounds t[findall(pred, t)] # Don't use map - requires N^2 memory and most joins are sparse
end

# Map

# First layer of dispatch seperates cases where predicate applies just to one part of the product table
function map(pred::Predicate{names}, t::ProductTable{<:Any, <:Any, <:AbstractVector{<:NamedTuple{n1}}, <:AbstractVector{<:NamedTuple{n2}}}) where {names, n1, n2}
    if _issubset(names, n1)
        return ProductArray((x, y) -> x, map(pred, t.t1), Array{Nothing}(undef, size(t.t2)))
    elseif _issubset(names, n2)
        return ProductArray((x, y) -> y, Array{Nothing}(undef, size(t.t1)), map(pred, t.t2))
    end

    n1_projected = _intersect(Val(names), Val(n1))
    n2_projected = _intersect(Val(names), Val(n2))
    names_projected = (n1_projected..., n2_projected...)

    t_projected = project(t, names_projected)
    index1 = promote_index(project(getindexes(t.t1), n1_projected)...)
    index2 = promote_index(project(getindexes(t.t2), n2_projected)...)

    return @inbounds _map(pred, t_projected, index1, index2)
end

# Seperate the cases where we know we can or can't do some acceleration with the predicate
function _map(pred::Predicate, t::ProductTable, ::NoIndex, ::NoIndex)
    out = Array{Bool}(undef, size(t))

    @inbounds for i in keys(t)
        out[i] = pred(t[i])
    end

    return out
end

# Default to applying the accelerated filter to the second table
function _map(pred::Predicate, t::ProductTable, ::Any, ::Any)
    out = Array{Bool}(undef, size(t))
    
    @inbounds for i in keys(t.t1) 
        x = t.t1[i]
        tmp = map(Predicate(pred, x), t.t2)
        out[i, :] = tmp
    end

    return out
end

# If the second table has no acceleration index, try switch the ordering (TODO is this a good idea? Should this be more predictable to the user?)
function _map(pred::Predicate, t::ProductTable, ::Any, ::NoIndex) # Reverse looping order
    out = Array{Bool}(undef, size(t))
    
    @inbounds for i in keys(t.t2)
        x = t.t2[i]
        tmp = map(Predicate(pred, x), t.t1)
        out[:, i] = tmp
    end

    return out
end

# TODO implement a sort-merge join algorithm:

# function _map(pred::IsEqual, t::ProductTable, ::SortIndex, ::SortIndex)
#     ...
# end

# findall

# First layer of dispatch seperates cases where predicate applies just to one part of the product table
function findall(pred::Predicate{names}, t::ProductTable{<:Any, <:Any, <:AbstractVector{<:NamedTuple{n1}}, <:AbstractVector{<:NamedTuple{n2}}}) where {names, n1, n2}
    if _issubset(names, n1)
        return ProductArray((x, y) -> CartesianIndex(x, y), findall(pred, t.t1), keys(t.t2))
    elseif _issubset(names, n2)
        return ProductArray((x, y) -> CartesianIndex(x, y), keys(t.t1), findall(pred, t.t2))
    end

    n1_projected = _intersect(Val(names), Val(n1))
    n2_projected = _intersect(Val(names), Val(n2))
    names_projected = (n1_projected..., n2_projected...)

    t_projected = project(t, names_projected)
    index1 = promote_index(project(getindexes(t.t1), n1_projected)...)
    index2 = promote_index(project(getindexes(t.t2), n2_projected)...)

    return @inbounds _findall(pred, t_projected, index1, index2)
end


# Seperate the cases where we know we can or can't do some acceleration with the predicate
function _findall(pred::Predicate, t::ProductTable, ::NoIndex, ::NoIndex)
    return findall(row -> pred(row), t)
end

# Default to applying the accelerated filter to the second table
function _findall(pred::Predicate, t::ProductTable, ::Any, index2::Any)
    out = Vector{CartesianIndex{2}}()
    
    @inbounds for i in keys(t.t1) 
        x = t.t1[i]
        tmp = _findall(Predicate(pred, x), t.t2, index2)
        for j in tmp # TODO: use a lazily-mapped append!, or something
            push!(out, CartesianIndex(i, j))
        end
    end

    return out
end

# If the second table has no acceleration index, try switch the ordering (TODO is this a good idea? Should this be more predictable to the user?)
function _findall(pred::Predicate, t::ProductTable, index1::Any, ::NoIndex) # Reverse looping order
    out = Vector{CartesianIndex{2}}()
    
    @inbounds for j in keys(t.t2)
        x = t.t2[j]
        tmp = map(Predicate(pred, x), t.t1)
        for i in tmp # TODO: use a lazily-mapped append!, or something
            push!(out, CartesianIndex(i, j))
        end
    end

    return out
end

# Sort-merge join algorithm:

function _findall(pred::Equals, t::ProductTable, index1::SortIndex, index2::SortIndex)
    out = Vector{CartesianIndex{2}}()
    if isempty(t)
        return out
    end
    
    @inbounds t1 = view(t.t1.data[1], index1.order) # a single column.
    n1 = length(t1)
    i1 = 1
    @inbounds x1 = t1[1]

    @inbounds t2 = view(t.t2.data[1], index2.order) # a single column.
    n2 = length(t2)
    i2 = 1
    @inbounds x2 = t2[1]
    
    while true
        if isequal(x1, x2)
            i1_last = searchsortedlast(t1, x1)
            i2_last = searchsortedlast(t2, x2)
            for j1 in i1:i1_last
                for j2 in i2:i2_last
                    @inbounds push!(out, CartesianIndex(index1.order[j1], index2.order[j2]))
                end
            end
            i1 = i1_last + 1; if i1 > n1; break; end
            i2 = i2_last + 1; if i2 > n2; break; end
            @inbounds x1 = t1[i1]
            @inbounds x2 = t2[i2]
        elseif isless(x1, x2)
            i1 = searchsortedfirst(t1, x2); if i1 > n1; break; end
            @inbounds x1 = t1[i1]
        else
            i2 = searchsortedfirst(t2, x1)
            @inbounds x2 = t2[i2]
        end
    end

    return out
end

function _findall(pred::Equals, t::ProductTable, index1::UniqueSortIndex, index2::SortIndex)
    out = Vector{CartesianIndex{2}}()
    if isempty(t)
        return out
    end
    
    @inbounds t1 = view(t.t1.data[1], index1.order) # a single column.
    n1 = length(t1)
    i1 = 1
    @inbounds x1 = t1[1]

    @inbounds t2 = view(t.t2.data[1], index2.order) # a single column.
    n2 = length(t2)
    i2 = 1
    @inbounds x2 = t2[1]
    
    while true
        if isequal(x1, x2)
            i2_last = searchsortedlast(t2, x2)
            for j2 in i2:i2_last
                @inbounds push!(out, CartesianIndex(index1.order[i1], index2.order[j2]))
            end
            i1 = i1 + 1; if i1 > n1; break; end
            i2 = i2_last + 1; if i2 > n2; break; end
            @inbounds x1 = t1[i1]
            @inbounds x2 = t2[i2]
        elseif isless(x1, x2)
            i1 = searchsortedfirst(t1, x2); if i1 > n1; break; end
            @inbounds x1 = t1[i1]
        else
            i2 = searchsortedfirst(t2, x1); if i2 > n2; break; end
            @inbounds x2 = t2[i2]
        end
    end

    return out
end

function _findall(pred::Equals, t::ProductTable, index1::SortIndex, index2::UniqueSortIndex)
    out = Vector{CartesianIndex{2}}()
    if isempty(t)
        return out
    end
    
    @inbounds t1 = view(t.t1.data[1], index1.order) # a single column.
    n1 = length(t1)
    i1 = 1
    @inbounds x1 = t1[1]

    @inbounds t2 = view(t.t2.data[1], index2.order) # a single column.
    n2 = length(t2)
    i2 = 1
    @inbounds x2 = t2[1]
    
    while true
        if isequal(x1, x2)
            i1_last = searchsortedlast(t1, x1)
            for j1 in i1:i1_last
                @inbounds push!(out, CartesianIndex(index1.order[j1], index2.order[i2]))
            end
            i1 = i1_last + 1; if i1 > n1; break; end
            i2 = i2 + 1; if i2 > n2; break; end
            @inbounds x1 = t1[i1]
            @inbounds x2 = t2[i2]
        elseif isless(x1, x2)
            i1 = searchsortedfirst(t1, x2); if i1 > n1; break; end
            @inbounds x1 = t1[i1]
        else
            i2 = searchsortedfirst(t2, x1); if i2 > n2; break; end
            @inbounds x2 = t2[i2]
        end
    end

    return out
end

function _findall(pred::Equals, t::ProductTable, index1::UniqueSortIndex, index2::UniqueSortIndex)
    out = Vector{CartesianIndex{2}}()
    if isempty(t)
        return out
    end
    
    @inbounds t1 = view(t.t1.data[1], index1.order) # a single column.
    n1 = length(t1)
    i1 = 1
    @inbounds x1 = t1[1]

    @inbounds t2 = view(t.t2.data[1], index2.order) # a single column.
    n2 = length(t2)
    i2 = 1
    @inbounds x2 = t2[1]
    
    while true
        if isequal(x1, x2)
            @inbounds push!(out, CartesianIndex(index1.order[i1], index2.order[i2]))
            i1 = i1 + 1; if i1 > n1; break; end
            i2 = i2 + 1; if i2 > n2; break; end
            @inbounds x1 = t1[i1]
            @inbounds x2 = t2[i2]
        elseif isless(x1, x2)
            i1 = searchsortedfirst(t1, x2); if i1 > n1; break; end
            @inbounds x1 = t1[i1]
        else
            i2 = searchsortedfirst(t2, x1); if i2 > n2; break; end
            @inbounds x2 = t2[i2]
        end
    end

    return out
end
