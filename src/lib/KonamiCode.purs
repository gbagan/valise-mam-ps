module Lib.KonamiCode (konamiCode) where
import MamPrelude
import Data.Array (takeEnd)

codeSequence ∷ Array String
codeSequence = ["ArrowUp", "ArrowUp", "ArrowDown", "ArrowDown", "ArrowLeft", "ArrowRight", "ArrowLeft", "ArrowRight", "b", "a"]

konamiCode ∷ ∀m st. MonadState st m ⇒ Lens' st (Array String) → m Unit → String → m Unit
konamiCode lens onActivation key = do
    state ← get
    let seq = takeEnd 10 $ (state ^. lens) `snoc` key
    lens .= seq
    when (seq == codeSequence) onActivation