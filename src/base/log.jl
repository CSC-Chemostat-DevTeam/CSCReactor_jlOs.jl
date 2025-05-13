## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
LOG_DIR = ""
CURR_LOGFILE = ""
CURR_LOGDAT::Vector{Dict} = []

export logdir!
function logdir!(dir)
    global LOG_DIR = dir
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _trydeserialize(file, dflt; rm = true)
    try
        !isfile(file) && return dflt
        return deserialize(file)
    catch err
        @error err
        (err isa InterruptException) && rethrow(err)
        rm && Base.rm(file; force = true)
        return dflt
    end
end

function _tryserialize(file::String, dat)
    err = nothing
    while true
        try
            serialize(file, dat)
        catch _err
            err = _err
            @error err
        end
        # ignore InterruptException till serialize
        (err isa InterruptException) && continue
        break
    end
    (err isa InterruptException) && rethrow(_err)
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-

function _curr_loaddat(file::String)
    global CURR_LOGFILE, CURR_LOGDAT
    file == CURR_LOGFILE && return CURR_LOGDAT
    _dat = _trydeserialize(file, []; rm = true)
    CURR_LOGFILE = file
    CURR_LOGDAT = _dat
    return CURR_LOGDAT
end


## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _logfile(prefix = ""; dir = LOG_DIR, ext = ".jls")
    isempty(LOG_DIR) && return ""
    date_tag = Dates.format(Dates.now(), "dd-mm-YYYY-HH-MM")
    return joinpath(dir, string(prefix, date_tag, ext))
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
export logres
function logres(res; prefix = "")
    _file = _logfile(prefix)
    isempty(_file) && return ""
    mkpath(dirname(_file))
    dat = _curr_loaddat(_file)
    push!(dat, res)
    _tryserialize(_file, dat)
    return res
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
export foreach_log
function foreach_log(f::Function, log_dir::String = LOG_DIR; 
        len = Int(1e10)
    )
    !isdir(LOG_DIR) && return;
    files_ = readdir(log_dir; join = true)
    sort!(files_)
    for (i, fn) in enumerate(files_)
        dat0 = _trydeserialize(fn, []; rm = false)
        for dat1 in dat0
            f(dat1) === :break && return
        end
        i < len || break;
    end
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
nothing


