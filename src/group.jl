
function group(by::Project{n}, f, t::Table{names}) where {n, names}
    t_projected = Project(n)(t)
    _group
end



function groupinds(by::Project{n}, t::Table{names}) where {n, names}
    return groupinds(by(t))
end

function groupinds(by::Project{names}, t::Table{names}) where {names}
    _groupinds(t, promote_index(t.indexes...))
end
    
function _groupinds(t::Table{names, T}, ::AbstractIndex) where {names, T}
    T = eltype(t)
    inds = keys(t)

    out = Dict{T, Vector{Int}}()
    for i ∈ inds
        @inbounds x = t[i]
        push!(get!(()->Vector{V}(), out, key), i)
    end
    return out
end

function _groupinds(t::Table{names, T}, index::HashIndex{names}) where {names, T}
    return index.dict
end

function _groupinds(t::Table{names, T}, index::UniqueHashIndex{names}) where {names, T}
    d = index.dict

    values = Vector{Vector{Int}}(undef, length(d.values)) # Need SVector{1, Int} or something similarly fast

    @inbounds begin
        i = start(d)
        while !done(d, i)
            (x, i) = next(d, i)
            values[i] = [x]
        end
    end
    return Dict(d.slots, d.keys, values, d.ndel, d.count, d.age, d.idxfloor, d.maxprobe)
end