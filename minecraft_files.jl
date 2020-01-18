struct Tag
    name::String
    payload::Any
end

const nullTag = Tag("", nothing)


function readTag(stream, the_type, indentations)
    payload = "none"
    if the_type == 0x01
        payload = ntoh(read(stream, Int8))
    end
    if the_type == 0x02
        payload = ntoh(read(stream, Int16))
    end
    if the_type == 0x03
        payload = ntoh(read(stream, Int32))
    end
    if the_type == 0x04
        payload = ntoh(read(stream, Int64))
    end
    if the_type == 0x05
        payload = ntoh(read(stream, Float32))
    end
    if the_type == 0x06
        payload = ntoh(read(stream, Float64))
    end
    if the_type == 0x07
        array_size = ntoh(read(stream, Int32))
        payload = read(stream, array_size)
    end
    if the_type == 0x08
        string_length = ntoh(read(stream, UInt16))
        payload = String(read(stream, string_length))
    end
    if the_type == 0x09
        #println(repeat("--", indentations), "List!")
        the_subtype = read(stream, Int8)
        #println(repeat("--", indentations),"subtype ", the_subtype)
        array_size = ntoh(read(stream, Int32))
        payload =  []
        for i = 1:array_size
            push!(payload, readTag(stream, the_subtype, indentations + 1))
        end
    end
    if the_type == 0x0a
        payload = Tag[]
        newTag = Tag("", 1)
        while newTag != nullTag
            newTag = readNamedTag(stream, indentations + 1)
            if newTag != nullTag
               push!(payload, newTag)
            end
        end
    end
    if the_type == 0xb
        array_size = ntoh(read(stream, Int32))
        payload = Array{Int32, 1}(undef, array_size)
        for i = 1:array_size
            payload[i] = ntoh(read(stream, Int32))
        end
    end
    if the_type == 0xc
        array_size = ntoh(read(stream, Int32))
        payload = Array{UInt64, 1}(undef, array_size)
        for i = 1:array_size
            payload[i] = ntoh(read(stream, UInt64))
        end
    end
    return payload
end

function readNamedTag(stream, indentations=0)
    the_type = read(stream, UInt8)
    if the_type == 0
        return nullTag
    end
    name_length = ntoh(read(stream, UInt16))
    name = String(read(stream, name_length))
    #println(repeat("--", indentations), name, " ", the_type)
    payload = readTag(stream, the_type, indentations + 1)
    return Tag(name, payload)
end

function get_heightmap(z, x; chunks)

    chunk = chunks[z, x]
    if (chunk != nullTag )
        if(chunk.payload[1].payload[7].name == "Heightmaps")
            world_surface = chunk.payload[1].payload[7].payload[4].payload
            return get9(world_surface)
        else
            return zeros(UInt64, (16, 16)) .+ 32
        end
    else
        return zeros(UInt64, (16, 16))
    end
end


function get9(worldheight)
    bita = BitArray(undef, 16 * 16 * 9)
    bita.chunks .= worldheight
    return reshape(map(0:16 * 16 - 1) do i
        bita[1 + 9 * i: 9 + 9 * i].chunks[1]
            end, (16, 16))
end


using CodecZlib
function getChunks(fname)
    locations = Array{UInt32, 2}(undef, 32, 32)
    sizes = Array{UInt8, 2}(undef, 32, 32)

    chunks = Array{Tag, 2}(undef, 32, 32)
    open(fname, "r") do io

        for x = 1:32
            for z = 1:32
                val = ntoh(read(io, Int32))
                locations[x, z] = val >> 8
                sizes[x, z] = val & 255

            end
        end

        for x = 1:32
            for z = 1:32
                compressed_chunk = Array{UInt8, 1}()
                if(locations[z, x] != 0)
                    seek(io, locations[z, x] * 4096)

                    chunk_length = ntoh(read(io, UInt32))
                    compression_type = read(io, UInt8)


                    readbytes!(io, compressed_chunk, chunk_length - 1)

                    uncompressed_chunk = transcode(ZlibDecompressor, compressed_chunk)
                    chunk_buffer = IOBuffer(uncompressed_chunk)

                    chunks[z, x] = readNamedTag(chunk_buffer)
                else
                    chunks[z, x] = nullTag
                end

            end
        end


    end
    return chunks
end
