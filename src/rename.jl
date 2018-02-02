struct Rename{oldnames, newnames}
end
@inline Rename(oldnames::Tuple{Vararg{Symbol}}, newnames::Tuple{Vararg{Symbol}}) = Rename{oldnames, newnames}()
@inline Rename(oldname::Symbol, newname::Symbol) = Rename{(oldname,), (newname,)}()

@inline rename(x, oldname::Symbol, newname::Symbol) = Rename(oldname, newname)(x)
@inline rename(x, oldnames::Tuple{Vararg{Symbol}}, newnames::Tuple{Vararg{Symbol}}) = Rename(oldnames, newnames)(x)

@inline function (::Rename{oldnames, newnames})(nt::NamedTuple{names}) where {oldnames, newnames, names}
    return NamedTuple{_rename(oldnames, newnames, names)}(values(nt))
end

@pure function _rename(oldnames::Tuple{Vararg{Symbol}}, newnames::Tuple{Vararg{Symbol}}, names::Tuple{Vararg{Symbol}})
    if length(unique(oldnames)) != length(unique(oldnames))
        error("The old column names $oldnames are not unique")
    end

    if length(unique(newnames)) != length(unique(newnames))
        error("The new column names $newnames are not unique")
    end

    if length(oldnames) != length(newnames)
        error("The number of new column names does not match the number of old column names")
    end

    out = map(names) do n
        i = findfirst(equalto(n), oldnames)
        return i === nothing ? n : newnames[i]
    end

    if length(unique(out)) != length(unique(names))
        error("The output column names $out are not unique")
    end

    return out
end
