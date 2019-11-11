module Game.Valise.View where
import MyPrelude
import Game.Effs (EFFS)
import Game.Valise.Model (State, showHelpA, setDragA, moveObjectA, _positions)
import Pha (VDom, Prop, h, text, maybeN)
import Pha.Action ((🔍))
import Pha.Html (div', a, svg, g, class', svguse, rect, attr, style, href, width, height, viewBox, fill, transform, translate, x, y, pc,
    pointermove, pointerenter, pointerleave, pointerup, pointerdown)

pos :: ∀a effs. Int -> Int -> Int -> Int -> Array (Prop a effs)
pos x' y' w h = [
    width (show w),
    height (show h),
    x (show x'),
    y (show y')
]

valise :: ∀a. Lens' a State -> State -> VDom a EFFS
valise lens state = svg [
    viewBox 0 0 825 690,
    pointermove $ lens 🔍 moveObjectA,
    pointerup $ lens 🔍 setDragA Nothing
][
    h "use" [href "#valise", class' "valise-close" true, width "100%", height "100%"] [], 
    
    -- 
   

    g [class' "valise-open" true] [
        h "use" [href "#openvalise"] [],

        object { symbol: "switch", link: Nothing, help: "", drag: false } 
            300 460 42 60 [] [], {-

            Object({
                symbol: 'bulboff',
                class: {'valise-bulb': true, on: state.isSwitchOn},
                help: 'Trouve un moyen d\'allumer l\'ampoule',
            }, -}

        object { symbol: "bulbon", link: Just "noirblanc", help: "Jeu: tour noir, tout blanc", drag: false } 
            477 280 48 48 [] [],
        

        object { symbol: "frog2", link: Just "frog", help: "Jeu: la grenouille", drag: false}
            549 320 40 40 [fill "#bcd35f"] [x "10%", y "20%", width "80%", height "80%"],

        object { symbol: "flowerpot", link: Nothing, help: "Quelque chose se cache derrière ce pot", drag: true}
            533 300 64 64 [] [],

        object { symbol: "hanoibot", link: Just "solitaire", help: "Jeu: solitaire", drag: false}
            500 430 75 51 [] [x "30%", y "20%", width "40%", height "40%"],

        object { symbol: "hanoitop", link: Nothing, help: "Quelque chose se cache sous cette tour", drag: true}
            507 409 60 57 [] [],

        object {symbol: "knight", link: Just "queens", help: "Jeu: les 8 reines", drag: false}
            461 380 24 48 [transform "rotate(40)"] [],
    
        object { symbol: "pen", link: Just "dessin", help: "Jeu: dessin", drag: false}
            610 400 60 60 [] [],
        
        object {symbol: "stack", link: Just "jetons", help: "Jeu: jetons", drag: false}
            350 500 50 50 [] [],

        object {symbol: "wheel", link: Just "roue", help: "Jeu: roue des couleurs", drag: false}
            400 205 50 50 [transform "scale(1,0.8)"] [],

        object {symbol: "card", link: Just "nim", help: "Jeu: Poker Nim", drag: false}
            450 130 40 50 [transform "rotate(30)"] [],

        object {symbol: "tile", link: Just "tiling", help: "Jeu: carrelage", drag: false}
            280 400 120 60 [] [],

        object {symbol: "tricolor", link: Just "baseball", help: "Jeu: baseball multicolore", drag: false}
            350 330 90 60 [] [],

        object {symbol: "race", link: Just "paths", help: "Jeu: chemins", drag: false}
            450 445 64 64 [transform "rotate(40)"] [],

        object {symbol: "paw", link: Just "labete", help: "Jeu: la bête", drag: false}
            300 180 40 40 [transform "rotate(30)", attr "opacity" "0.5"] [],

        object {symbol: "quiet", link: Nothing, help: "Jeu: preuve sans mot", drag: false}
            180 130 50 50 [] [],

        object {symbol: "chocolate", link: Just "chocolat", help: "Jeu: chocolat", drag: false}
            200 200 60 60 [transform "rotate(40)"] []
            --  ;
    ]
] where
    object {drag, link, help, symbol} x' y' w' h' props children =
        let defaultTranslate = translate (pc $ toNumber x' / 8.5)  (pc $ toNumber y' / 6.9) in
        g [style "transform" $ 
            if drag then   
                state ^. (_positions ∘ at symbol) # maybe defaultTranslate \{x: x2, y: y2} -> translate (pc $ 100.0 * x2) (pc $ 100.0 * y2)
            else 
                defaultTranslate
        ] [
            g props [
                svg ([
                    -- payloadFn = relativePointerPosition -- >>= (set('name', drag));
                    -- position = if drag then state.position[drag];
            
                    -- 'touch-action': 'none',
                    class' "valise-object ui-touch-action-none" true,
                    class' "draggable" drag,
                    width w',
                    height h',
                    pointerdown $ if drag then 
                            lens 🔍 setDragA (Just {name: symbol, x: toNumber w' / 1650.0, y: toNumber h' / 1380.0})
                        else
                            pure unit
                ] <> if isJust link then [] else [
                        pointerenter $ lens 🔍 showHelpA help,
                        pointerleave $ lens 🔍 showHelpA ""
                ]) [ 
                    h "use" [
                        href $ "#" <> symbol, class' "valise-symbol" true
                    ] [],
                    maybeN $ link <#> \l -> a [ href $ "#" <> l] [
                        rect "0" "0" "100%" "100%" ([
                            class' "valise-object-link" true, 
                            fill "transparent",
                            pointerenter $ lens 🔍 showHelpA help,
                            pointerleave $ lens 🔍 showHelpA ""
                        ] <> children)
                    ]
                ]
            ]
        ]

view :: ∀a. Lens' a State -> State -> VDom a EFFS 
view lens state = div' [
    class' "ui-flex-center valise-main-container" true,
    class' "open" state.isOpen
] [
    div' [] [
        div' [class' "valise-logo" true] [svguse "#logo" []],
        div' [class' "valise-container" true] [
            valise lens state,
            div' [
                class' "valise-help" true,
                class' "visible" (state.helpVisible && state.help /= "")
            ] [text state.help] 
        ]
    ]
]