module Game.Paths where
import MyPrelude
import Game (class CGame)
import Game.Core (init) as C
import Game.Paths.Model (State, istate) as M
import Game.Paths.View (view) as V

newtype State = State M.State
is :: Iso' State M.State
is = iso (\(State a) -> a) State

instance cgame :: CGame State where
    init (State st) = C.init st <#> State -- todo simplifier? 
    view lens (State st) = V.view (lens ∘ is) st
    onKeyDown _ = mempty

state :: State
state = State M.istate