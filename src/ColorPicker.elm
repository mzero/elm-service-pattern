module ColorPicker exposing
  ( Request(..)
  , mapRequest
  , askForColor
  )

{-| The interface to a color picking service.  This service provides other
sub-compnents the ability to request that the user pick a color.

Colors are represented as CSS color value strings. I.E.: `#f7d87e`.

See the very similar `SizePicker` service for a more detailed discussion of
  how this is structured.

# Requests
@docs Request, askForColor

# Fancy Stuff
@docs mapRequest

-}


{-|-}
type Request msg
  = RequestColor String (String -> msg)


{-|-}
mapRequest : (msg1 -> msg2) -> Request msg1 -> Request msg2
mapRequest mapFunc req =
  case req of
    RequestColor s msgFunc -> RequestColor s (msgFunc >> mapFunc)


{-| Create a reqeust for the color picker service to ask the user for a color.
When the user has chosen a color, it will be used with the supplied function
to create a message object, which will be routed to your `update` function.

The supplied string is used to identify the request to the user.
-}
askForColor : String -> (String -> msg) -> Request msg
askForColor = RequestColor


