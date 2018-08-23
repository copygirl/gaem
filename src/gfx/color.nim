type
  Color* = object
    red*: float32
    green*: float32
    blue*: float32
    alpha*: float32


proc newColor*(red, green, blue: float32, alpha = 1.0): Color =
  Color(red: red, green: green, blue: blue, alpha: alpha)

proc newColor*(red, green, blue: int, alpha = 255): Color =
  newColor(red.float / 255, green.float / 255, blue.float / 255, alpha.float / 255)

proc newColorARGB*(value: int): Color =
  newColor(value shr 16 and 0xFF, value shr 8 and 0xFF, value and 0xFF, value shr 24 and 0xFF)

proc newColorRGB*(value: int): Color =
  newColor(value shr 16 and 0xFF, value shr 8 and 0xFF, value and 0xFF)


proc toARGB*(value: Color): int =
  (value.alpha.int * 255).clamp(0, 255) shl 24 or
    (value.red.int * 255).clamp(0, 255) shl 16 or
    (value.green.int * 255).clamp(0, 255) shl 8 or
    (value.blue.int * 255).clamp(0, 255)

proc toRGB*(value: Color): int =
  (value.red.int * 255).clamp(0, 255) shl 16 or
    (value.green.int * 255).clamp(0, 255) shl 8 or
    (value.blue.int * 255).clamp(0, 255)


const C_WHITE*   = newColorRGB(0xFFFFFF)
const C_GRAY*    = newColorRGB(0x808080)
const C_SILVER*  = newColorRGB(0xC0C0C0)
const C_BLACK*   = newColorRGB(0x000000)

const C_RED*     = newColorRGB(0xFF0000)
const C_MAROON*  = newColorRGB(0x800000)
const C_YELLOW*  = newColorRGB(0xFFFF00)
const C_OLIVE*   = newColorRGB(0x808000)
const C_LIME*    = newColorRGB(0x00FF00)
const C_GREEN*   = newColorRGB(0x008000)
const C_AQUA*    = newColorRGB(0x00FFFF)
const C_TEAL*    = newColorRGB(0x008080)
const C_BLUE*    = newColorRGB(0x0000FF)
const C_NAVY*    = newColorRGB(0x000080)
const C_FUCHSIA* = newColorRGB(0xFF00FF)
const C_PURPLE*  = newColorRGB(0x800080)
