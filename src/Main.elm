module Main exposing
  ( main
  )

import Browser

import Top


main : Program () Top.Model Top.Msg
main =
  Browser.element
    { init = always (Top.init, Cmd.none)
    , view = Top.view
    , update = Top.update
    , subscriptions = Top.subscriptions
    }
  