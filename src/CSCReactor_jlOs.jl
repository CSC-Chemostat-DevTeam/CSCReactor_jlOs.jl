module CSCReactor_jlOs
    
    using Reexport
    using MassExport
    @reexport using LibSerialPort
    @reexport using Dates
    @reexport using Serialization
    export LibSerialPort
    
    #! include base
    include("base/0_types.jl")
    include("base/1_constants.jl")
    include("base/csvlines.jl")
    include("base/inOs_interface.jl")
    include("base/serial.jl")
    include("base/log.jl")

    @exportall_words()
end