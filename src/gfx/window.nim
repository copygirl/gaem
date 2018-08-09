import
  sdl2,
  times,
  
  ../config


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

var
  window: WindowPtr
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
    flags = SDL_WINDOW_SHOWN or SDL_WINDOW_OPENGL
  )
  
  if isNil window:
    raise newException(SdlException, "Error during sdl2.createWindow: " & $sdl2.getError())
  
  # OpenGL flags
  discard glSetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, int32(GL_VERSION[0]))
  discard glSetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, int32(GL_VERSION[1]))
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

# TODO: Handle pollEvent more nicely.
export
  Event,
  EventType
iterator pollEvents*(): Event =
  var event: Event = defaultEvent
  while pollEvent(event):
    yield event

## Swaps the OpenGL buffers.
proc swapBuffers*() =
  window.glSwapWindow()
  updateFrameTiming()

## Destroys the SDL window and OpenGL context.
proc destroyWindow*() =
  window.destroy()
  context.glDeleteContext()
  sdl2.quit()
