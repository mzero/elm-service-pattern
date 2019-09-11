module Command exposing
  ( Command(..)
  , none

  , batch
  , map
  )

{-| A meta-command type that encapsulates all the command-like things a
component might make.

`Command` is completely analagous to `Cmd`, only in addition to including
`Cmd` values, it can include requests to service components that are in the
application.

Like `Cmd`, `Command` is parametric in the type of messages that it's requests
might generate as responses. See `map`.

# Commands
@docs Command, none, batch

# Fancy Stuff
@docs map

---
# Narrative Path
Continue on with [`SizePicker.Service`](SizePicker-Service)...
-}


import ColorPicker
import SizePicker

{-| The command type. There are constructors for all the types of commands in
the whole application.
-}
type Command msg
  = NoCommand
  | Cmd (Cmd msg)
  | ColorPicker (ColorPicker.Request msg)
  | SizePicker (SizePicker.Request msg)
  | Batch (List (Command msg))


{-| No command to be done.
-}
none : Command msg
none = NoCommand


{-| Convert a list of commands into a single command
-}
batch : List (Command msg) -> Command msg
batch = Batch


{-| Maps `Commands` from one message type to another. Usually used so that
`Commands` generated in sub-components (which use the sub-component's
`msg` type) can be handled in the parent component.

    type alias ParentModel = { ... childModel : Child.Model, ... }
    type ParentMsg = ... | ChildMsg Child.Msg | ...
    
    update : ParentMsg -> ParentModel -> (ParentModel, Command ParentMsg)
    update msg model =
      case msg of
        ...
        ChildMsg childMsg ->
          let
            (childModel, childCommand) = Child.update childMsg model.childModel
          in
            ( { model | childModel = childModel }
            , Command.map ChildMsg childCommand
            )
-}
map : (msg1 -> msg2) -> Command msg1 -> Command msg2
map msgFn command =
  case command of
    NoCommand -> NoCommand
    Cmd cmd -> Cmd (Cmd.map msgFn cmd)
    ColorPicker svc1 -> ColorPicker (ColorPicker.mapRequest msgFn svc1)
    SizePicker svc2 -> SizePicker (SizePicker.mapRequest msgFn svc2)
    Batch commands -> Batch (List.map (map msgFn) commands)
