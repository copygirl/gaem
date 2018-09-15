import
  glm,
  opengl,
  
  ../core/event,
  ../core/window,
  ../util/log,
  
  ./color,
  ./gl/shader


var
  projectionLoc , modelviewLoc : Uniform
  projection    , modelview    : Mat4f

proc setModelview(m: Mat4f) =
  modelview = m
  modelviewLoc.set(m)

template withModelview*(m: Mat4f, body: untyped) =
  let oldModelview = modelview
  setModelview(modelview * m)
  body
  setModelview(oldModelview)


proc onWindowResized() =
  let size = getWindowSize()
  glViewport(0, 0, size.width.GLSizei, size.height.GLSizei)
  let aspect = size.width.toFloat / size.height.toFloat
  projection = perspective(radians(75'f32), aspect, 0.1, 100)
  projectionLoc.set(projection)

ResizeEvent.subscribe(onWindowResized)


proc initOpenGL*() =
  log(sevDebug, "OpenGL", "Initializing OpenGL")
  
  loadExtensions()
  
  when not defined(release):
    proc debugMessageCallback(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum,
                              length: GLsizei, message: ptr GLchar, userParam: pointer) {.stdcall.} =
      log(sevDebug, "OpenGL", $message)
    glDebugMessageCallback(debugMessageCallback, nil)
    glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, nil, false)
  
  let bg = newColorRGB(0x441111)
  glClearColor(bg.red, bg.blue, bg.green, bg.alpha)
  
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  
  glEnable(GL_DEPTH_TEST)
  
  glEnable(GL_CULL_FACE)
  glFrontFace(GL_CCW)

proc loadShaders*() =
  log(sevDebug, "OpenGL", "Loading shaders")
  
  let program = newProgram()
  program.attach(loadShaderFile(ShaderType.Vertex, "./assets/shader/core.vert"))
  program.attach(loadShaderFile(ShaderType.Fragment, "./assets/shader/core.frag"))
  program.glBindAttribLocation(0, "inPosition")
  program.glBindAttribLocation(1, "inColor")
  program.link()
  projectionLoc = program.getUniform("projection")
  modelviewLoc  = program.getUniform("modelview")
  program.use()
  
  onWindowResized()
  setModelview(mat4f())
