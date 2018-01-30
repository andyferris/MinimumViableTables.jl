# Select a subset of columns 
# TODO more general "select" with renaming, mapping, etc?

function project end

struct Project{names}
end
@inline Project(names::Tuple{Vararg{Symbol}}) = Project{names}()

(::Project{names})(x) where {names} = project(x, names)

@inline function project(nt::NamedTuple, names::Tuple{Vararg{Symbol}})
    return _project(nt, Val(names))
end

@generated function _project(nt::NamedTuple{names}, ::Val{names2}) where {names, names2}
    exprs = [:(getproperty(nt, $(Expr(:quote, n)))) for n in names2]
    return quote
        @_inline_meta
        return NamedTuple{names2}(tuple($(exprs...)))
    end
end
