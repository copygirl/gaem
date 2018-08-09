import opengl as gl

type
  Color* = object
    red*: float32
    green*: float32
    blue*: float32
    alpha*: float32


proc newColor*(red, green, blue: float32, alpha = 1.0): Color =
  Color(red: red, green: green, blue: blue, alpha: alpha)

proc newColor*(red, green, blue: int, alpha = 255): Color =
  newColor(float(red) / 255, float(green) / 255, float(blue) / 255, float(alpha) / 255)

proc newColorARGB*(value: int): Color =
  newColor(value shr 16 and 0xFF, value shr 8 and 0xFF, value and 0xFF, value shr 24 and 0xFF)

proc newColorRGB*(value: int): Color =
  newColor(value shr 16 and 0xFF, value shr 8 and 0xFF, value and 0xFF)


proc toARGB*(value: Color): int =
  (int(value.alpha) * 255).clamp(0, 255) shl 24 or
    (int(value.red) * 255).clamp(0, 255) shl 16 or
    (int(value.green) * 255).clamp(0, 255) shl 8 or
    (int(value.blue) * 255).clamp(0, 255)

proc toRGB*(value: Color): int =
  (int(value.red) * 255).clamp(0, 255) shl 16 or
    (int(value.green) * 255).clamp(0, 255) shl 8 or
    (int(value.blue) * 255).clamp(0, 255)


const C_BLACK*   = newColorRGB(0x000000)
const C_SILVER*  = newColorRGB(0xC0C0C0)
const C_GRAY*    = newColorRGB(0x808080)
const C_WHITE*   = newColorRGB(0xFFFFFF)
const C_MAROON*  = newColorRGB(0x800000)
const C_RED*     = newColorRGB(0xFF0000)
const C_PURPLE*  = newColorRGB(0x800080)
const C_FUCHSIA* = newColorRGB(0xFF00FF)
const C_GREEN*   = newColorRGB(0x008000)
const C_LIME*    = newColorRGB(0x00FF00)
const C_OLIVE*   = newColorRGB(0x808000)
const C_YELLOW*  = newColorRGB(0x000080)
const C_NAVY*    = newColorRGB(0x0000FF)
const C_BLUE*    = newColorRGB(0x008080)
const C_TEAL*    = newColorRGB(0x000080)
const C_AQUA*    = newColorRGB(0x00FFFF)


proc glClear*(value: Color) =
  glClearColor(value.red, value.blue, value.green, value.alpha)
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)
