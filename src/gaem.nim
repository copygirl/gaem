import
  # Dependencies
  glm,
  opengl,
  strutils,
  
  # Project imports
  config,
  window,
  
  gfx/color,
  gfx/gl/buffer,
  gfx/gl/shader,
  
  util/log


const BG_COLOR = newColorRGB(0x441111)

var
  running = true
  projectionLoc , modelviewLoc : Uniform
  projection    , modelview    : Mat4f

proc stop*() {.noconv.} =
  running = false

proc onWindowResized() =
  let size = getWindowSize()
  glViewport(0, 0, size.width.GLSizei, size.height.GLSizei)
  let aspect = size.width.toFloat / size.height.toFloat
  projection = perspective(radians(75'f32), aspect, 0.1, 100)
  projectionLoc.set(projection)

setControlCHook(stop)


# ========================================

log(sevDebug, "main", "Creating game window")

initWindow("gaem - " & VERSION, (1280, 720))
loadExtensions()

when not defined(release):
  proc debugMessageCallback(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum,
                            length: GLsizei, message: ptr GLchar, userParam: pointer) {.stdcall.} =
    log(sevDebug, "OpenGL", $message)
  glDebugMessageCallback(debugMessageCallback, nil)
  glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DEBUG_SEVERITY_NOTIFICATION, 0, nil, false)

glEnable(GL_BLEND)
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

glEnable(GL_DEPTH_TEST)

glEnable(GL_CULL_FACE)
glFrontFace(GL_CCW)


# ========================================

log(sevDebug, "main", "Loading shaders")

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
modelview = lookAt(vec3f(0, 2, -3), vec3f(0, 0, 0), vec3f(0, 1, 0))
modelviewLoc.set(modelview)


# ========================================

log(sevDebug, "main", "Creating buffers and VAOs")

# Vertex Array / Buffer setup
# TODO: Move this into helper class.

# Y   
# | Z 
# |/  
# *--X

#    *--------*
#   /        /|
#  /        / |
# *--------*  |
# |\_      |  |
# |  \_ #2 |  *
# | #1 \_  | /
# |      \_|/
# *--------*

var cube = @[
  # Left (-X)
  vec3f(-1.0, -1.0,  1.0), vec3f(-1.0,  1.0,  1.0), vec3f(-1.0, -1.0, -1.0),
  vec3f(-1.0,  1.0, -1.0), vec3f(-1.0, -1.0, -1.0), vec3f(-1.0,  1.0,  1.0),
  # Right (+X)
  vec3f( 1.0, -1.0, -1.0), vec3f( 1.0,  1.0, -1.0), vec3f( 1.0,  1.0,  1.0),
  vec3f( 1.0,  1.0,  1.0), vec3f( 1.0, -1.0,  1.0), vec3f( 1.0, -1.0, -1.0),
  # Bottom (-Y)
  vec3f(-1.0, -1.0,  1.0), vec3f(-1.0, -1.0, -1.0), vec3f( 1.0, -1.0,  1.0),
  vec3f( 1.0, -1.0, -1.0), vec3f( 1.0, -1.0,  1.0), vec3f(-1.0, -1.0, -1.0),
  # Top (+Y)
  vec3f(-1.0,  1.0, -1.0), vec3f(-1.0,  1.0,  1.0), vec3f( 1.0,  1.0,  1.0),
  vec3f( 1.0,  1.0,  1.0), vec3f( 1.0,  1.0, -1.0), vec3f(-1.0,  1.0, -1.0),
  # Back (-Z)
  vec3f(-1.0,  1.0,  1.0), vec3f( 1.0, -1.0,  1.0), vec3f( 1.0,  1.0,  1.0), #1
  vec3f(-1.0,  1.0,  1.0), vec3f(-1.0, -1.0,  1.0), vec3f( 1.0, -1.0,  1.0), #2
  # Front (+Z)
  vec3f(-1.0, -1.0, -1.0), vec3f(-1.0,  1.0, -1.0), vec3f( 1.0,  1.0, -1.0),
  vec3f( 1.0,  1.0, -1.0), vec3f( 1.0, -1.0, -1.0), vec3f(-1.0, -1.0, -1.0),
];

var cubeColors = @[
  C_MAROON, C_MAROON, C_MAROON, C_MAROON, C_MAROON, C_MAROON, # Left
  C_RED,    C_RED,    C_RED,    C_RED,    C_RED,    C_RED,    # Right
  C_GREEN,  C_GREEN,  C_GREEN,  C_GREEN,  C_GREEN,  C_GREEN,  # Bottom
  C_LIME,   C_LIME,   C_LIME,   C_LIME,   C_LIME,   C_LIME,   # Top
  C_NAVY,   C_NAVY,   C_NAVY,   C_NAVY,   C_NAVY,   C_NAVY,   # Back
  C_BLUE,   C_BLUE,   C_BLUE,   C_BLUE,   C_BLUE,   C_BLUE,   # Front
];

let vBuffer = createBuffer(BufferTarget.Array, cube)
let cBuffer = createBuffer(BufferTarget.Array, cubeColors)

var vao: GLuint
glGenVertexArrays(1, vao.addr)
vao.glBindVertexArray()
vBuffer.`bind`()
glVertexAttribPointer(0, 3, cGL_FLOAT, false, 0, nil)
cBuffer.`bind`()
glVertexAttribPointer(1, 4, cGL_FLOAT, false, 0, nil)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)


# ========================================

log(sevDebug, "main", "Starting game loop")

proc processEvents() =
  for event in pollEvents():
    case event.kind:
      of evQuit:
        running = false
      of evResize:
        onWindowResized()
      of evKeyDown:
        # Quit the game when the ESCAPE key is pressed.
        if event.keysym.scancode == SDL_SCANCODE_ESCAPE:
          running = false
      of evMouseMotion:
        if mbRight.isDown:
          var yaw = event.mouseMotion[0].toFloat / 100.0
          modelview.rotateInpl(yaw, vec3f(0, 1, 0))
          modelviewLoc.set(modelview)
      # FIXME: Relative mouse doesn't work with sway / wayland :(
      # of evMouseDown:
      #   setRelativeMouseMode(true)
      # of evMouseUp:
      #   setRelativeMouseMode(false)
      else: discard

while running:
  processEvents()
  
  glClear(BG_COLOR)
  vao.glBindVertexArray()
  glDrawArrays(GL_TRIANGLES, 0, cube.len.GLsizei)
  
  swapBuffers()


# ========================================

log(sevInfo, "main", "Shutting down")
destroyWindow()
