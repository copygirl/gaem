import
  glm,
  ../event,
  ../input,
  ./utility

type Camera* = object
  position*: Vec3f
  yaw*, pitch*, roll*: float32
  speed*: float32

var mouseMotion = vec2f(0, 0) # Buffered mouse motion. Applied in update().
var keyForward, keyBack, keyRight, keyLeft, keyUp, keyDown: bool

proc quat*(c: Camera): Quatf =
  quat(UP, c.yaw) * quat(RIGHT, c.pitch) * quat(FORWARD, -c.roll)

proc   right*(c: Camera): Vec3f = c.quat *   RIGHT
proc    left*(c: Camera): Vec3f = c.quat *    LEFT
proc      up*(c: Camera): Vec3f = c.quat *      UP
proc    down*(c: Camera): Vec3f = c.quat *    DOWN
proc forward*(c: Camera): Vec3f = c.quat * FORWARD
proc    back*(c: Camera): Vec3f = c.quat *    BACK

proc viewTransform*(c: Camera): Transform =
  rotation(c.roll, FORWARD) * rotation(c.pitch, RIGHT) * rotation(c.yaw, UP) *
    translation(vec3f(-c.position.x, -c.position.y, c.position.z))

proc update*(c: var Camera, updateTime: float) =
  c.yaw   += mouseMotion[0] / 100.0
  c.pitch += mouseMotion[1] / 100.0
  mouseMotion = vec2f(0, 0)
  
  let f = updateTime * c.speed
  if keyForward: c.position += c.forward * f
  if    keyBack: c.position += c.back    * f
  if   keyRight: c.position += c.right   * f
  if    keyLeft: c.position += c.left    * f
  if      keyUp: c.position +=   UP * f
  if    keyDown: c.position += DOWN * f


KeyDownEvent.subscribe proc(keysym: KeySym) =
  case keysym.scancode:
    of SDL_SCANCODE_W: keyForward = true
    of SDL_SCANCODE_S:    keyBack = true
    of SDL_SCANCODE_D:   keyRight = true
    of SDL_SCANCODE_A:    keyLeft = true
    of SDL_SCANCODE_SPACE:    keyUp = true
    of SDL_SCANCODE_LSHIFT: keyDown = true
    else: discard

KeyUpEvent.subscribe proc(keysym: KeySym) =
  case keysym.scancode:
    of SDL_SCANCODE_W: keyForward = false
    of SDL_SCANCODE_S:    keyBack = false
    of SDL_SCANCODE_D:   keyRight = false
    of SDL_SCANCODE_A:    keyLeft = false
    of SDL_SCANCODE_SPACE:    keyUp = false
    of SDL_SCANCODE_LSHIFT: keyDown = false
    else: discard

MouseMotionEvent.subscribe proc(args: MouseMotionEventArgs) =
  if mbRight.isDown:
    mouseMotion += vec2f(args.motion[0].toFloat, args.motion[1].toFloat)

MouseDownEvent.subscribe proc(args: MouseButtonEventArgs) =
  setRelativeMouseMode(true)
MouseUpEvent.subscribe proc(args: MouseButtonEventArgs) =
  setRelativeMouseMode(false)
