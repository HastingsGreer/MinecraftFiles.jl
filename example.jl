include("minecraft_files.jl")

function bigHeightMap(fname)
   chunks = getChunks(fname)
   surfaceChunked = get_heightmap.(1:32, (1:32)'; chunks=chunks)
   big_surface = vcat((hcat(surfaceChunked[:, i]...) for i in 1:32)...)
   return big_surface
end

function bhm_coords(i, j)
   fname = "../mcserver3/world/region/r." * string(i) * "." * string(j) * ".mca"
   if isfile(fname)
       return bigHeightMap(fname)
   end
   return nothing
end

scene = Scene()
for i = -10:10
  for j = -10:10
     println(i, j)
     chunks = bhm_coords(i, j)
     
     if chunks != nothing
        chunks[1, 2] = 0
        chunks[1, 1] = 256
        surface!(scene, 512 * j: 512 * j + 512, 512 * i: 512 *i + 512, chunks')
     end
  end
end

scene
