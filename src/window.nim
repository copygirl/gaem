import
  sdl2,
  times,
  
  config


# ========================================

const
  MaxFrameTimings = 200
var
  frameTiming: array[0..MaxFrameTimings-1, float]
  frameTimingIndex = 0
  frameTimingSize = 0
  lastFrameTime = 0.0

proc updateFrameTiming() =
  frameTimingIndex = (frameTimingIndex + 1) mod MaxFrameTimings
  frameTimingSize  = min(MaxFrameTimings, frameTimingSize + 1)
  
  let currentFrameTime = cpuTime()
  frameTiming[frameTimingIndex] = currentFrameTime - lastFrameTime
  lastFrameTime = currentFrameTime

## Yields the frame timings of the up to 200 last frames.
## That is, the time in seconds it took between each swapBuffers call.
iterator getFrameTimings*(): float =
  for i in 0..frameTimingSize-1:
    yield frameTiming[(frameTimingIndex - i + MaxFrameTimings) mod MaxFrameTimings]

## Gets the average FPS over the last up to X seconds (5 by default).
proc getFps*(maxSeconds = 5.0): float =
  var all = 0.0
  var count = 0
  for t in getFrameTimings(): 
    all += t
    inc count
    if all > maxSeconds: break
  result = count.toFloat() / all


# ========================================

type
  SdlException* = object of Exception
  WindowSize* = tuple[width: int, height: int]
  
  MouseButton* = enum
    mbLeft   = BUTTON_LEFT,
    mbMiddle = BUTTON_MIDDLE,
    mbRight  = BUTTON_RIGHT,
    mbX1     = BUTTON_X1,
    mbX2     = BUTTON_X2,
  
  WindowEventKind* = enum
    evQuit,
    evResize,
    evKeyDown,
    evKeyUp,
    evMouseMotion,
    evMouseDown,
    evMouseUp,
  WindowEvent* = object
    case kind*: WindowEventKind
      of evKeyDown, evKeyUp:
        keysym*: KeySym
      of evMouseMotion:
        mouseMotion*: Point
      of evMouseDown, evMouseUp:
        mouseButton*: MouseButton
        mousePosition*: Point
      else: discard

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
  window: WindowPtr
  windowSize: WindowSize
  mousePosition: Point
  mouseButtonDown: uint32
  context: GlContextPtr

## Initializes SDL2, creates and shows the window.
proc initWindow*(title: string, size: WindowSize) =
  if sdl2.init(INIT_VIDEO or INIT_AUDIO or INIT_EVENTS) != SdlSuccess:
    raise newException(SdlException, "Error during sdl2.init: " & $sdl2.getError())
  
  window = createWindow(
    title = title,
    x = SDL_WINDOWPOS_CENTERED,
    y = SDL_WINDOWPOS_CENTERED,
    w = int32(size.width),
    h = int32(size.height),
    flags = SDL_WINDOW_OPENGL or
            SDL_WINDOW_SHOWN or
            SDL_WINDOW_RESIZABLE
  )
  
  if isNil window:
    raise newException(SdlException, "Error during sdl2.createWindow: " & $sdl2.getError())
  
  var w, h: cint
  window.getSize(w, h)
  windowSize = (w.int, h.int)
  
  # OpenGL flags
  discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, GL_VERSION[0].int32)
  discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, GL_VERSION[1].int32)
  discard glSetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE)
  
  when not defined(release):
    discard glSetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG)
  
  discard glSetAttribute(SDL_GL_RED_SIZE, 5)
  discard glSetAttribute(SDL_GL_GREEN_SIZE, 5)
  discard glSetAttribute(SDL_GL_BLUE_SIZE, 5)
  discard glSetAttribute(SDL_GL_DEPTH_SIZE, 16)
  discard glSetAttribute(SDL_GL_DOUBLEBUFFER, 1)
  
  discard glSetSwapInterval(1)
  
  context = window.glCreateContext()
  lastFrameTime = cpuTime()

## Returns the size of the main game window.
proc getWindowSize*(): WindowSize = windowSize

## Returns the position of the mouse pointer in the window.
proc getMousePosition*(): Point = mousePosition
## Sets the position of the mouse pointer relative to the window.
proc setMousePosition*(p: Point) = warpMouseInWindow(window, p[0], p[0])

proc getRelativeMouseMode*(): bool = sdl2.getRelativeMouseMode().bool
proc setRelativeMouseMode*(enable: bool) = discard sdl2.setRelativeMouseMode(enable.Bool32)

proc isDown*(button: MouseButton): bool =
  (mouseButtonDown and (1'u32 shl button.int)) != 0

## Polls SDL2 for any events that might have occured, yielding those.
iterator pollEvents*(): WindowEvent =
  var event: Event = defaultEvent
  while pollEvent(event):
    case event.kind:
      of QuitEvent:
        yield WindowEvent(kind: evQuit)
      
      of KeyDown:
        yield WindowEvent(kind: evKeyDown, keysym: event.evKeyboard.keysym)
      of KeyUp:
        yield WindowEvent(kind: evKeyUp, keysym: event.evKeyboard.keysym)
      
      of MouseMotion:
        let ev = event.evMouseMotion
        let m  = (ev.xrel, ev.yrel).Point
        mousePosition = (ev.x, ev.y).Point
        yield WindowEvent(kind: evMouseMotion, mouseMotion: m)
      
      of MouseButtonDown:
        let ev = event.evMouseButton
        let mb = MouseButton(ev.button)
        let p  = (ev.x, ev.y).Point
        mouseButtonDown = mouseButtonDown or (1'u32 shl mb.int)
        yield WindowEvent(kind: evMouseDown, mouseButton: mb, mousePosition: p)
      of MouseButtonUp:
        let ev = event.evMouseButton
        let mb = MouseButton(ev.button)
        let p  = (ev.x, ev.y).Point
        mouseButtonDown = mouseButtonDown and not (1'u32 shl mb.int)
        yield WindowEvent(kind: evMouseUp, mouseButton: mb, mousePosition: p)
      
      of sdl2.WindowEvent:
        let ev = event.evWindow
        case ev.event:
          of WindowEvent_Resized:
            windowSize = (ev.data1.int, ev.data2.int)
            yield WindowEvent(kind: evResize)
          else: discard
      
      else: discard

## Swaps the OpenGL buffers.
proc swapBuffers*() =
  window.glSwapWindow()
  updateFrameTiming()

## Destroys the SDL window and OpenGL context.
proc destroyWindow*() =
  window.destroy()
  context.glDeleteContext()
  sdl2.quit()
