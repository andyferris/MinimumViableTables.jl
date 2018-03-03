# Operations on groups of indices

# Remove `NoIndex` from the list (TODO find a better name)
clean(t::Tuple{Vararg{AbstractIndex}}) = _clean(t...)
_clean(t, ts...) = (t, _clean(ts...)...)
_clean(::NoIndex, ts...) = _clean(ts...)
_clean() = ()

function (p::Project{n})(indexes::Tuple{Vararg{AbstractIndex}}) where {n}
    return clean(map(p, indexes))
end

promote_index(indexes...) = promote_getindexes(indexes)
promote_getindexes(t::Tuple{Vararg{AbstractIndex}}) = t[1]
promote_getindexes(t::Tuple{}) = NoIndex()

@inline function (r::Rename{oldnames, newnames})(indexes::Tuple{Vararg{AbstractIndex}}) where {oldnames, newnames}
    map(r, indexes)
end
