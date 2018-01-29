module MinimumViableTables

using Base: @pure, @propagate_inbounds, @_propagate_inbounds_meta

export project
export AbstractIndex, AbstractUniqueIndex, NoIndex, UniqueIndex, HashIndex, UniqueHashIndex,
       SortIndex, UniqueSortIndex

include("util.jl")
include("project.jl")
include("index.jl")
include("indices.jl")
include("table.jl")

end # module
