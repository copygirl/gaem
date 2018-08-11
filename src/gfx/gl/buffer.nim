import opengl

type
  ## Represents an OpenGL buffer object.
  Buffer* = object
    handle*: GLhandle
    target*: BufferTarget
  
  BufferTarget* {.pure.} = enum GLenum
    Array = GL_ARRAY_BUFFER
  
  ## Frequency:
  ## - STREAM: The data store contents will be modified once and used at most a few times.
  ## - STATIC: The data store contents will be modified once and used many times.
  ## - DYNAMIC: The data store contents will be modified repeatedly and used many times.
  ## Access:
  ## - DRAW: The data store contents are modified by the application, and used as the source for GL drawing and image specification commands.
  ## - READ: The data store contents are modified by reading data from the GL, and used to return that data when queried by the application.
  ## - COPY: The data store contents are modified by reading data from the GL, and used as the source for GL drawing and image specification commands.
  BufferUsageHint* {.pure.} = enum GLenum
    StaticDraw = GL_STATIC_DRAW

converter toHandle*(value: Buffer): GLhandle = value.handle
converter toEnum*(value: BufferTarget): GLenum = value.GLEnum
converter toEnum*(value: BufferUsageHint): GLenum = value.GLEnum


## Generates a new OpenGL Buffer object with the specified target.
proc newBuffer*(target: BufferTarget): Buffer =
  result = Buffer(target: target)
  glGenBuffers(1, addr(result.handle))

## Binds the specified Buffer.
proc `bind`*(buffer: Buffer) =
  glBindBuffer(buffer.target, buffer)

## Initializes a Buffer's data store with the specified data.
proc data*[T](buffer: Buffer, data: var seq[T],
              usage = BufferUsageHint.StaticDraw) =
  glBufferData(buffer.target, data.len * sizeof(T), addr(data[0]), usage)


## Generates, binds and initialized a Buffer with the specified data.
proc createBuffer*[T](target: BufferTarget, data: var seq[T],
                      usage = BufferUsageHint.StaticDraw): Buffer =
  result = newBuffer(target)
  result.`bind`()
  result.data(data, usage)
