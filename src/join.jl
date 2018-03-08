function innerjoin; end

const ⨝ = innerjoin

# TODO make signature compatible with theta-joins, etc.
function innerjoin(t1::Table{n1}, t2::Table{n2}) where {n1, n2}
    all_names = _union(n1, n2)
    same_names = _interesect(Val(n1), Val(n2))
    new_names = _tempnames(Val(same_names))
    
    @assert length(same_names) === 1 # TODO fix `Equals`...

    t2_renamed = Rename(same_names, new_names)(t2)
    t3 = filter(Equals{(same_names..., new_names...)}, t1 × t2_renamed)
    return Project{(all_names,)}()(t3)
end

# TODO how do "outer" joins work in this framework?
