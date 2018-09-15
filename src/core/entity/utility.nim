import glm


const
  RIGHT*   = vec3f( 1,  0,  0)
  LEFT*    = vec3f(-1,  0,  0)
  UP*      = vec3f( 0,  1,  0)
  DOWN*    = vec3f( 0, -1,  0)
  FORWARD* = vec3f( 0,  0,  1)
  BACK*    = vec3f( 0,  0, -1)


type Transform* = Mat4f

template identity*(): Transform = mat4f()

proc   right*(t: Transform): Vec3f = t[0].xyz
proc      up*(t: Transform): Vec3f = t[1].xyz
proc forward*(t: Transform): Vec3f = t[2].xyz

template left*(t: Transform): Vec3f = -t.right
template down*(t: Transform): Vec3f = -t.up
template back*(t: Transform): Vec3f = -t.forward


proc translation*(t: Vec3f): Transform =
  result = mat4f()
  result.translateInpl(t)
proc translation*(x, y, z: float32): Transform =
  result = mat4f()
  result.translateInpl(x, y, z)

proc rotation*(angle: float32, axis: Vec3f): Transform =
  result = mat4f()
  result.rotateInpl(angle, axis)
proc rotation*(angle: float32, x, y, z: float32): Transform =
  result = mat4f()
  result.rotateInpl(angle, x, y, z)
