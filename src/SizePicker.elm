module SizePicker exposing
  ( Request(..)
  , mapRequest
  , askForSize
  )

{-| The interface to a size picking service. This service provides other
sub-components the ability to request that the user pick a size. The UI for
the size picking is handled by the service, and is not within the calling
sub-components view.

Clients of this code can think of it in the same way as a `port`: You make
a request by calling a function that returns a value which is returned
from its `update` function to the containing component. That request value
may contain a message function, so that a `Msg` is delivered to the client at
a later time.

Example:

    import Command
    import SizePicker
    
    type alias Model = Maybe Int

    type Msg =
      = Start
      | SetSize Int

    update : Msg -> Model -> (Model, Command Msg)
    update msg model =
      case msg of
        Start
          -> (Nothing, Command.SizePicker <| SizePicker.askForSize SetSize)

        SetSize size
          -> (Just Size, Command.none)

# Requests
@docs Request, askForSize

# Fancy Stuff
@docs mapRequest

---
# Narrative Path
Continue on with [`Sub1`](Sub1)...
-}


{-| Requests that the size picking service can accept.

Normally, a client uses a convience function, like `askForSize`, to build a
request, and the wraps the request to make it a `Command`:

    update : Msg -> Model -> (Model, Command Msg)
    update msg model =
      ...
      let
        model_ = ...
        command_ = Command.SizePicker <| askForSize "Pikachu" SetSize
      in
        (model_, command_)

Generally, clients are expected to use the request building functions (like
`askForSize`) rather than these constructors directly.

The constructors are exposed so that the implementation, `SizePicker.Service`
can pattern match on them. There is no real issue with lack of encapsulation
here because any information in these constructors has to have come from the
client anyway.
-}
type Request msg
  = RequestSize String (Int -> msg)


{-| Convert a `Request` based one message type to another. This is analogous
to `Cmd.map`. It lets parent components handle requests made by children
components.  However, parent components don't usualy call this directly, but
use `Command.map` (which calls this internally).
-}
mapRequest : (msg1 -> msg2) -> Request msg1 -> Request msg2
mapRequest mapFunc req =
  case req of
    RequestSize s msgFunc -> RequestSize s (msgFunc >> mapFunc)


{-| Create a request for the size picker service to ask the user for a size.
When the user has chosen a size, it will be passed to the supplied function
to create a message object, which will be routed to your `update` function.

The supplied string is used to identify the request to the user.
-}
askForSize : String -> (Int -> msg) -> Request msg
askForSize = RequestSize


