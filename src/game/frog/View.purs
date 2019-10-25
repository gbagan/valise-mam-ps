module Game.Frog.View where

import Prelude
import Math (cos, sin, pi, sqrt)
import Data.Array ((!!), concat, mapWithIndex, reverse)
import Data.Maybe (maybe, fromMaybe)
import Data.Tuple (Tuple(..))
import Data.String (joinWith)
import Data.Int (toNumber)
import Optic.Core (Lens', (^.))
import Lib.Core (tabulate, pairwise, floatRange)
import Pha (VDom, text, lensAction)
import Pha.Html (div', span, br, svg, viewBox, g, use, line, path, text',
                class', key, click, style,
                width, height, stroke, fill, strokeDasharray, strokeWidth, translate)
import UI.Template (template, incDecGrid)
import UI.Dialog (card)
import UI.Icon (icongroup)
import UI.Icons (iconSelectGroupM, icons2Players, iundo, iredo, ireset, irules)
import Lib.Game (Mode(..), (🎲), _nbRows, _position, _turn, _mode, _play')
import Game.Frog.Model (FrogState, _moves, selectMove, reachableArray)

type Cartesian = { x :: Number, y :: Number}
type Polar = { radius :: Number, theta :: Number }

lineIntersection :: Number -> Number -> Number -> Number -> { x :: Number, y :: Number }
lineIntersection  m1 b1 m2 b2 = { x, y: m1 * x + b1 } where x = (b2 - b1) / (m1 - m2)

polarToCartesian :: Polar -> Cartesian
polarToCartesian {radius, theta} = { x: radius * cos theta, y: radius * sin theta }

spiral :: Cartesian -> Number -> Number -> Number -> Number -> Number -> String
spiral center startRadius radiusStep startTheta endTheta thetaStep =
    floatRange startTheta endTheta thetaStep <#> (\theta ->
        let b = radiusStep / (2.0 * pi)
            r = startRadius + b * theta
            point = { x: center.x + r * cos theta, y: center.y + r * sin theta }
            slope = (b * sin theta + r * cos theta) / (b * cos theta - r * sin theta)
            intercept = -(slope * r * cos theta - r * sin theta)
        in
            { point, slope, intercept }
    )
    # pairwise
    # mapWithIndex (\i (Tuple a b) ->
        let { x, y } = lineIntersection a.slope a.intercept b.slope b.intercept
            p = ["Q", show $ x + center.x, show $ y + center.y, show $ b.point.x, show b.point.y]
        in
            if i == 0 then ["M", show a.point.x, show a.point.y] <> p else p
    )
    # concat
    # joinWith " "

spiralPointsPolar :: Int -> Array Polar
spiralPointsPolar n = reverse $ tabulate (n + 1) \i ->
    let theta = sqrt(if i == n then 21.0 else toNumber i * 20.0 / toNumber n) * 1.36 * pi
        radius = 61.0 * theta / (2.0 * pi)
    in
        { theta, radius }


spiralPoints :: Int -> Array Cartesian
spiralPoints n = spiralPointsPolar n <#> polarToCartesian

spiralPath :: String
spiralPath = spiral { x: 0.0, y: 0.0 } 0.0 61.0 0.0 (37.0 / 6.0 * pi) (pi / 6.0)

-- shift = (_, e) => e.shiftKey;
lily :: forall a. Int -> Number -> Number -> Boolean -> Boolean -> VDom a
lily i x y reachable hidden =
    (if i == 0 then
        use (x - 30.0) (y - 45.0) 80.0 80.0 
    else
        use (x - 24.0) (y - 24.0) 48.0 48.0
    ) "#lily" [
        class' "frog-lily" true,
        class' "reachable" reachable,
        class' "hidden" hidden
    ]

view :: forall a. Lens' a FrogState -> FrogState -> VDom a
view lens state = template lens {config, board, rules} state where
    position = state^._position
    reachable = reachableArray state
    pointsPolar = spiralPointsPolar $ state^._nbRows
    config = card "La grenouille" [
        iconSelectGroupM lens state "Déplacements autorisés" [1, 2, 3, 4, 5] (state^._moves) selectMove,
        icons2Players lens state,
        icongroup "Options" $ [iundo, iredo, ireset, irules] <#> \x -> x lens state -- help
    ]
    grid = 
        div' [class' "ui-board frog-board" true] [
            svg [viewBox "-190 -200 400 400", height "100%", width "100%"] $
                [
                    path spiralPath [fill "none", stroke "black", strokeWidth "3"],
                    line 153.0 9.0 207.0 20.0 [stroke "black", strokeDasharray "5", strokeWidth "6"],
                    line 153.0 7.0 153.0 39.0 [stroke "black", strokeWidth "3"],
                    line 207.0 18.0 207.0 50.0 [stroke "black", strokeWidth "3"]
                ] <> (spiralPoints (state^._nbRows) # mapWithIndex \i {x, y} ->
                    g [
                        key $ "lily" <> show i,
                        click $ lensAction lens $ _play' i   -- actions.when(shift, [actions.mark, i], [actions.play, i])
                    ] [
                        lily i x y false false,
                        lily i x y true (maybe true not $ reachable !! i), --  || state.hideReachable),
                        text' x y (if true {- state^._help -} then show $ (state^._nbRows) - i else "") [class' "frog-index" true]
                    ]
                )
                {- <> state.marked.map((b, i) => b && i !== state.position &&
                use({
                    key: 'reach' + i,
                    href: '#frog',
                    class: 'frog-frog marked',
                                            x: spiralPoints[i].x - 16,
                    y: spiralPoints[i].y  20,
                    width: 32,
                    height: 32
                }) -}
                <> [ let {radius, theta} = fromMaybe {radius: 0.0, theta: 0.0} (pointsPolar !! position) in
                    g [
                    key "frog",
                    class' "frog-frog-container" true,
                    style "transform" $ translate radius 0.0 <> " rotate(" <> show (theta * 180.0 / pi) <> "deg)",
                    style "transform-origin" $ show (-radius) <> "px 0"
                ] [
                    g [
                        class' "frog-frog-container" true,
                        style "transform" $ "rotate(" <> show (-theta * 180.0 / pi) <> "deg)"
                    ] [
                        use (-20.0) (-20.0) 40.0 40.0 "#frog" [
                            class' "frog-frog" true,
                            class' "goal" $ position == 0
                        ]
                    ]
                ]],
            span [] [text $
                if position == 0 then
                    "Partie finie"
                else if state^._turn == 0 then
                    "Tour du premier joueur"
                else if state^._mode == DuelMode then
                    "Tour du second joueur"
                else 
                    "Tour de l'IA"
            ]
        ]

    board = incDecGrid lens state [grid]

    rules = [
        text "Jeu de la grenouille", br,
        text "Règles pas encore définies"
    ]
    -- winTitle: winTitleFor2Players(state)