module Sub2 exposing
  ( Model
  , init

  , Msg
  , update
  , view
  , subscriptions
  )

{-| A simple sub-component that draws a box. It uses the `SizePicker` 
service twice to let the user pick the width and height of thebox.

See `Sub1` for details and commentary. This is implemented in exactly the 
same way. 

# Component Types
@docs Model, init, Msg

# Component Functions
@docs update, view, subscriptions
-}

import Html
import Html.Attributes as Attr
import Html.Events as Events

import Command
import SizePicker


{-|-}
type Model = Model
  { width : Maybe Int
  , height : Maybe Int
  }


{-|-}
init : Model
init = Model { width = Just 10, height = Just 10 }


{-|-}
type Msg
  = SetWidth Int
  | SetHeight Int
  | PickWidth
  | PickHeight


{-|-}
update : Msg -> Model -> (Model, Command.Command Msg)
update msg (Model m) =
  case msg of
    SetWidth w ->
      ( Model { m | width = Just w }, Command.none )

    SetHeight h ->
      ( Model { m | height = Just h }, Command.none )

    PickWidth ->
      ( Model { m | width = Nothing }
      , Command.SizePicker (SizePicker.askForSize "Sub2 width" SetWidth)
      )

    PickHeight ->
      ( Model { m | height = Nothing }
      , Command.SizePicker (SizePicker.askForSize "Sub2 height" SetHeight)
      )


{-|-}
view : Model -> Html.Html Msg
view (Model m) =
  Html.div [ Attr.class "row" ]
    [ Html.div [ Attr.class "col" ]
      [ case m.width of
          Nothing -> Html.p [] [ Html.text "waiting for a width..." ]
          Just width ->
            Html.p []
              [ Html.text "Width: "
              , Html.b [] [ Html.text <| String.fromInt width ]
              , Html.text " "
              , Html.button [ Events.onClick PickWidth ] [ Html.text "Pick" ]
              ]
      , case m.height of
          Nothing -> Html.p [] [ Html.text "waiting for a height..." ]
          Just height ->
            Html.p []
              [ Html.text "Height: "
              , Html.b [] [ Html.text <| String.fromInt height ]
              , Html.text " "
              , Html.button [ Events.onClick PickHeight ] [ Html.text "Pick" ]
              ]
      , case Maybe.map2 (*) m.width m.height of
          Nothing -> Html.p [] [ Html.text "area unknown" ]
          Just area ->
            Html.p []
              [ Html.text "Area: "
              , Html.b [] [ Html.text <| String.fromInt area ]
              ]
      ]
    , Html.div [ Attr.class "col" ]
      [ case (m.width, m.height) of
          (Just width, Just height) ->
            Html.div
              [ Attr.class "box"
              , Attr.style "width" (String.fromInt width ++ "px")
              , Attr.style "height" (String.fromInt height ++ "px")
              ]
              [ ]
          _ -> Html.div [] []
      ]
    ]

{-|-}
subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none
