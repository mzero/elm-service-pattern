module Sub1 exposing
  ( Model
  , init

  , Msg(..) -- normall wouldn't be exposed, but we want them in the doc
  , update
  , view
  , subscriptions
  )

{-| A simple sub-component that draws a box. It uses the `SizePicker` and
`ColorPicker` services to let the user pick the size and color of the box.

For simplicity of the example, colors here are just strings with CSS color
values.

# Component Types
@docs Model, init, Msg

# Component Functions
@docs update, view, subscriptions

---
# Narrative Path
Continue on with [`Command`](Command)...
-}

import Html
import Html.Attributes as Attr
import Html.Events as Events

import Command
import ColorPicker
import SizePicker


{-|-}
type Model = Model
  { size : Maybe Int
  , color : Maybe String
  }


{-|-}
init : Model
init = Model { size = Just 10, color = Just "#f00" }


{-| The `Pick` constructors are messages from the `onClick` handlers in the
view to indicate the user has clicked the button to pick a value.

The `Set` constructors are messages from the picker services saying that the
value has been picked.
-}
type Msg
  = PickSize
  | PickColor
  | SetSize Int
  | SetColor String


{-| A standard sub-component `update` function, but notice that in the return
value it has `Command Msg` rather than `Cmd Msg`. `Command` is a super set of
both the standard `Cmd` values, as well as the requests that other services in
the app offer. As a consequence, requests must be wrapped in the correct 
`Command` constructor:

    Command.SizePicker <| SizePicker.askForSize "Pikachu" SetSize

or

    Command.Cmd <| somePortThing 

(You might think that `askForSize` could have done this wrapping, but it can't
because it would lead to a circular import between `Command` and `SizePicker`!)
-}
update : Msg -> Model -> (Model, Command.Command Msg)
update msg (Model m) =
  case msg of
    PickSize ->
      ( Model { m | size = Nothing }
      , Command.SizePicker <| SizePicker.askForSize "Sub1" SetSize
      )

    PickColor ->
      ( Model { m | color = Nothing }
      , Command.ColorPicker <| ColorPicker.askForColor "Sub1" SetColor
      )

    SetSize size ->
      ( Model { m | size = Just size }, Command.none )

    SetColor color ->
      ( Model { m | color = Just color }, Command.none )


{-|-}
view : Model -> Html.Html Msg
view (Model m) =
  Html.div [ Attr.class "row" ]
    [ Html.div [ Attr.class "col" ]
      [ case m.size of
          Nothing -> Html.p [] [ Html.text "waiting for a size..." ]
          Just size ->
            Html.p []
              [ Html.text "Size: "
              , Html.b [] [ Html.text <| String.fromInt size ]
              , Html.text " "
              , Html.button [ Events.onClick PickSize ] [ Html.text "Pick" ]
              ]
      , case m.color of
          Nothing -> Html.p [] [ Html.text "waiting for a color..." ]
          Just color ->
            Html.p []
              [ Html.text "Size: "
              , Html.b [] [ Html.text color ]
              , Html.text " "
              , Html.button [ Events.onClick PickColor ] [ Html.text "Pick" ]
              ]
      ]
    , Html.div [ Attr.class "col" ]
      [ case (m.size, m.color) of
          (Just size, Just color) ->
            Html.div
              [ Attr.class "box"
              , Attr.style "background-color" color
              , Attr.style "width" (String.fromInt size ++ "px")
              , Attr.style "height" (String.fromInt size ++ "px")
              ]
              [ ]
          _ -> Html.div [] []
      ]
    ]


{-|-}
subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none
