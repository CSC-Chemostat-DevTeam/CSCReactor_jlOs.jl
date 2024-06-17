struct SCSReactor
    dat::Dict
    SCSReactor() = Dict()
end

# PC <-> Arduino communication protocole
struct CSVMsg
    raw::Vector{String}  # read lines
    parsed::Dict{String, Any}         # parsed data
    CSVMsg() = new(String[], Dict{String, Any}())
end