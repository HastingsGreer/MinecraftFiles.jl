include("minecraft_files.jl")

@time chunks = getChunks("mc/r.0.0.mca")



@time surfaceChunked = get_heightmap.(1:32, (1:32)'; chunks=chunks)
0
@time mc_surface = vcat((hcat(surfaceChunked[:, i]...) for i in 1:32)...)
