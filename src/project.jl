# Select a subset of columns 
# TODO more general "select" with renaming, mapping, etc?

struct Project{names}
end
@inline Project(names::Tuple{Vararg{Symbol}}) = Project{names}()

@inline Project(n1::Symbol) = Project{(n1,)}()
@inline Project(n1::Symbol, n2::Symbol) = Project{(n1, n2)}()
@inline Project(n1::Symbol, n2::Symbol, n3::Symbol) = Project{(n1, n2, n3)}()
@inline Project(n1::Symbol, n2::Symbol, n3::Symbol, n4::Symbol) = Project{(n1, n2, n3, n4)}()
# TODO generalize this - constant propagation doesn't like slurping.

@inline project(x, names::Tuple{Vararg{Symbol}}) = Project{names}()(x)

@generated function (::Project{names2})(nt::NamedTuple{names}) where {names, names2}
    exprs = [:(getproperty(nt, $(Expr(:quote, n)))) for n in names2]
    return quote
        @_inline_meta
        return NamedTuple{names2}(tuple($(exprs...)))
    end
end
