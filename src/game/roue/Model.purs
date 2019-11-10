module Game.Roue.Model where

import MyPrelude
import Lib.Util (swap)
import Control.Monad.Rec.Class (tailRecM, Step(..))
import Game.Core (class Game, GState(..), genState, newGame', lockAction, _position, _showWin, defaultSizeLimit)
import Pha.Action (Action, action, delay, DELAY, RNG, getState, setState)

type Position = Array (Maybe Int)

data Ball = Panel Int | Wheel Int | Board
derive instance eqBall :: Eq Ball

type Ext' = {
    size :: Int,
    rotation :: Int,
    dragged :: Maybe Ball
}
newtype Ext = Ext Ext'
type State = GState Position Ext

istate :: State
istate = genState [] identity (Ext {rotation: 0, size: 5, dragged: Nothing})

_ext :: Lens' State Ext'
_ext = lens (\(State _ (Ext a)) -> a) (\(State s _) x -> State s (Ext x))
_rotation :: Lens' State Int
_rotation = _ext ∘ lens (_.rotation) (_{rotation = _})
_size :: Lens' State Int
_size = _ext ∘ lens (_.size) (_{size = _})
_dragged :: Lens' State (Maybe Ball)
_dragged = _ext ∘ lens (_.dragged) (_{dragged = _})

-- renvoie un tableau indiquant quelles sont les balles alignées avec leur couleur
aligned :: State -> Array Boolean
aligned state =
    state^._position # mapWithIndex (\index -> maybe false $ \c -> c == (index + rot) `mod` n)
    where
        n = length $ state^._position
        rot = state^._rotation

validRotation' :: State -> Boolean
validRotation' state = (length $ filter identity $ aligned state) == 1

-- une rotation est valide si exactement une couleur est alignée et il y a une balle pour chque couleur         
validRotation :: State -> Boolean
validRotation state = validRotation' state && (all isJust $ state^._position )


instance roueGame :: Game (Array (Maybe Int)) Ext {from :: Ball, to :: Ball} where
    play state move = act (state^._position) where
        act = case move of 
            {from: Panel from, to: Wheel to} -> ix to .~ Just from
            {from: Wheel from, to: Wheel to } -> swap from to
            {from: Wheel from, to: Board} -> ix from .~ Nothing
            _ -> identity
    
    canPlay _ _ = true
    
    initialPosition state = pure $ replicate (state^._size) Nothing

    isLevelFinished _ = false
    
    onNewGame = pure ∘ (_rotation .~ 0)

    computerMove _ = Nothing
    sizeLimit = defaultSizeLimit
    updateScore st = st ~ true


-- tourne la roue de i crans
rotate :: Int -> State -> State
rotate i = _rotation %~ add i

rotateA :: ∀effs. Int -> Action State effs
rotateA i = action $ rotate i

setSizeA :: ∀effs. Int -> Action State (rng :: RNG | effs)
setSizeA = newGame' (set _size)


checkA :: ∀effs. Action State (delay :: DELAY | effs)
checkA = lockAction $ getState >>= \st -> tailRecM go (st^._size) where
    go 0 = do
        setState (_showWin .~ true)
        delay $ 1000
        setState (_showWin .~ false)
        pure (Done unit)
    go i = do
        st2 <- getState
        if not (validRotation st2) then
            pure (Done unit)
        else do
            setState (rotate 1)
            delay 600
            pure $ Loop (i-1)

deleteDraggedA :: ∀effs. Action State effs
deleteDraggedA = action \state ->
    let state2 = state # _dragged .~ Nothing in
    state^._dragged # maybe state2 case _ of
            Wheel i -> state2 # (_position ∘ ix i) .~ Nothing
            _ -> state2
