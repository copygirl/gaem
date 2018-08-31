import
  glm,
  opengl,
  strutils

type
  Program* = object
    ## Represents an OpenGL program object.
    handle*: GLhandle
  
  Shader* = object
    ## Represents an OpenGL shader object.
    handle*: GLhandle
    shaderType*: ShaderType
  
  Uniform* = object
    ## Represents an OpenGL uniform variable for a program object.
    location*: GLint
  
  ShaderType* {.pure.} = enum GLenum
    Fragment = GL_FRAGMENT_SHADER,
    Vertex   = GL_VERTEX_SHADER,
    Geometry = GL_GEOMETRY_SHADER,
    Compute  = GL_COMPUTE_SHADER
  
  ShaderException* = object of Exception

converter toGLhandle*(value: Program): GLhandle = value.handle
converter toGLhandle*(value: Shader): GLhandle = value.handle
converter toGLint*(value: Uniform): GLint = value.location
converter toGLenum*(value: ShaderType): GLenum = value.GLenum

proc getInfoLog[T](obj: T): string =
  ## Returns the information log of the OpenGL object, or nil if none.
  when T is Program: # Decide which procs/values to use based on the object type.
    const
      getiv       = glGetProgramiv
      getInfoLog  = glGetProgramInfoLog
      statusPName = GL_LINK_STATUS
  elif T is Shader:
    const
      getiv       = glGetShaderiv
      getInfoLog  = glGetShaderInfoLog
      statusPName = GL_COMPILE_STATUS
  else: {.error "Only Program and Shader are valid".}
  
  var status: GLint
  getiv(obj, statusPName, addr status)
  if status == 0:
    var logLength: GLsizei
    getiv(obj, GL_INFO_LOG_LENGTH, addr logLength)
    result = newString(logLength)
    getInfoLog(obj, logLength, addr logLength, result)
  else: result = nil

proc checkInfoLog[T](obj: T) =
  ## Raises a ShaderException if the OpenGL object has an information log.
  let log = obj.getInfoLog()
  if not isNil(log):
    raise newException(ShaderException, log)


proc newProgram*(): Program =
  ## Creates and returns a new OpenGL Program.
  Program(handle: glCreateProgram())

proc attach*(program: Program, shader: Shader) =
  ## Attaches a Shader to a Program.
  glAttachShader(program, shader)

proc link*(program: Program) =
  ## Links a Program, raising an exception if it failed.
  glLinkProgram(program)
  program.checkInfoLog()

proc use*(program: Program) =
  ## Intalls a Program as part of the current rendering state.
  glUseProgram(program)


proc newShader*(shaderType: ShaderType): Shader =
  ## Creates a new OpenGL Shader object.
  Shader(handle: glCreateShader(shaderType),
         shaderType: shaderType)

proc source*(shader: Shader, source: string) =
  ## Sets the source code of a Shader.
  let sourceArr = [source].allocCStringArray()
  defer: sourceArr.deallocCStringArray()
  glShaderSource(shader, 1, sourceArr, nil)

proc compile*(shader: Shader) =
  ## Compiles a Shader, raising an exception if it failed.
  glCompileShader(shader)
  shader.checkInfoLog()


proc loadShaderString*(shaderType: ShaderType, source: string): Shader =
  ## Creates and compiles a new Shader from a source string.
  result = newShader(shaderType)
  result.source(source)
  result.compile()

proc loadShaderFile*(shaderType: ShaderType, path: string): Shader =
  ## Creates and compiles a new Shader from a source file.
  loadShaderString(shaderType, readFile(path))


proc getUniform*(program: Program, name: string): Uniform =
  let loc = program.glGetUniformLocation(name)
  # This will return -1 for unused (not active) uniforms that have been optimized out..?
  if loc == -1: raise newException(
    ShaderException, "The uniform '$#' could not be retrieved" % [name])
  Uniform(location: loc)

# TODO: Make uniform setting strongly typed?

proc set*(uniform: Uniform, value: Mat4f) =
  uniform.glUniformMatrix4fv(1, false, value.arr[0].arr[0].unsafeAddr)
