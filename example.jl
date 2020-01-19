include("minecraft_files.jl")

function bigHeightMap(fname)
   chunks = getChunks(fname)
   surfaceChunked = get_heightmap.(1:32, (1:32)'; chunks=chunks)
   big_surface = vcat((hcat(surfaceChunked[:, i]...) for i in 1:32)...)
   return big_surface
end

function bhm_coords(i, j)
   fname = "mc/r." * string(i) * "." * string(j) * ".mca"
   if isfile(fname)
       return bigHeightMap(fname)
   end
   return nothing
end
function wholeworld_heightmap()
   scene = Scene()
   for i = -10:10
     for j = -10:10

        chunks = bhm_coords(i, j)

        if chunks != nothing
           println(i, j)
           chunks[1, 2] = 0
           chunks[1, 1] = 128
           heatmap!(scene, 512 * j: 512 * j + 512, 512 * i: 512 *i + 512, chunks', scale_plot=false)
        end
     end
   end

   return scene
end


#println(sections)
function getSection(chunk, i)
   sections = chunk.payload[1].payload[12].payload
   section = sections[i]
   pallete = section[2].payload


   N = max(Int64(ceil(log2(length(pallete)))), 4)

   blockstatesP = section[1].payload

   blockstates = reshape(getN(blockstatesP, N, 16 * 16 * 16), (16, 16, 16)) .!= 0
   return blockstates
end

function namesFromPalette(tag)
   return [filter((x) -> x.name == "Name", elem)[1].payload for elem in tag.payload]
end

chunks = getChunks("mc\\r.0.0.mca")
#heatmap(bhm_coords(0, 0), scale_plot=false)
#
#heatmap(get_heightmap(6, 6; chunks=chunks))

chunk = chunks[6, 6]

sections = chunk.payload[1].payload[12].payload

mv = hcat((getSection(chunk, i) for i in 2:12)...)

scene = Scene()
volume!(scene, mv .* 1.)
cc = cameracontrols(scene)
cc.rotationspeed[] = .004
update!(scene)
cc.eyeposition[] = .5 .* cc.eyeposition[] .+ .5 .* cc.lookat[]
cc.eyeposition[] = .5 .* cc.eyeposition[] .+ .5 .* cc.lookat[]
cc.eyeposition[] = .5 .* cc.eyeposition[] .+ .5 .* cc.lookat[]
#scene
