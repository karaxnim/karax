port module Picker exposing (main)

import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import Html.Events exposing (..)



main =
  App.programWithFlags
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL


type alias Model =
  { running : Bool
  , entries : List Entry
  }


type alias Entry =
  { selected : Bool
  , id : Int
  , impl : Impl
  }


type alias Impl =
  { name : String
  , version : String
  , url : String
  , optimized : Bool
  }


init : List Impl -> ( Model, Cmd msg )
init impls =
  { running = False
  , entries = List.indexedMap (Entry False) impls
  }
    ! []



-- UPDATE


type Msg
  = Toggle Int
  | Start
  | End


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
  case msg of
    Toggle id ->
      { model | entries = toggle id model.entries }
        ! []

    Start ->
      { model | running = True }
        ! [ startSelected model.entries ]

    End ->
      { model | running = False }
        ! []


toggle : Int -> List Entry -> List Entry
toggle id entries =
  case entries of
    [] ->
      []

    entry :: rest ->
      if entry.id == id then
        { entry | selected = not entry.selected } :: rest

      else
        entry :: toggle id rest


port start : List Impl -> Cmd msg


startSelected : List Entry -> Cmd msg
startSelected entries =
  start (List.map .impl (List.filter .selected entries))



-- SUBSCRIPTIONS


port end : (() -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  end (always End)



-- VIEW


view : Model -> Html Msg
view { running, entries } =
  div []
    [ ul
        (if running then [ style [("color", "#aaa")] ] else [])
        (List.map (viewEntry running) entries)
    , button
        [ style [("width","100%")]
        , disabled running
        , onClick Start
        ]
        [ text "Run" ]
    ]


viewEntry : Bool -> Entry -> Html Msg
viewEntry running { id, selected, impl } =
  li
    (if running then [ pointer ] else [ pointer, onClick (Toggle id) ])
    [ input [ type' "checkbox", checked selected, disabled running ] []
    , text (" " ++ impl.name ++ " " ++ impl.version)
    , span
        [ style [("color","#aaa")]
        ]
        [ text (if impl.optimized then " (optimized)" else "")
        ]
    ]


pointer : Attribute msg
pointer =
  style [ ("cursor", "pointer") ]