import
  # Dependencies
  glm,
  opengl,
  sdl2,
  strutils,
  
  # Project imports
  config,
  
  gfx/color,
  gfx/window,
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

# FIXME: Don't hardcode, get window size somehow.
glViewport(0, 0, 1280, 720)


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

var projection = perspective(radians(75'f32), 800 / 450'f32, 0.1, 100)
var modelview  = lookAt(vec3f(2, 2, 2), vec3f(0, 0, 0), vec3f(0, 1, 0))
projectionLoc.set(projection)


# ========================================

log(sevDebug, "main", "Creating buffers and VAOs")

# Vertex Array / Buffer setup
# TODO: Move this into helper class.
var cube = @[
  vec3f(-1.0, -1.0, -1.0), vec3f(-1.0, -1.0,  1.0), vec3f(-1.0,  1.0,  1.0),
  vec3f( 1.0,  1.0, -1.0), vec3f(-1.0, -1.0, -1.0), vec3f(-1.0,  1.0, -1.0),
  vec3f( 1.0, -1.0,  1.0), vec3f(-1.0, -1.0, -1.0), vec3f( 1.0, -1.0, -1.0),
  vec3f( 1.0,  1.0, -1.0), vec3f( 1.0, -1.0, -1.0), vec3f(-1.0, -1.0, -1.0),
  vec3f(-1.0, -1.0, -1.0), vec3f(-1.0,  1.0,  1.0), vec3f(-1.0,  1.0, -1.0),
  vec3f( 1.0, -1.0,  1.0), vec3f(-1.0, -1.0,  1.0), vec3f(-1.0, -1.0, -1.0),
  vec3f(-1.0,  1.0,  1.0), vec3f(-1.0, -1.0,  1.0), vec3f( 1.0, -1.0,  1.0),
  vec3f( 1.0,  1.0,  1.0), vec3f( 1.0, -1.0, -1.0), vec3f( 1.0,  1.0, -1.0),
  vec3f( 1.0, -1.0, -1.0), vec3f( 1.0,  1.0,  1.0), vec3f( 1.0, -1.0,  1.0),
  vec3f( 1.0,  1.0,  1.0), vec3f( 1.0,  1.0, -1.0), vec3f(-1.0,  1.0, -1.0),
  vec3f( 1.0,  1.0,  1.0), vec3f(-1.0,  1.0, -1.0), vec3f(-1.0,  1.0,  1.0),
  vec3f( 1.0,  1.0,  1.0), vec3f(-1.0,  1.0,  1.0), vec3f( 1.0, -1.0,  1.0)
];
var cubeColors = @[
  C_RED,    C_RED,    C_RED,    C_RED,    C_RED,    C_RED,
  C_LIME,   C_LIME,   C_LIME,   C_LIME,   C_LIME,   C_LIME,
  C_BLUE,   C_BLUE,   C_BLUE,   C_BLUE,   C_BLUE,   C_BLUE,
  C_YELLOW, C_YELLOW, C_YELLOW, C_YELLOW, C_YELLOW, C_YELLOW,
  C_PURPLE, C_PURPLE, C_PURPLE, C_PURPLE, C_PURPLE, C_PURPLE,
  C_WHITE,  C_WHITE,  C_WHITE,  C_WHITE,  C_WHITE,  C_WHITE
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
    case event.kind
    of EventType.QuitEvent:
      running = false
    else: discard

while running:
  processEvents()
  
  modelview = modelview.rotate(0.01, vec3f(0, 1, 0))
  modelviewLoc.set(modelview)
  
  glClear(BG_COLOR)
  vao.glBindVertexArray()
  glDrawArrays(GL_TRIANGLES, 0, GLsizei(cube.len))
  
  swapBuffers()


# ========================================

log(sevInfo, "main", "Shutting down")
destroyWindow()
