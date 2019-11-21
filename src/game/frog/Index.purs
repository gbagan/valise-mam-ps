module Game.Frog (State, state) where
import MyPrelude
import Pha.Action ((🔍))
import Pha.Lens (viewOver)
import Game (class CGame)
import Game.Core (init) as C
import Game.Frog.Model (State, istate, onKeyDown) as M
import Game.Frog.View (view) as V

newtype State = State M.State
_iso :: Iso' State M.State
_iso = iso (\(State a) -> a) State

instance cgame :: CGame State where
    init = _iso 🔍 C.init
    view lens (State st) = viewOver (lens ∘ _iso) (V.view st)
    onKeyDown a = _iso 🔍 M.onKeyDown a

state :: State
state = State M.istate