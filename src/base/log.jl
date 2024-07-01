## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
LOG_DIR = ""

export logdir!
function logdir!(dir)
    global LOG_DIR = dir
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _trydeserialize(file, dflt)
    try
        return deserialize(file)
    catch err
        @error err
        rm(file; force = true)
        return dflt
    end
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _logfile(prefix = ""; dir = LOG_DIR, ext = ".jls")
    isempty(LOG_DIR) && return ""
    now = Dates.now()
    date_tag = Dates.format(now, "dd-mm-YYYY-HH-MM")
    return joinpath(dir, string(prefix, date_tag, ext))
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
export logres
function logres(res; prefix = "")
    _file = _logfile(prefix)
    isempty(_file) && return ""
    mkpath(dirname(_file))
    dat = isfile(_file) ? _trydeserialize(_file, Dict()) :  Dict()
    dat[string(now())] = res
    serialize(_file, dat)
    return res
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
nothing


