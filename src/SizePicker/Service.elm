module SizePicker.Service exposing
  ( Id
  , Model(..)   -- normally wouldn't be exposed, but we want it in the doc
  , init

  , Msg

  , update
  , request
  , view
  , subscriptions
  )

{-| The implementation of the size picker service.

For the most part, this is structured like any other sub-component, with 
`Model` and `Msg` types, and `update`, `view`, and `subscriptions` functions.

The only differences are:
  1. The `Model` type is parametric on the _top component's `Msg` type_
  2. The addition of a `request` function.
  3. The return tuple of `request` and `update` has an additional value

# Types
@docs Id, Model, init, Msg

# Functions
@docs update, request, view, subscriptions

---
# Narrative Path
Continue on with [`Top`](Top)...
-}


import Dict exposing (Dict)
import Html
import Html.Events

import Command

import SizePicker exposing (..)
  -- this is the public interface to this service, and so exposing (..) is okay


{-| Internal ids are used to tag the requests in progress.
-}
type alias Id = Int


{-| The model of the service must be parametric on the message type of the
component that contains it. This is usually the top component in the
application.

The reason for this can be seen in the dictionary of pending requests: The
request includes a function that maps the response (the picked size) to a
message to be re-injected into the program, via the top component's `update`
function.
-}
type Model top = Model
  { nextId : Id
  , pending : Dict Id (String, Int -> top)
  }


{-|-}
init : Model top
init = Model { nextId = 0, pending = Dict.empty }


{-| The message type of this service, as a sub-component.
-}
type Msg
  = Pick Id Int


{-| This like a standard sub-component update function with an addition:
The returned tuple has a third value, `List top`, that is a list of top-level
messages that should be operated on after this update. These are the messages
back to requesting sub-components.
-}
update : Msg -> Model top -> (Model top, Command.Command Msg, List top)
update msg (Model m) =
  case msg of
    Pick id size ->
      case Dict.get id m.pending of
        Just (_, respFn) ->
          let
            model_ = Model { m | pending = Dict.remove id m.pending }
            resp = respFn size
          in
            ( model_, Command.none, [resp] )
        Nothing ->
          ( Model m, Command.none, [] )

{-| This is almost identical in every way to `update`, only it handles a
`Request`, not a `Msg`. Upon progressing the request, the model may have
changed, new `Command`s issues, and even other response messages returned.

Notice that `Request` here is parameterized by `top`. This is because by the
time a `Request` from a child component had bubbled up to the top component
for dispatch to this function, it has been mapped (`Command.map`) to the
top component's message type.
-}
request : Request top -> Model top -> (Model top, Command.Command Msg, List top)
request req (Model m) =
  case req of
    RequestSize name respFn ->
      let
        id = m.nextId
        pending = Dict.insert id (name, respFn) m.pending
        model = Model { m | nextId = id + 1, pending = pending }
      in
        ( model, Command.none, [])



{-|-}
view : Model top -> Html.Html Msg
view (Model m) =
  if Dict.isEmpty m.pending
    then
      Html.p [ ] [ Html.text "No pending size requests" ]
    else
      Html.ul [ ]
      <| List.map (\(id, (name, _)) -> 
          Html.li [ ]
            [ Html.b [ ] [ Html.text name ]
            , Html.text " would like a size: "
            , Html.button [ Html.Events.onClick (Pick id 10) ] [ Html.text "S" ]
            , Html.button [ Html.Events.onClick (Pick id 30) ] [ Html.text "M" ]
            , Html.button [ Html.Events.onClick (Pick id 50) ] [ Html.text "L" ]
            ]
          )
      <| Dict.toList m.pending


{-|-}
subscriptions : Model top -> Sub Msg
subscriptions _ = Sub.none
