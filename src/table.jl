# A table presents itself as a vector of named tuple

struct Table{names, T <: NamedTuple, Vs <: Tuple{Vararg{AbstractVector}}, Is <: Tuple{Vararg{AbstractIndex}}} <: AbstractVector{T}
    data::Vs
    indexes::Is
end

@inline axes(t::Table) = axes(first(t.data))

@generated function getindex(t::Table{names}, i::Int) where {names}
    exprs = [:($(names[j]) = t.data[$j][i]) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        $(Expr(:tuple, exprs...))
    end
end

@generated function setindex!(t::Table{names}, v::NamedTuple{names2}, i) where {names, names2}
    if !issetequal(names, names2)
        error("Attempted to assign named tuple with names $names2 to table with names $names")
    end

    # TODO - rebuild indices? or make them immutable? or let the user "use with care"?

    exprs = [:(t.data[$j][i] = v[$(names[j])]) for j = 1:length(names)]
    return quote
        @_propagate_inbounds_meta
        exprs...
    end
end

function show(io::IO, ::MIME"text/plain", table::Table)
    n = length(table)
    println(io, "Table with $n rows and $(length(table)) and ")
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