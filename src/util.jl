@pure function _issubset(a::Tuple{Vararg{Symbol}}, b::Tuple{Vararg{Symbol}})
    for sa ∈ a
        if sa ∉ b
            return false
        end
    end
    return true
end

@pure function _issetequal(a::NTuple{N, Symbol}, b::NTuple{N, Symbol}) where {N}
    for sa ∈ a
        if sa ∉ b
            return false
        end
    end
    return true
end
@pure _issetequal(::Tuple{Vararg{Symbol}}, ::Tuple{Vararg{Symbol}}) = false

@pure function _headsubset(a::Tuple{Vararg{Symbol}}, b::Tuple{Vararg{Symbol}})
    out = ()
    for s ∈ a
        if s ∈ b
            out = (out..., s)
        else
            return out
        end
    end
    return out
end

@generated function _eltypes(a::Tuple{Vararg{AbstractVector}})
    Ts = []
    for V in a.parameters
        push!(Ts, eltype(V))
    end
    return Tuple{Ts...}
end

@generated function _makevectors(::Type{Ts}, dims::Tuple{Int}) where {Ts <: Tuple}
    exprs = [:(Vector{$T}(uninitialized, dims)) for T ∈ Ts.parameters]
    return quote
        @_inline_meta
        return tuple($(exprs...))
    end
end

@generated function _values(nt::NamedTuple{names}) where {names}
    exprs = [:(getproperty(nt, $(Expr(:quote, n)))) for n in names]
    return quote
        @_inline_meta
        return tuple($(exprs...))
    end
end
