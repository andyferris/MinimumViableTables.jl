# MinimumViableTables

[![Build Status](https://travis-ci.org/andyferris/MinimumViableTables.jl.svg?branch=master)](https://travis-ci.org/andyferris/MinimumViableTables.jl)

[![Coverage Status](https://coveralls.io/repos/andyferris/MinimumViableTables.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/andyferris/MinimumViableTables.jl?branch=master)

[![codecov.io](http://codecov.io/github/andyferris/MinimumViableTables.jl/coverage.svg?branch=master)](http://codecov.io/github/andyferris/MinimumViableTables.jl?branch=master)

An attempt to make a minimal interface for *fast* tables in Julia. The minimum viable table
will provide:
 
 * Convenient yet minimalistic API and syntax - many operations are idiomatic Julia.
 * Fast iteration of rows - strongly typed data structures.
 * Extensible system of acceleration indices - an external package may introduce e.g. 
   accelerated spatial indexing.
 * A "complete" system for relational algebra

A "table" is a finite relation, which is simply a collection of named tuples (rows). Here,
we think of this as any `AbstractVector{<:NamedTuple{names}}` (though we may extend this to
`AbstractDict`s later). To make certain operations faster, tables may provide a set of
"acceleration indices" which allow mapping of some condition to the row indices. These 
might include a mapping from the hash of some columns to a row index, or the row indices
sorted in a certain order.