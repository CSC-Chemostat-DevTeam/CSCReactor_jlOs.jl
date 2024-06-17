using CSCReactor_jlOs
using CSCReactor_jlOs: parse_csvline!
using Test

@testset "CSCReactor_jlOs.jl" begin
    # Write your tests here.
    ## ---.-.- ...- -- .--- . .- .-. . ..- .--.-
    let
        lines = """
        ----------------------
        \$ACK:37944:6814:RECIEVED!!!%
        \$INO:ANALOG-READ:12::::::::::::::%
        \$RES:0:37944:6829:read:1021%
        \$ACK:37944:6844:DONE!!!%
        """ |> split

        pkg = Dict()
        for line in lines
            parse_csvline!(pkg, line)
            !isempty(pkg["done_ack"]) && break
        end
        @test pkg["responses"][0]["cmdhash"] == 37944
        @test pkg["responses"][0]["data"][2] == "1021"
        
    end
end
