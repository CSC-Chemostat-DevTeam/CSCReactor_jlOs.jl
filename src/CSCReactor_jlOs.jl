module CSCReactor_jlOs
    using LibSerialPort
    using Dates
    using Serialization

    
    #! include base
    include("base/0_types.jl")
    include("base/1_constants.jl")
    include("base/csvlines.jl")
    include("base/inOs_interface.jl")
    include("base/serial.jl")
    include("base/log.jl")

end