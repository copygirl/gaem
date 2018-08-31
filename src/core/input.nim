import
  sdl2,
  ./event

type
  MouseButton* = enum
    mbLeft   = BUTTON_LEFT,
    mbMiddle = BUTTON_MIDDLE,
    mbRight  = BUTTON_RIGHT,
    mbX1     = BUTTON_X1,
    mbX2     = BUTTON_X2,
  
  MouseMotionEventArgs* = object
    motion*: Point
  MouseButtonEventArgs* = object
    button*:   MouseButton
    position*: Point

export
  Point,
  KeySym,
  Scancode,
  Keymod,
  KMOD_CTRL,
  KMOD_SHIFT,
  KMOD_ALT,
  KMOD_GUI

var
  KeyDownEvent* = newEvent[KeySym]()
  KeyUpEvent*   = newEvent[KeySym]()
  MouseMotionEvent* = newEvent[MouseMotionEventArgs]()
  MouseDownEvent*   = newEvent[MouseButtonEventArgs]()
  MouseUpEvent*     = newEvent[MouseButtonEventArgs]()

var
  mousePosition: Point
  mouseButtonDown: uint32

proc isDown*(button: MouseButton): bool =
  ## Returns whether the specified mouse button is currently held down.
  (mouseButtonDown and (1'u32 shl button.int)) != 0

proc handleInputEvent*(event: sdl2.Event) =
  case event.kind:
    of KeyDown: KeyDownEvent.fire event.evKeyboard.keysym
    of KeyUp:   KeyUpEvent.fire event.evKeyboard.keysym
    
    of MouseMotion:
      let ev = event.evMouseMotion
      let m  = (ev.xrel, ev.yrel).Point
      mousePosition = (ev.x, ev.y)
      MouseMotionEvent.fire MouseMotionEventArgs(motion: m)
    
    of MouseButtonDown, MouseButtonUp:
      let ev = event.evMouseButton
      let mb = MouseButton(ev.button)
      let p  = (ev.x, ev.y).Point
      if event.kind == MouseButtonDown:
        mouseButtonDown = mouseButtonDown or (1'u32 shl ev.button)
        MouseDownEvent.fire MouseButtonEventArgs(button: mb, position: p)
      else:
        mouseButtonDown = mouseButtonDown and not (1'u32 shl ev.button)
        MouseUpEvent.fire MouseButtonEventArgs(button: mb, position: p)
    
    else: discard

proc getRelativeMouseMode*(): bool =
  sdl2.getRelativeMouseMode()

proc setRelativeMouseMode*(enable: bool) =
  discard sdl2.setRelativeMouseMode(enable.Bool32)
