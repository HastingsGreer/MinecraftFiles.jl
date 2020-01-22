include("minecraft_files.jl")

function bigHeightMap(fname)
   chunks = getChunks(fname)
   surfaceChunked = get_heightmap.(1:32, (1:32)'; chunks=chunks)
   big_surface = vcat((hcat(surfaceChunked[:, i]...) for i in 1:32)...)
   return big_surface
end

function bhm_coords(i, j)
   fname = "r." * string(i) * "." * string(j) * ".mca"
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
   sections = chunk.payload["Level"]["Sections"]
   if length(sections) < i
      return zeros(UInt8, 16, 16, 16)
   end
   section = sections[i]
   
   if "Palette" in keys(section)
           palette = section["Palette"]
           
           name_array = namesFromPalette(palette)
           
           println(name_array)
           
           


           N = max(Int64(ceil(log2(length(palette)))), 4)

           blockstatesP = section["BlockStates"]

           blockstates = reshape(Array{UInt8, 1}(getN(blockstatesP, N, 16 * 16 * 16)), (16, 16, 16))
           
           
           return blockstates
   else
       return zeros(UInt8, 16, 16, 16)
   end
end

function namesFromPalette(tag)
   return [elem["Name"] for elem in tag]
end

chunks = getChunks("../mcserver3/world/region/r.0.0.mca")
#heatmap(bhm_coords(0, 0), scale_plot=false)
#
#heatmap(get_heightmap(6, 6; chunks=chunks))


function getAirArray(i,j; chunks=chunks)

   chunk = chunks[i, j]
   if(chunk != nullTag && "Sections" in keys(chunk.payload["Level"]))
      sections = chunk.payload["Level"]["Sections"]

      mv = (cat((getSection(chunk, i) for i in 2:12)...; dims=3))
   else
      mv = zeros(UInt8, 16, 16, 176)
   end
   return mv
end

function getSlab(j; chunks=chunks)
   return reduce(vcat, getAirArray.(j, 1:32; chunks=chunks))
end

function getAll(chunks)
   return reduce(hcat, getSlab.(1:32; chunks=chunks))
end
using Makie
#=
scene = Scene()
volume!(scene, myv .* 1.)
cc = cameracontrols(scene)
cc.rotationspeed[] = .004
update!(scene)
cc.eyeposition[] = .5 .* cc.eyeposition[] .+ .5 .* cc.lookat[]
cc.eyeposition[] = .5 .* cc.eyeposition[] .+ .5 .* cc.lookat[]
cc.eyeposition[] = .5 .* cc.eyeposition[] .+ .5 .* cc.lookat[]
#scene
=#
