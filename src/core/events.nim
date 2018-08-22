import macros

type
  EventHandler*[T] = proc(event: T)
  Event*[T] = seq[EventHandler[T]]

proc newEvent*[T](): Event[T] =
  result = newSeq[EventHandler[T]]()

proc subscribe*[T](ev: Event[T], handler: EventHandler[T]) =
  ev.add(handler)

proc unsubscribe*[T](ev: Event[T], handler: EventHandler[T]) =
  ev.del(handler)

proc fire*[T](ev: Event[T], event: T) =
  for handler in ev: handler(event)
