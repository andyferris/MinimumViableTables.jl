# Index constructors
NoIndex(t::Table) = NoIndex()

function UniqueIndex{names}(t::Table) where {names}
    # TODO check columns actually exist in table
    # TODO add uniqueness check? Maybe a keyword argument or `@checkbounds` or something
    return UniqueIndex{names}()
end

function SortIndex{names}(t::Table) where {names}
    order = sortperm(Project(names)(t))
    return SortIndex{names}(order)
end

function UniqueSortIndex{names}(t::Table) where {names}
    # TODO add uniqueness check? Maybe a keyword argument or `@checkbounds` or something
    order = sortperm(Project(names)(t))
    return UniqueSortIndex{names}(order)
end

function HashIndex{names}(t::Table) where {names}
    t_projected = Project(names)(t)
    d = Dict{_valuetype(eltype(t_projected)), Vector{Int}}()
    for i in keys(t_projected) # TODO make faster
        row = Tuple(t_projected[i])
        if haskey(d, row)
            push!(d[row], i)
        else
            d[row] = Int[i]
        end
    end
    return HashIndex{names}(d)
end

function UniqueHashIndex{names}(t::Table) where {names}
    t_projected = Project(names)(t)
    d = Dict{_valuetype(eltype(t_projected)), Int}()
    for i in keys(t_projected) # TODO make faster
        row = Tuple(t_projected[i])
        if haskey(d, row)
            error("Columns $names do not contain unique values")
        else
            d[row] = i
        end
    end
    return UniqueHashIndex{names}(d)
end

"""
    accelerate(table, AcceleratorType)

Returns a new table with an acceleration index of the specified type. The output table
may be faster at certain operations like `filter` with a relavent `Predicate`, however the
input table will remain unchanged.

See also `accelerate!`.
"""
function accelerate(t::Table{names}, ::Type{I}) where {I <: AbstractIndex, names}
    newindex = I(t)
    return Table{names}(getdata(t), (accelerators(t)..., newindex))
end

"""
    accelerate!(table, AcceleratorType)

Returns a new table with an acceleration index of the specified type. The output table may
be faster at certain operations like `filter` with a `Predicate`. The order of rows in the
input table may be changed in-place to optimize locality and further increase speed - for 
example the rows may be ordered by one of the columns. However, the input table will not
have the knowledge of the acceleration index attached - take care to use the output table
after this operation.

See also `accelerate`.
"""
function accelerate!(t::Table{names}, ::Type{<:AbstractIndex})
    return accelerate(t, I)
end

function accelerate!(t::Table{<:Any,<:Any,Tuple{}}, ::Type{SortIndex{names}}) where {names}
    order = sortperm(Project(names)(t))
    foreach(col -> permute!(col, order), getdata(t))
    return Table{names}(getdata(t), (SortIndex{names}(order),))
end

function accelerate!(t::Table{<:Any,<:Any,Tuple{}}, ::Type{UniqueSortIndex{names}}) where {names}
    order = sortperm(Project(names)(t))
    foreach(col -> permute!(col, order), getdata(t))
    return Table{names}(getdata(t), (UniqueSortIndex{names}(order),))
end

# TODO tests for above