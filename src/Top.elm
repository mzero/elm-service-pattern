module Top exposing
  ( Model
  , init

  , Msg(..)   -- normally not exposed, but we want it in the doc
  , update
  , view
  , subscriptions

  , ComponentBase
  , Component
  , Service
  
  , processCommand
  , processCommandAndMessages
  , updateComponent
  , updateService
  , requestService
  )

{-| This is the top component in the application. It contains four sub-
components: two are services and and two are normal sub-components.

Weaving together subcomponents is a well established pattern in Elm. The
core of this whole project is the logic here that weaves together services
as well. They are more complicating because updates to sub-components may
result in service requests, which must then be threaded through. And service
operations may result in messages that need to get processed back to the
sub-components.

While this doc will walk though some of this, you are highly encouraged
to read the source code.

# Types
@docs Model, init, Msg

# Functions
@docs update, view, subscriptions

# Component Descriptors

These types and values make working with multiple components easy. While the
types here are highly parameterized and a littly dizzing to read, they will
make the `update` function be almost trivial. Using these techniques, you
can easily incorporate dozens of sub-components and services in a top level
component.

An example descriptor is:

    sub1 : Component Sub1.Model Sub1.Msg 
    sub1 =
      { msgFn = Sub1Msg
      , getModel = .sub1
      , setModel = \s m -> { m | sub1 = s }
      , update = Sub1.update
      }

See the source code for others.
@docs ComponentBase, Component, Service

# Processing Functions

These internal functions do the bulk of the work in calling a sub-component
and processing te returned values. This mostly a nest of unwrapping and re-
wrapping.

See the source code to see how they work.

@docs processCommand, processCommandAndMessages, updateComponent, updateService, requestService

---
# Narrative Path
Now go [browse the source](https://github.com/mzero/elm-service-pattern)...
-}
import Html
import Html.Attributes as Attr

import Command
import ColorPicker
import ColorPicker.Service as ColorPicker
import SizePicker
import SizePicker.Service as SizePicker
import Sub1
import Sub2


-- TYPES

{-| Standard model type with fields for the sub-component models. Notice that
for services, their model type is parameterized by this top level's `Msg` type.
-}
type alias Model =
  { colorPicker : ColorPicker.Model Msg
  , sizePicker : SizePicker.Model Msg
  , sub1 : Sub1.Model
  , sub2 : Sub2.Model
  }

{-|-}
init : Model
init =
  { colorPicker = ColorPicker.init
  , sizePicker = SizePicker.init
  , sub1 = Sub1.init
  , sub2 = Sub2.init
  }


{-| Standard message type for something with sub-components. There is a
constructor for each sub-component's msg type.

(Those are different `Msg` types - click on them and see. This might be easier
to read in the source code.)
-}
type Msg
  = NoOp
  | ColorPickerMsg ColorPicker.Msg
  | SizePickerMsg SizePicker.Msg
  | Sub1Msg Sub1.Msg
  | Sub2Msg Sub2.Msg


-- COMPONENT DESCRIPTORS

{-| A `ComponentBase` value describes a sub-component. It has the function for
mapping the sub-component's message type into `Msg`, and functions for getting
and setting the sub-component's model in `Model`.
-}
type alias ComponentBase model msg a =
  { a
  | msgFn : msg -> Msg
  , getModel : Model -> model
  , setModel : model -> Model -> Model
  }


{-| A regular component has a simple `update` function.
-}
type alias Component model msg =
  ComponentBase model msg
    { update : msg -> model -> (model, Command.Command msg)
    }


{-| A service has an update and a request function, and both may return
additional `Msg` values to be processed.
-}
type alias Service model msg req =
  ComponentBase model msg
    { update : msg -> model -> (model, Command.Command msg, List Msg)
    , request : req -> model -> (model, Command.Command msg, List Msg)
    }


sub1 : Component Sub1.Model Sub1.Msg 
sub1 =
  { msgFn = Sub1Msg
  , getModel = .sub1
  , setModel = \s m -> { m | sub1 = s }
  , update = Sub1.update
  }

sub2 : Component Sub2.Model Sub2.Msg 
sub2 =
  { msgFn = Sub2Msg
  , getModel = .sub2
  , setModel = \s m -> { m | sub2 = s }
  , update = Sub2.update
  }

colorPicker : Service (ColorPicker.Model Msg) ColorPicker.Msg (ColorPicker.Request Msg)
colorPicker =
  { msgFn = ColorPickerMsg
  , getModel = .colorPicker
  , setModel = \s m -> { m | colorPicker = s }
  , update = ColorPicker.update
  , request = ColorPicker.request
  }

sizePicker : Service (SizePicker.Model Msg) SizePicker.Msg (SizePicker.Request Msg)
sizePicker =
  { msgFn = SizePickerMsg
  , getModel = .sizePicker
  , setModel = \s m -> { m | sizePicker = s }
  , update = SizePicker.update
  , request = SizePicker.request
  }


accumulate : List b -> (a, b) -> (a, List b)
accumulate bs (a, b) = (a, b :: bs)


{-| `Command` values must be ultimately resolved into `Cmd` values so they can
be returned to the Elm framework. Where `Command` wraps a service request,
the service's `request` function will be called, and those results processed
recursively.
-}
processCommand : Model -> Command.Command Msg -> (Model, Cmd Msg)
processCommand model command0 =
  let
    step command (m, cs) =
      case command of
        Command.NoCommand -> (m, cs)
        Command.Cmd c -> (m, c :: cs)
        Command.ColorPicker r -> requestService colorPicker r m |> accumulate cs
        Command.SizePicker r -> requestService sizePicker r m |> accumulate cs
        Command.Batch commands -> List.foldl step (m, cs) commands
  in
    step command0 (model, []) |> Tuple.mapSecond Cmd.batch


{-| This is very simiilar to `processCommand`, but is used for services which
return an additional `List Msg` to be processed. These are messages to be sent
back to sub-components. This function handles them by calling this module's
own `update` on them.
-}
processCommandAndMessages : Model -> Command.Command Msg -> List Msg -> (Model, Cmd Msg)
processCommandAndMessages model cmd msgs =
  let
    (model_, cmd0) = processCommand model cmd
    step msg (m, cs) = update msg m |> accumulate cs
  in
    List.foldl step (model_, [cmd0]) msgs |> Tuple.mapSecond Cmd.batch


{-| Helper function for performing a component update. This involves getting
the components model from `Model`, calling its `update` function, and
handling the results.
-}
updateComponent : Component model msg -> msg -> Model -> (Model, Cmd Msg)
updateComponent comp msg model =
  let
    (compModel_, command) = comp.update msg (comp.getModel model)
    model_ = comp.setModel compModel_ model
    command_ = Command.map comp.msgFn command
  in
    processCommand model_ command_

{-| Like `updateComponent` but for services.
-}
updateService : Service model msg req -> msg -> Model -> (Model, Cmd Msg)
updateService svc msg model =
  let
    (svcModel_, command, newMsgs) = svc.update msg (svc.getModel model)
    model_ = svc.setModel svcModel_ model
    command_ = Command.map svc.msgFn command
  in
    processCommandAndMessages model_ command_ newMsgs

{-| Helper function for handling a request on a service. The logic is
identical to `updateService`, but usese the services `request` function
instead.
-}
requestService : Service model msg req -> req -> Model -> (Model, Cmd Msg)
requestService svc req model =
  let
    (svcModel_, command, newMsgs) = svc.request req (svc.getModel model)
    model_ = svc.setModel svcModel_ model
    command_ = Command.map svc.msgFn command
  in
    processCommandAndMessages model_ command_ newMsgs



{-| Given the complexity of services, you'd think this would have a hairy
implementation. But you'd be wrong! Given the component descriptors and
processing helper functions, handling a component or service is a one liner:

    case msg of
      ...
      SizePickerMsg spMsg -> updateService sizePicker spMsg model
      ...

-}
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp -> (model, Cmd.none)

    ColorPickerMsg cpMsg -> updateService colorPicker cpMsg model
    SizePickerMsg spMsg -> updateService sizePicker spMsg model

    Sub1Msg sub1msg -> updateComponent sub1 sub1msg model
    Sub2Msg sub2msg -> updateComponent sub2 sub2msg model


{-|-}
view : Model -> Html.Html Msg
view model =
  Html.div []
    [ Html.h1 [] [ Html.text "Service Example" ]
    , Html.div [ Attr.class "row" ]
      [ Html.div [ Attr.class "col clients" ]
        [ Html.div [ Attr.class "module client" ]
          [ Html.h2 [] [ Html.text "Sub1" ]
          , Html.map Sub1Msg <| Sub1.view model.sub1
          ]
        , Html.div [ Attr.class "module client" ]
          [ Html.h2 [] [ Html.text "Sub2" ]
          , Html.map Sub2Msg <| Sub2.view model.sub2
          ]
        ]
      , Html.div [ Attr.class "col services" ]
        [ Html.div [ Attr.class "module service" ]
          [ Html.h2 [] [ Html.text "Color Picker" ]
          , Html.map ColorPickerMsg <| ColorPicker.view model.colorPicker
          ]
        , Html.div [ Attr.class "module service" ]
          [ Html.h2 [] [ Html.text "Size Picker" ]
          , Html.map SizePickerMsg <| SizePicker.view model.sizePicker
          ]
        ]
      ]
    ]


{-|-}
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Sub.map ColorPickerMsg (ColorPicker.subscriptions model.colorPicker)
    , Sub.map SizePickerMsg (SizePicker.subscriptions model.sizePicker)
    , Sub.map Sub1Msg (Sub1.subscriptions model.sub1)
    , Sub.map Sub2Msg (Sub2.subscriptions model.sub2)
    ]

