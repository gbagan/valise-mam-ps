module Game.Eternal.Model where

import MyPrelude

import Debug.Trace (spy)
import Game.Core (class Game, class MsgWithCore, CoreMsg, GState, SizeLimit(..), playA, coreUpdate, _ext, genState, newGame, _position, _nbRows)
import Game.Effs (EFFS)
import Lib.Util (repeat)
import Pha.Update (Update, getState, purely)

data Edge = Edge Int Int
infix 3 Edge as ↔
instance eqEdge ∷ Eq Edge where
    eq (u1 ↔ v1) (u2 ↔ v2) = u1 == u2  && v1 == v2 || u1 == v2 && u2 == v1
type Pos = { x ∷ Number, y ∷ Number }

-- | une structure Graph est composée d'une liste des arêtes et de la position de chaque sommet dans le plan
type Graph = {vertices ∷ Array Pos, edges ∷ Array Edge }

data GraphKind = Path | Cycle
derive instance eqgkind ∷ Eq GraphKind

data Rules = OneGuard | ManyGuards
derive instance eqrules ∷ Eq Rules

-- | une position est composée de la position des gardes et éventuellement d'un sommet attaqué
type Position = {guards ∷ Array Int, attacked ∷ Maybe Int}

-- | un move est soit un sommet attaqué en cas d'attaque,
-- | soit un ensemble de déplacéments de gardes en cas de défense
data Move = Attack Int | Defense (Array Int)

data Phase = PrepPhase | GamePhase
derive instance eqPhase ∷ Eq Phase

path ∷ Int → Graph
path n =
    {   vertices: repeat n \i → 
            {   x: 0.50 + 0.35 * cos (toNumber i * 2.0 * pi / toNumber n)
            ,   y: 0.50 + 0.35 * sin (toNumber i * 2.0 * pi / toNumber n)
            }
    ,   edges: repeat (n - 1) \i → i ↔ (i + 1)
    }

cycle ∷ Int → Graph
cycle n = g { edges = g.edges `snoc` (0 ↔ (n-1)) }
    where g = path n
{- 
graphs ∷ Array Graph
graphs = [house, ex1, ex2, ex3, cross]
-}

type Ext' = 
    {   graph ∷ Graph
    ,   nextmove ∷ Array Int
    ,   phase ∷ Phase
    ,   graphkind ∷ GraphKind
    ,   draggedGuard ∷ Maybe Int
    ,   rules ∷ Rules
    }

newtype ExtState = Ext Ext'

type State = GState Position ExtState

-- lenses
_ext' ∷ Lens' State Ext'
_ext' = _ext ∘ iso (\(Ext a) → a) Ext
_graph ∷ Lens' State Graph
_graph = _ext' ∘ lens _.graph _{graph = _}
_nextmove ∷ Lens' State (Array Int)
_nextmove = _ext' ∘ lens _.nextmove _{nextmove = _}
_phase ∷ Lens' State Phase
_phase = _ext' ∘ lens _.phase _{phase = _}
_graphkind ∷ Lens' State GraphKind
_graphkind = _ext' ∘ lens _.graphkind _{graphkind = _}
_rules ∷ Lens' State Rules
_rules = _ext' ∘ lens _.rules _{rules = _}
_draggedGuard ∷ Lens' State (Maybe Int)
_draggedGuard = _ext' ∘ lens _.draggedGuard _{draggedGuard = _}

_guards ∷ Lens' Position (Array Int)
_guards = lens _.guards _{guards = _}
_attacked ∷ Lens' Position (Maybe Int)
_attacked = lens _.attacked _{attacked = _}


-- | état initial
istate ∷ State
istate = genState 
            {guards: [], attacked: Nothing}
            _{nbRows = 6, customSize = true}
            (Ext { graphkind: Path, graph: path 1, nextmove: [], phase: PrepPhase, draggedGuard: Nothing, rules: OneGuard})


isValidNextMove ∷ State → Array Int → Boolean
isValidNextMove st dests =
    case (st^._position).attacked of
        Nothing → false
        Just attack →
            let edges = (st^._graph).edges
                srcs = (st^._position).guards
                moveEdges = zipWith (↔) srcs dests
            in
            elem attack dests
            && (moveEdges # all \edge@(from↔to) -> from == to || elem edge edges)

{-
moveGuards ∷ Array Int → Multimove → Array Int
moveGuards guards multimove = guards <#> \guard →
    case multimove # find \{from, to} → from == guard of
        Nothing → guard
        Just {from, to} → to
-}

instance game ∷ Game {guards ∷ Array Int, attacked ∷ Maybe Int} ExtState Move where
    play state (Defense nextmove) =
        case (state^._position).attacked of
            Just attacked ->
                if isValidNextMove state nextmove then
                    Just {attacked: Nothing, guards: nextmove}
                else
                    Nothing
            _ -> Nothing

    play state (Attack x) =
        if elem x (state^._position).guards || isJust (state^._position).attacked then
            Nothing
        else
            Just $ (state^._position) { attacked = Just x}

    initialPosition _ = pure {guards: [], attacked: Nothing}
    
    onNewGame state =
        let state2 = state 
                        # _nextmove .~ [] 
                        # _phase .~ PrepPhase 
                        # _draggedGuard .~ Nothing
        in
        case state^._graphkind of
            Path -> pure (state2 # _graph .~ path (state^._nbRows))
            Cycle -> pure(state2 # _graph .~ cycle (state^._nbRows))

    isLevelFinished state =
        let guards = (state^._position).guards 
            edges = (state^._graph).edges
        in
        case (state^._position).attacked of
            Nothing → false
            Just attack →
                guards # all \guard → not (elem (guard ↔ attack) edges)


    computerMove _ = pure Nothing
    sizeLimit = const (SizeLimit 3 0 10 0)
    updateScore st = st ∧ true


toggleGuard ∷ Int → Array Int → Array Int
toggleGuard x l = if elem x l then filter (_ /= x) l else l `snoc` x

addToNextMove ∷ Array Edge → Int → Int → Array Int → Array Int → Array Int
addToNextMove edges from to srcs dests
    | elem (from ↔ to) edges =
        case elemIndex from srcs of
            Nothing -> spy "1" dests
            Just i -> spy "2" (dests # ix i .~ to) 
    | otherwise = spy "3" dests

dragGuard ∷ Maybe Int → State → State
dragGuard to st =
    case st^._draggedGuard of
        Nothing -> st
        Just from ->
            let to2 = fromMaybe from to in
            st # _nextmove %~ addToNextMove (st^._graph).edges from to2 (st^._position).guards  # _draggedGuard .~ Nothing


data Msg = Core CoreMsg | SetGraphKind GraphKind | SetRules Rules 
            | DragGuard Int | DropGuard Int | LeaveGuard | DropOnBoard
            | StartGame | ToggleGuard Int | Play Int
instance withcore ∷ MsgWithCore Msg where core = Core
    
update ∷ Msg → Update State EFFS
update (Core msg) = coreUpdate msg
update (SetGraphKind kind) = newGame (_graphkind .~ kind)
update (SetRules rules) = newGame (_rules .~ rules)
update StartGame = purely $ \st -> st # _phase .~ GamePhase # _nextmove .~ (st^._position).guards
update (ToggleGuard x) = pure unit
update (DragGuard x) = purely $ _draggedGuard .~ Just x
update (DropGuard to) = purely $ dragGuard (Just to)

update LeaveGuard = purely $ _draggedGuard .~ Nothing
update DropOnBoard = purely $ dragGuard Nothing

update (Play x) = do
    st <- getState
    let guards = (st^._position).guards
    case st^._phase /\ (st^._position).attacked  of
        PrepPhase /\ _ -> purely $ _position ∘ _guards %~ toggleGuard x
        GamePhase /\ Just attacked -> playA $ Defense (addToNextMove (st^._graph).edges x attacked guards guards)
        GamePhase /\ Nothing -> playA (Attack x)