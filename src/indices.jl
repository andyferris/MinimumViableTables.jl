# Operations on groups of indices

# Remove `NoIndex` from the list (TODO find a better name)
clean(t::Tuple{Vararg{AbstractIndex}}) = _clean(t...)
_clean(t, ts...) = (t, _clean(ts...)...)
_clean(::NoIndex, ts...) = _clean(ts...)
_clean() = ()

function (p::Project{n})(accelerators::Tuple{Vararg{AbstractIndex}}) where {n}
    return clean(map(p, accelerators))
end

promote_index(accelerators...) = promote_accelerators(accelerators)
promote_accelerators(t::Tuple{Vararg{AbstractIndex}}) = t[1]
promote_accelerators(t::Tuple{}) = NoIndex()

@inline function (r::Rename{oldnames, newnames})(accelerators::Tuple{Vararg{AbstractIndex}}) where {oldnames, newnames}
    map(r, accelerators)
end
