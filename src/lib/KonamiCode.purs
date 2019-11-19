module Lib.KonamiCode (konamiCode) where
import MyPrelude
import Data.Array (takeEnd)
import Pha.Action (Action, getState, setState)

codeSequence :: String
codeSequence = "ArrowUp ArrowUp ArrowDown ArrowDown ArrowLeft ArrowRight ArrowLeft ArrowRight b a"

konamiCode :: ∀a effs. Lens' a (Array String) -> Action a effs -> String -> Action a effs
konamiCode lens onActivation key = do
    state <- getState
    let seq = state ^. lens # flip snoc key # takeEnd 10
    setState (lens .~ seq)
    when (joinWith " " seq == codeSequence) onActivation