using MinimumViableTables
using Test

using MinimumViableTables: _issubset, _issetequal, _headsubset, _makevectors, _values, clean

# TODO Make an @inferred-like macro to test inference with constant propagation

include("util.jl")
include("project.jl")
include("index.jl")
include("table.jl")
include("filters.jl")
