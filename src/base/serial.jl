## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
function _serial_write(sp::SerialPort, data; tout = 1)
    # write
    set_write_timeout(sp, tout)
    try
        write(sp, string(data))
        return true
    catch e
        isa(e, LibSerialPort.Timeout) || rethrow()
    finally
        clear_write_timeout(sp)
    end
    return false
end

function _serial_readline(sp::SerialPort; tout = 1)
    # write
    set_read_timeout(sp, tout)
    line = nothing
    try
        line = readline(sp)
    catch e
        isa(e, LibSerialPort.Timeout) || rethrow()
    finally
        clear_read_timeout(sp)
    end
    return line
end
