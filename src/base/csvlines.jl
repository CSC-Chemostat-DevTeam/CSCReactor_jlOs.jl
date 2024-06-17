## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
# This is the communication protocole between Arduino <-> PC
export parse_csvline!
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
    if !isempty(rec_ack) && isempty(echo)
        echo["csvline"] = line
        echo["tokens"] = tokens
        return
    end

    # responses
    # \$RES:0:37944:6829:read:1021%
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
export csvcmd
function csvcmd(args...)
    args_str = join((string(arg) for arg in args), ":")
    return string("\$", args_str, "%")
end

export send_csvcmd
function send_csvcmd(sp::SerialPort, args...; tout = 1)
    # write
    pkg = Dict{String, Any}()
    _serial_write(sp, csvcmd(args...); tout)
    while true
        line = _serial_readline(sp; tout)
        isnothing(line) && break
        parse_csvline!(pkg, line)
        # TODO: check hash and timelines
        # - keep data hash, but include in the msg a random hash 
        # to uniquelly identify each msg
        isempty(pkg["done_ack"]) || break
    end
    pkg
end
