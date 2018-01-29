

@pure function _issubset(a::Tuple{Vararg{Symbol}}, b::Tuple{Vararg{Symbol}}) where {N}
    for sa ∈ a
        if sa ∉ b
            return false
        end
    end
    return true
end

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

