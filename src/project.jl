# Select a subset of columns 
# TODO more general "select" with renaming, mapping, etc?

function project end

struct Project{names}
end
@inline Project(names::Tuple{Vararg{Symbol}}) = Project{names}()

(::Project{names})(x) where {names} = project(x, names)
