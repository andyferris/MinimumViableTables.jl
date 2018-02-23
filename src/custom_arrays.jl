"""
    ProductArray(f, a1, a2)

Takes the Cartesian product of two arrays, `a1` and `a2`, by applying `f` to each pairwise
combination of elements of `a1` and `a2`. The dimensionality of the output is the sum of
the dimensionality of the inputs.

# Examples

julia> ProductArray(tuple, 1:3, 1:4)
3×4 ProductArray{Tuple{Int64,Int64},2,typeof(tuple),UnitRange{Int64},UnitRange{Int64}}:
 (1, 1)  (1, 2)  (1, 3)  (1, 4)
 (2, 1)  (2, 2)  (2, 3)  (2, 4)
 (3, 1)  (3, 2)  (3, 3)  (3, 4)
"""
struct ProductArray{T, N, F, A1, A2} <: AbstractArray{T, N}
    f::F
    a1::A1
    a2::A2
end

function ProductArray(f::F, a1::AbstractArray{<:Any, n}, a2::AbstractArray{<:Any, m}) where {F, n, m}
    T = Core.Compiler.return_type(f, Tuple{eltype(a1), eltype(a2)})
    return ProductArray{T, _add(n, m), F, typeof(a1), typeof(a2)}(f, a1, a2)
end

size(a::ProductArray) = (size(a.a1)..., size(a.a2)...)
axes(a::ProductArray) = (axes(a.a1)..., axes(a.a2)...)

@propagate_inbounds function getindex(a::ProductArray{T, n}, i::Vararg{Int, n}) where {T, n}
    n1 = ndims(a.a1)
    n2 = ndims(a.a2)

    (i1, i2) = split_inds(Val(n1), Val(n2), i)
    
    x1 = a.a1[i1...]
    x2 = a.a2[i2...]

    return a.f(x1, x2)::T
end

@generated function split_inds(::Val{n1}, ::Val{n2}, i::Tuple{Vararg{Int, n3}}) where {n1, n2, n3}
    @assert n3 == n1 + n2
    
    exprs1 = Any[ :(i[$j]) for j = 1:n1 ]
    exprs2 = Any[ :(i[$j]) for j = (1+n1):n3 ]

    return quote
        @_inline_meta
        return ( tuple($(exprs1...)), tuple($(exprs2...)) )
    end
end

