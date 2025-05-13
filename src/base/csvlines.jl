## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# This is the communication protocole between Arduino <-> PC
function parse_csvline!(pkg::Dict, line)
    
    rec_ack = get!(pkg, "rec_ack") do
        Dict{String, Any}()
    end
    echo = get!(pkg, "echo") do
        Dict{String, Any}()
    end
    done_ack = get!(pkg, "done_ack") do
        Dict{String, Any}()
    end
    responses = get!(pkg, "responses") do
        Dict{Int, Any}()
    end

    # is csv line
    # m = match(r"\A\$.*\%\Z", line)
    startswith(line, '\$') || return
    endswith(line, '%') || return
    
    line = strip(line, ['\$', '%'])
    tokens = split(line, ':')

    # is ack line
    # \$ACK:37944:6814:RECIEVED!!!%
    if isempty(rec_ack)
        first(tokens) == "ACK" || return
        last(tokens) == "RECIEVED!!!" || return
        rec_ack["csvline"] = line
        rec_ack["tokens"] = tokens
        rec_ack["cmdhash"] = parse(Int, tokens[2])
        rec_ack["timetag"] = parse(Int, tokens[3])
        return
    end
    
    # is echo line
    # $ECHO:4904:2669:DHT11:MEASSURE:52::::::::::::::::::::::::::::::%
    if tokens[1] == "ECHO"
        echo["csvline"] = line
        echo["tokens"] = tokens
        echo["cmdhash"] = parse(Int, tokens[2])
        echo["timetag"] = parse(Int, tokens[3])
        return
    end

    # responses
    # $RES:0:37944:6829:read:1021%
    if tokens[1] == "RES"
        res_num = parse(Int, tokens[2])
        res = Dict()
        res["csvline"] = line
        res["tokens"] = tokens
        res["res_num"] = res_num
        res["cmdhash"] = parse(Int, tokens[3])
        res["timetag"] = parse(Int, tokens[4])
        res["data"] = tokens[5:end]
        responses[res_num] = res
        return
    end

    # done ack
    # \$ACK:37944:6844:DONE!!!%
    if isempty(done_ack)
        first(tokens) == "ACK" || return
        last(tokens) == "DONE!!!" || return
        done_ack["csvline"] = line
        done_ack["tokens"] = tokens
        done_ack["cmdhash"] = parse(Int, tokens[2])
        done_ack["timetag"] = parse(Int, tokens[3])
        return
    end

    return pkg
end

## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# CSV COMMAND
function csvcmd(args...)
    args_str = join((string(arg) for arg in args), ":")
    return string("\$", args_str, "%")
end

# TODO/ Implement cmd group
# - usage case: some times, a single hight level operation needs several commands
function send_csvcmd(sp::SerialPort, args...; 
        tout = 1, 
        log = true, 
        log_extras::Dict = Dict()
    )
    # write
    jl_cmdhash = crc16_hash(args, UInt16(0)) |> Int |> string

    # write
    pkg = Dict{String, Any}()
    pkg["log_extras"] = log_extras
    pkg["time_tag"] = Dates.now()
    _serial_write(sp, csvcmd(args...); tout)
    # read
    while true
        line = _serial_readline(sp; tout)
        isnothing(line) && break
        contains(line, jl_cmdhash) || continue
        parse_csvline!(pkg, line)
        # TODO: check hash and timelines
        # - keep data hash, but include in the msg a random hash 
        # to uniquelly identify each msg
        isempty(pkg["done_ack"]) || break
    end
    log && logres(pkg)
    pkg
end

## ---. .- .- ... - -- ... - -.- .- .-.-- .-- --
function _vec_as_dict(vec::Vector)
    @assert length(vec) % 2 == 0 "Vector must have an even number of elements (key-value pairs)."
    Dict{String, Any}(string(vec[i]) => vec[i+1] for i in 1:2:length(vec))
end

_tryparse(::Type{<:AbstractString}, s::AbstractString) = s
_tryparse(T, s) = tryparse(T, s)

# find first response data
# - assume _vec_as_dict (vad) format
function vad_data(res::Dict, key::String, dflt = nothing; T = String)
    haskey(res, "responses") || return dflt
    for (_, dat) in res["responses"]
        haskey(dat, "data") || continue
        _dict = _vec_as_dict(dat["data"])
        haskey(_dict, key) || continue
        _val = _tryparse(T, getindex(_dict, key))
        return isnothing(_val) ? dflt : _val
    end
    return dflt
end


function res_success(res)
    haskey(res, "done_ack") || return false
    isempty(res["done_ack"]) && return false
    return true
end

## ---. .- .- ... - -- ... - -.- .- .-.-- .-- --
#  Hashing
#  from: https://forum.arduino.cc/t/simple-checksum-that-a-noob-can-use/300443/3
#  TOSYNC
function crc16_hash(c::Char, crc::UInt16)
    crc = crc ⊻ UInt16(c)
    for i in 1:8
        if crc & 1 == 1
            crc = (crc >> 1) ⊻ 0xA001
        else
            crc = crc >> 1
        end
    end
    return crc
end

function crc16_hash(str::AbstractString, crc::UInt16)
    for c in str
        crc = crc16_hash(c, crc)
    end
    return crc
end

function crc16_hash(strs, crc::UInt16)
    for str in strs
        crc = crc16_hash(string(str), crc)
    end
    return crc
end