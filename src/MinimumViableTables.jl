module MinimumViableTables

using Base: @pure, @propagate_inbounds, @_propagate_inbounds_meta, @_inline_meta, 
            getproperty

import Base: size, axes, getindex, setindex!, show, similar, copy, filter, map

using Indexing

export colnames, project, Project, addindex

export AbstractIndex, AbstractUniqueIndex, NoIndex, UniqueIndex, HashIndex, UniqueHashIndex,
       SortIndex, UniqueSortIndex

export Table, IsEqual

include("util.jl")
include("project.jl")
include("index.jl")
include("indices.jl")
include("table.jl")
include("makeindex.jl")
include("filters.jl")

end # module

# Fundamental relational algebra operations:
#
# Set and bag operations: union, setdiff, intersect, isunique, vcat (from Julia AbstractVector interface)
# Projections: project, Project{names} (also map)
# Selections: filter (accelerated when using filter predicates like IsEqual)
# Renames: TODO rename, Rename{oldnames, newnames} (also map)
# Cartesian product: todo
#
# The above also relate to joins with (abstract) relations... we can think about this...
#
# Some performance improvements:
#
# * The unique searching cases tend to return 0 or 1 elements. A "Nullable" like vector
#   (an immutable AbstractVector of length 0 or 1) could be a performance help in these
#   cases.
#
# * Perhaps use faster sorting (radix, etc)
#
# * Perhaps investigate performance of Dict
#
# * Primary keys (particulary lexicographical sort) and the ability to reorder a table
#   to suite one (or more) acceleration indexes (i.e. improve memory locality).
#
# * Think about memory locality and hash-based acceleration indexes.
#
# * Consider tables with row storage.
#
# * More views.