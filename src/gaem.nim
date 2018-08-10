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

var projection: Mat4[float32]
var modelview: Mat4[float32]

# ========================================

log(sevDebug, "main", "Loading shaders")

let program = newProgram()
program.attach(loadShaderFile(ShaderType.Vertex, "./assets/shader/core.vert"))
program.attach(loadShaderFile(ShaderType.Fragment, "./assets/shader/core.frag"))
program.glBindAttribLocation(0, "inPosition")
program.glBindAttribLocation(1, "inColor")
program.link()
let projectionLoc = program.getUniform("projection")
let modelviewLoc  = program.getUniform("modelview")
program.use()


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
glGenVertexArrays(1, addr(vao))
vao.glBindVertexArray()
vBuffer.`bind`()
glVertexAttribPointer(0, 3, cGL_FLOAT, false, 0, nil)
cBuffer.`bind`()
glVertexAttribPointer(1, 4, cGL_FLOAT, false, 0, nil)
glEnableVertexAttribArray(0)
glEnableVertexAttribArray(1)


# ========================================

log(sevDebug, "main", "Starting game loop")

var running = true

proc stop*() {.noconv.} =
  running = false

setControlCHook(stop)

proc processEvents() =
  for event in pollEvents():
    case event.kind:
      of evQuit:
        running = false
      of evKeyDown:
        if event.keysym.scancode == SDL_SCANCODE_ESCAPE:
          running = false
      else: discard

var tick = 0
while running:
  processEvents()
  
  let size = getWindowSize()
  glViewport(0, 0, GLSizei(size.width), GLSizei(size.height))
  
  let aspect = size.width.toFloat / size.height.toFloat
  projection = perspective(radians(75'f32), aspect, 0.1, 100)
  modelview  = lookAt(vec3f(0, 2, -3), vec3f(0, 0, 0), vec3f(0, 1, 0))
    .rotate(tick.toFloat() * 0.01, vec3f(0, 1, 0))
  
  projectionLoc.set(projection)
  modelviewLoc.set(modelview)
  
  
  glClear(BG_COLOR)
  vao.glBindVertexArray()
  glDrawArrays(GL_TRIANGLES, 0, GLsizei(cube.len))
  
  swapBuffers()
  inc tick


# ========================================

log(sevInfo, "main", "Shutting down")
destroyWindow()
