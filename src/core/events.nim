import macros

type
  ## Represents an event callback, fired when a certain event occurs.
  EventHandler*[T] = proc(event: T) {.nimcall.}
  
  ## Represents an event, which listeners can subscribe to.
  ## When the even fires, listeners will be notified in an unspecified order.
  Event*[T] = object
    handlers: seq[EventHandler[T]]


proc newEvent*[T](): Event[T] =
  result = Event[T](handlers: newSeq[EventHandler[T]]())


proc subscribe*[T](ev: var Event[T], handler: EventHandler[T]) =
  ev.handlers.add(handler)

proc subscribe*(ev: var Event[void], handler: proc() {.nimcall.}) =
  subscribe[void](ev, handler)


proc unsubscribe*[T](ev: var Event[T], handler: EventHandler[T]) =
  let i = ev.handlers.find(handler)
  ev.handlers.delete(i)

proc unsubscribe*(ev: var Event[void], handler: proc() {.nimcall.}) =
  unsubscribe[void](ev, handler)


proc fire*[T](ev: Event[T], event: T) =
  for handler in ev.handlers: handler(event)

proc fire*(ev: Event[void]) =
  for handler in ev.handlers: handler()
