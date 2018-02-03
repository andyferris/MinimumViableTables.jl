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
    d = Dict{eltype(t_projected), Vector{Int}}()
    for i in keys(t_projected) # TODO make faster
        row = t_projected[i]
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
    d = Dict{eltype(t_projected), Int}()
    for i in keys(t_projected) # TODO make faster
        row = t_projected[i]
        if haskey(d, row)
            error("Columns $names do not contain unique values")
        else
            d[row] = i
        end
    end
    return UniqueHashIndex{names}(d)
end

# Generic function for adding a new index to a Table
function addindex(t::Table{names}, ::Type{I}) where {I <: AbstractIndex, names}
    newindex = I(t)
    return Table{names}(t.data, (getindexes(t)..., newindex))
end
