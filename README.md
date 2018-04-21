# MinimumViableTables

[![Build Status](https://travis-ci.org/andyferris/MinimumViableTables.jl.svg?branch=master)](https://travis-ci.org/andyferris/MinimumViableTables.jl)
[![Coverage Status](https://coveralls.io/repos/andyferris/MinimumViableTables.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/andyferris/MinimumViableTables.jl?branch=master)
[![codecov.io](http://codecov.io/github/andyferris/MinimumViableTables.jl/coverage.svg?branch=master)](http://codecov.io/github/andyferris/MinimumViableTables.jl?branch=master)

This package is an attempt to make a minimal interface for *fast* tables and relational
operations in Julia. The primary goals are to provide:
 
 * A minimalistic extension of core Julia concepts to support relational algebra. The common
   definition of a relation is as a collection of named tuples. Here, a `Table` is just an
   `AbstractVector` of `NamedTuple`s, a Cartesian product of tables is an `AbstractMatrix`
   of `NamedTuple`s, and we my support other collections of `NamedTuple`s in the future. 
 * Standard Julia operations are **fast**. A strongly typed data structure provides fast
   iteration of rows. Column-based storage and (some) lazy evaluation provides for efficient
   operations for analytics workloads, and operations like `filter`, `map` and `findall`
   are specialized for speed.
 * An extensible system of acceleration indexes allows for maximal speed, no matter the
   problem or domain. Common acceleration indexes like hash- or sort-based indexes are
   provided by the package, along with `Predicate`s that know how to take advantage of the
   structure. The system is extensible such that an external package may introduce e.g. 
   accelerated spatial indexing, or inverted indexing to support accelearted textual search,
   etc.

The package is a work-in-progress and currently only provides a rather low-level interface
to relational algebra operations and acceleration indexes. A higher-level interface for end
users may be desirable.

## Tables

A "table" is a finite relation, which is simply a collection of named tuples (rows). Here,
we think of this as any `AbstractVector{<:NamedTuple{names}}` (though we may extend this to
`AbstractDict`s later). The package provides a concrete `Table` type which stores data as
columns, but presents it to Julia as rows of `NamedTuple` (i.e. a relation).

Constructing a `Table` is straight forward, such as:

```julia
Table(a = [1,2,3], b = [2.0, 4.0, 6.0])
```

Relational algebra consists of a small set of operations. One can "project" a table to fewer
columns using:
```julia
project(table, (:a, :b))
# or
Project{(:a, :b)}()(table)
```

Similarly columns can be renamed with the `rename` function (or `Rename` singleton type).

Rows can be manipulated with the standard Julia `AbstractVector` interface. Operations like
`vcat`, `union`, `intersect`, `setdiff` will produce new vectors of named tuples. We can
"select" certain rows using `filter`, or find the row indexes of certain rows using `findall`,
or use `map` to construct a boolean array indicating the image of matching- and non-matching rows.
For example, we may chose to use a perfectly standard Julia `filter` operation to obtain only
the rows where the values in column `a` are equal to `1` like so:
```julia
filter(row -> row.a == 1, table)
```

To make certain operations faster, tables may provide a set of "acceleration indexes" which
allow mapping of some condition to the row indices. These might include a mapping from the
hash of some columns to a row index, or the row indices sorted in a certain order, or simply
the knowledge that the values in one or more columns is unique.

## Acceleration Indices

An acceleration index provides information about one-or-more columns of a `Table` to allow
for fast lookup of relevant rows. These indexes may accelerate operations such as filtering
rows, performing grouping and aggregates, or joins with other tables, and are typically 
attached to a `Table` with the `accelerate` function like so:

```julia
table2 = accelerate(table, HashIndex{(:a,)})
```

Multiple indexes may be attached to a single `Table`. The built-in set of `AbstractIndex`es
are:

 * `SortIndex` - prodides the ordering (with respect to `isless`) of the rows of one or more
   columns.
 * `UniqueSortIndex` - like a `SortIndex`, but also with the guarantee that the elements of
   the specified column(s) are unique.
 * `HashIndex` - provides a `Dict` mapping from the values of one or more columns to the
   corresponding row indices.
 * `UniqueHashIndex` - like a `HashIndex`, but also with the guarantee that the elements of
   the specified column(s) are unique.
 * `UniqueIndex` - demarks simply that the elements of certain row(s) are unique.
 * `NoIndex` - an internal placeholder used where no suitable index is found.

External packages are free to create subtypes of `AbstractIndex{names}` and specialized
algorithms that make use of the new accelerations.

## Predicates on a single table

Julia needs a way of determining how to use an acceleration index to make a given operation
faster. We might attempt to use an anonymous function to indicate which rows to select, like
our earlier example:
```julia
filter(row -> row.a == 1, table)
```
Unfortunately, this obscures a lot of information about our query such as that we only care
about the values in column `:a`, and that we are performing an equality comparison to `1`.
This means we have no way of knowing *how* to use one of acceleration indexes to make this
operation faster.

To solve this, this package provides the `Predicate` abstract type.
Subtypes of `Predicate{names}` are `Function`s that always return a `Bool` and depend only on
the values in the columns `names`. Each `Predicate` may be used with `filter`, `findall` or
`map` in combination with an acceleration index to achieve a faster result than a full table
scan. The package will attempt to use the best acceleration index for the given `Predicate`
and operation. Some example usage:

```julia
filter(IsEqual(a = 1), table)
findall(IsLess(b = 2.0), table)
map(In(c = 3..10), table)
```

The built-in predicates designed to work on a single table are:

 * `IsEqual` - returns `true` if a the element is equal to the specified value. For example,
   `filter(IsEqual(a = 1), table)` will use hash- or sort-based acceleration indexes for fast
   searches of rows where the column `:a` is `isequal` to `1`. Multiple columns may be
   specified (such as `IsEqual(a = 1, b = 2.0)`).
 * `IsLess` - returns `true` if the element is less than the specified value. For example,
   `filter(IsEqual(a = 1), table)` will return all the rows where the values of column `:a`
   is less than `1` according to `isless`, and is accelerated by sort-based indexes.
   Multiple columns may be specified.
 * `IsLessEqual` - similar to `LessThan`, but also accepts equal elements.
 * `IsGreater` - similar to `LassThan`, but only accepts greater elements.
 * `IsGreaterEqual` - similar to `LassThan`, but only accepts greater or equal elements.
 * `In` - returns `true` if the element is in a given collection. Specializes for speed on
   `Interval` (which is a minimalistic, v0.7-compatible version of *IntervalSets.jl*). This
   allows for fast "windowing" type searches such as `filter(In(a = 3..10), table)` in
   combination with sort-based indexes. Multiple columns may be provided, for a "box"-style
   search.

## Products of tables, and joins

The final relational algebra operation we haven't mentioned is the Cartesian product of two
tables. This package provides the `ProductTable` type which is an `AbstractMatrix` of
`NamedTuple`s. Example usage:

```julia
t3 = ProductTable(t1, t2)
```

So far, we haven't mentioned a "join" operation. In relation algebra, a join is simply the
combination of a Cartesian product operation followed by a `filter` over a `Predicate` such
as equality between two columns. Predicates that relate multiple columns of a table are
provided and can be used to accelerate `filter`, `findall` and `map` of a `ProductTable`,
i.e. facilitate fast joins. For example

```julia
t4 = filter(Equals(:a, :b), t3)
```
will join `t1` and `t2` on equality of columns `:a` and `:b`. The set of built-in comparitive
`Predicate`s are

 * `Equals` - values in two columns are equal according to `isequal`
 * `LessThan` - value in first column is less than second according to `isless`
 * `LessEqualThan` - value in first column is less than or equal to second
 * `GreaterThan` - value in first column is greater than second
 * `GreaterEqualThan` - value in first column is greater than or equal to second
 * `Within` - values in the two columns are within a specified distance of each other

The joining operation can occur in one of three ways

 * No acceleration index is used, so a full double loop over the two tables is required.
 * A loop is perfomed over the rows of one table (say `t1`) and for each of these rows a
   new `Predicate` is created to query the second table (e.g. `t2`). For example, `Equals`
   may result in a series of `IsEqual` searches on the second table, or `Within` may create
   a series of `In(::Interval)` searches of the second table for windowing-style joins.
 * A sort-merge join is perfomed where two sort-based indexes are available and the predicate
   is `IsEqual`.

## What next?

This package needs some more concise surface-level syntax, such as some concept of `join`
and `groupby` and so-on. One possibility is to integrate this with [SplitApplyCombine.jl](https:github.com/andyferris/SplitApplyCombine.jl).

So far all `Table`s are vectors and `ProductTable`s are limited to 2D. Ideally we could take
the Cartesian product of arbitrarily many tables.

For ultimate speed of complex queries, we will probably need to make some more operations
behave in a lazy, streaming fashion so e.g. multiple filtering operations may occur in a
single loop.

All the predicates are using `isequal` and `isless`, for simplicity. We should really 
support sensible data behavior with `NaN` and `missing`.

As always, performance can be optimized. There are some simple benchmarks in the
`benchmarks/` directory.

I/O operations (including `show`) should be provided somehow (hopefully using the package
ecosystem).
