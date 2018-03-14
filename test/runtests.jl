using MinimumViableTables
using Test

using MinimumViableTables: _issubset, _issetequal, _headsubset, _makevectors, _add, _all,
                           clean, searchsortedlastless, searchsortedfirstgreater,
                           _valuetype, _cat_types, _intersect, _setdiff

# TODO Make an @inferred-like macro to test inference with constant propagation

include("interval.jl")

include("util.jl")
include("project.jl")
include("rename.jl")
include("index.jl")
include("table.jl")
include("rowoperations.jl")
include("makeindex.jl")
include("predicates.jl")

include("custom_arrays.jl")
include("producttable.jl")
