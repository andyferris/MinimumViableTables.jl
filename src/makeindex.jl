# Index constructors
NoIndex(t::Table) = NoIndex()

function UniqueIndex{names}(t::Table) where {names}
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
    d = Dict{eltype(t), Vector{Int}}()
    for i in keys(t_projected) # TODO make faster
        row = d[i]
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
    d = Dict{eltype(t), Int}()
    for i in keys(t_projected) # TODO make faster
        row = d[i]
        if haskey(d, row)
            error("Columns $names do not contain unique values")
        else
            d[row] = i
        end
    end
    return UniqueHashIndex{names}(d)
end

# Generic function for adding a new index to a Table
function makeindex(::Type{I}, t::Table{names}) where {I <: AbstractIndex, names}
    newindex = I(t)
    return Table{names}(t.data, (t.indexes..., newindex))
end
