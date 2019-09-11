module ColorPicker.Service exposing
  ( Id
  , Model
  , init

  , Msg
  , update
  , request
  , view
  , subscriptions
  )

{-| The implementation of the color picker service.

See `SizePicker.Service` for commentary and details, since this service is
implemented in exactly the same way.

# Types
@docs Id, Model, init, Msg

# Functions
@docs update, request, view, subscriptions
-}

import Dict exposing (Dict)
import Html
import Html.Events as Events

import Command

import ColorPicker exposing (..)


{-|-}
type alias Id = Int


{-|-}
type Model top = Model
  { nextId : Id
  , pending : Dict Id (String, String -> top)
  }


{-|-}
init : Model top
init = Model { nextId = 0, pending = Dict.empty }


{-|-}
type Msg
  = Pick Id String


{-|-}
update : Msg -> Model top -> (Model top, Command.Command Msg, List top)
update msg (Model m) =
  case msg of
    Pick id color ->
      case Dict.get id m.pending of
        Just (_, respFn) ->
          let
            model_ = Model { m | pending = Dict.remove id m.pending }
            resp = respFn color
          in
            ( model_, Command.none, [resp] )
        Nothing ->
          ( Model m, Command.none, [] )


{-|-}
request : Request top -> Model top -> (Model top, Command.Command Msg, List top)
request req (Model m) =
  case req of
    RequestColor name respFn ->
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
      Html.p [ ] [ Html.text "No pending color requests" ]
    else
      Html.ul [ ]
      <| List.map (\(id, (name, _)) -> 
          Html.li [ ]
            [ Html.b [ ] [ Html.text name ]
            , Html.text " would like a color: "
            , Html.button [ Events.onClick (Pick id "#f00") ] [ Html.text "R" ]
            , Html.button [ Events.onClick (Pick id "#0f0") ] [ Html.text "G" ]
            , Html.button [ Events.onClick (Pick id "#00f") ] [ Html.text "B" ]
            ]
          )
      <| Dict.toList m.pending


{-|-}
subscriptions : Model top -> Sub Msg
subscriptions _ = Sub.none
