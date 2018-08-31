import
  # Dependencies
  glm,
  opengl,
  
  # Project imports
  ./config,
  
  ./core/event,
  ./core/input,
  ./core/window,
  
  ./gfx/color,
  ./gfx/gl,
  ./gfx/gl/buffer,
  
  ./util/log


log(sevInfo, "main", "Starting gaem ", VERSION)

var running = true

proc stop*() {.noconv.} =
  running = false

# Since stop() is {.noconv.} it only works like so:
QuitEvent.subscribe proc() = stop()

setControlCHook(stop)


# ========================================

log(sevDebug, "main", "Creating game window")

initWindow("gaem - " & VERSION, (1280, 720))
initOpenGL()
loadShaders()


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

var camera = lookAt(vec3f(0, 2, -3), vec3f(0, 0, 0), vec3f(0, 1, 0))

KeyDownEvent.subscribe proc(keysym: KeySym) =
  # Quit the game when the ESCAPE key is pressed.
  if keysym.scancode == SDL_SCANCODE_ESCAPE:
    running = false

MouseMotionEvent.subscribe proc(args: MouseMotionEventArgs) =
  if mbRight.isDown:
    var yaw = args.motion[0].toFloat / 100.0
    camera.rotateInpl(yaw, vec3f(0, 1, 0))

MouseDownEvent.subscribe proc(args: MouseButtonEventArgs) =
  setRelativeMouseMode(true)
MouseUpEvent.subscribe proc(args: MouseButtonEventArgs) =
  setRelativeMouseMode(false)

while running:
  processEvents()
  
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
  
  withModelview(camera):
    vao.glBindVertexArray()
    glDrawArrays(GL_TRIANGLES, 0, cube.len.GLsizei)
  
  swapBuffers()


# ========================================

log(sevInfo, "main", "Shutting down")
destroyWindow()
