module Main where

import Data.List (nub)

-- =============================================================================
-- TIPOS
-- =============================================================================

-- Valores de célula: 0 = vazia (solver preenche), -1 = sem prédio, 1‥N = altura
type Grid = [[Int]]

-- Representa um puzzle Wolkenkratzer completo.
data Puzzle = Puzzle
  { gridSize    :: Int          -- tamanho do grid (linhas e colunas)
  , maxHeight   :: Int          -- altura máxima permitida
  , topClues    :: [Maybe Int]  -- dicas do topo, uma por coluna
  , bottomClues :: [Maybe Int]  -- dicas da base, uma por coluna
  , leftClues   :: [Maybe Int]  -- dicas da esquerda, uma por linha
  , rightClues  :: [Maybe Int]  -- dicas da direita, uma por linha
  , initial     :: Grid         -- grade inicial
  }

-- =============================================================================
-- CONFIGURAÇÃO DO PUZZLE
-- =============================================================================
--
-- Posição das dicas ao redor do grid:
--
--             top: [c1, c2, c3, c4, c5, c6]
--                   ↓   ↓   ↓   ↓   ↓   ↓
--           ┌────┬────┬────┬────┬────┬────┐
--  left[0] →│    │    │    │    │    │    │← right[0]
--  left[1] →│    │    │    │    │    │    │← right[1]
--  left[2] →│    │    │    │    │    │    │← right[2]
--  left[3] →│    │    │    │    │    │    │← right[3]
--  left[4] →│    │    │    │    │    │    │← right[4]
--  left[5] →│    │    │    │    │    │    │← right[5]
--           └────┴────┴────┴────┴────┴────┘
--                   ↑   ↑   ↑   ↑   ↑   ↑
--             bot: [c1, c2, c3, c4, c5, c6]
--
-- Use Nothing quando não houver dica numa posição.
-- Exemplo: [Just 3, Nothing, Just 2, Just 1, Just 4, Just 2]

-- Tamanho do grid (número de linhas e colunas):
n :: Int
n = 6

-- Altura máxima dos prédios:
maxH :: Int
maxH = 6

-- Dicas vistas de cima (uma por coluna, da esquerda para a direita):
cluesTop :: [Maybe Int]
cluesTop = [Just 4, Nothing, Nothing, Just 4, Just 3, Just 5]

-- Dicas vistas de baixo (uma por coluna, da esquerda para a direita):
cluesBottom :: [Maybe Int]
cluesBottom = [Nothing, Just 3, Just 3, Just 2, Just 3, Nothing]

-- Dicas vistas da esquerda (uma por linha, de cima para baixo):
cluesLeft :: [Maybe Int]
cluesLeft = [Nothing, Nothing, Nothing, Nothing, Just 2, Nothing]

-- Dicas vistas da direita (uma por linha, de cima para baixo):
cluesRight :: [Maybe Int]
cluesRight = [Nothing, Just 3, Just 2, Nothing, Nothing, Just 1]

-- Grade inicial:
--   0     = célula vazia (o solver preenche)
--  1‥maxH = altura pré-preenchida pelo enunciado
startGrid :: Grid
startGrid =
  [ [ 0,  0,  0,  0,  0,  0 ]   -- linha 0
  , [ 0,  0,  0,  0,  0,  0 ]   -- linha 1
  , [ 0,  0,  1,  5,  0,  0 ]   -- linha 2
  , [ 0,  0,  0,  0,  0,  0 ]   -- linha 3
  , [ 0,  0,  0,  0,  0,  0 ]   -- linha 4
  , [ 0,  0,  0,  0,  0,  0 ]   -- linha 5
  ]

-- Constrói o puzzle a partir das configurações definidas.
puzzle :: Puzzle
puzzle = Puzzle
  { gridSize    = n
  , maxHeight   = maxH
  , topClues    = cluesTop
  , bottomClues = cluesBottom
  , leftClues   = cluesLeft
  , rightClues  = cluesRight
  , initial     = startGrid
  }

-- =============================================================================
-- UTILITÁRIOS DO GRID
-- =============================================================================

getRow :: Grid -> Int -> [Int]
getRow grid row = grid !! row

getCol :: Grid -> Int -> [Int]
getCol grid col = map (!! col) grid

-- Substitui o elemento na posição i por x (cria nova lista; Haskell não tem mutação).
replaceAt :: [a] -> Int -> a -> [a]
replaceAt xs i x = take i xs ++ [x] ++ drop (i + 1) xs

-- Retorna novo grid com o valor val na célula (row, col).
setCell :: Grid -> Int -> Int -> Int -> Grid
setCell grid row col val = replaceAt grid row (replaceAt (getRow grid row) col val)

-- Encontra a primeira célula vazia (0) que o solver precisa preencher.
findEmpty :: Grid -> Maybe (Int, Int)
findEmpty grid =
  case [ (r, c)
       | (r, row) <- zip [0..] grid
       , (c, val) <- zip [0..] row
       , val == 0 ] of
    []      -> Nothing
    (pos:_) -> Just pos

-- =============================================================================
-- VALIDAÇÃO
-- =============================================================================

-- Verdadeiro se os valores positivos da lista não se repetem (zeros e -1 são ignorados).
noDups :: [Int] -> Bool
noDups xs =
  let filled = filter (> 0) xs
  in  length filled == length (nub filled)

-- Verdadeiro se colocar val em (row, col) não gera duplicata na linha nem na coluna.
isValidPlacement :: Grid -> Int -> Int -> Int -> Bool
isValidPlacement grid row col val =
  noDups (replaceAt (getRow grid row) col val) &&
  noDups (replaceAt (getCol grid col) row val)

-- =============================================================================
-- CONTAGEM DE PRÉDIOS VISÍVEIS
-- =============================================================================

-- Conta prédios visíveis olhando da esquerda para a direita.
-- Um prédio é visível quando é mais alto que todos os anteriores.
-- Células -1 (sem prédio) são ignoradas.
-- Exemplo: [1,3,2,4] → vê 1, vê 3, oculto 2, vê 4 = 3 visíveis
countVisible :: [Int] -> Int
countVisible = go 0 . filter (/= -1)
  where
    go _       []     = 0
    go tallest (x:xs)
      | x > tallest = 1 + go x xs
      | otherwise   =     go tallest xs

-- Valida uma dica de borda. Nothing sempre passa; Just n exige exatamente n visíveis.
checkClue :: Maybe Int -> [Int] -> Bool
checkClue Nothing  _  = True
checkClue (Just n) xs = countVisible xs == n

-- =============================================================================
-- VERIFICAÇÃO DE DICAS
-- =============================================================================

-- Linha ou coluna completa quando não há mais células vazias (0).
isComplete :: [Int] -> Bool
isComplete = notElem 0

-- Conta células com prédio (valor positivo).
buildingCount :: [Int] -> Int
buildingCount = length . filter (> 0)

-- Verifica dicas de esquerda/direita para a linha row.
-- Incompleta: poda se já há -1s demais. Completa: verifica contagem e dicas.
checkRowClues :: Puzzle -> Grid -> Int -> Bool
checkRowClues puzzle grid row =
  let r         = getRow grid row
      blanks    = length (filter (== -1) r)
      maxBlanks = gridSize puzzle - maxHeight puzzle
  in  if isComplete r
        then buildingCount r == maxHeight puzzle             &&
             checkClue (leftClues  puzzle !! row) r          &&
             checkClue (rightClues puzzle !! row) (reverse r)
        else blanks <= maxBlanks

-- Verifica dicas de topo/base para a coluna col.
-- Incompleta: poda se já há -1s demais. Completa: verifica contagem e dicas.
checkColClues :: Puzzle -> Grid -> Int -> Bool
checkColClues puzzle grid col =
  let c         = getCol grid col
      blanks    = length (filter (== -1) c)
      maxBlanks = gridSize puzzle - maxHeight puzzle
  in  if isComplete c
        then buildingCount c == maxHeight puzzle              &&
             checkClue (topClues    puzzle !! col)         c  &&
             checkClue (bottomClues puzzle !! col) (reverse c)
        else blanks <= maxBlanks

-- Verdadeiro se todas as linhas e colunas satisfazem suas dicas.
checkAllClues :: Puzzle -> Grid -> Bool
checkAllClues puzzle grid =
  all (checkRowClues puzzle grid) [0 .. gridSize puzzle - 1] &&
  all (checkColClues puzzle grid) [0 .. gridSize puzzle - 1]

-- =============================================================================
-- RESOLVEDOR POR BACKTRACKING
-- =============================================================================

-- Tenta cada candidato para a célula (row, col); retrocede quando necessário.
-- Para cada valor v:
--   1. Gera duplicata na linha/coluna → pular.
--   2. Viola dica ao completar linha/coluna → podar.
--   3. Válido → recursão; se falhar → backtracking.
tryValues :: Puzzle -> Grid -> Int -> Int -> [Int] -> Maybe Grid
tryValues _ _ _ _ [] = Nothing  -- sem candidatos: falha e sinaliza backtracking
tryValues puzzle grid row col (val:vals)
  | not (isValidPlacement grid row col val) = tryValues puzzle grid row col vals
  | otherwise =
      let grid' = setCell grid row col val
      in  if checkRowClues puzzle grid' row && checkColClues puzzle grid' col
            then case solve puzzle grid' of
                   Just result -> Just result
                   Nothing     -> tryValues puzzle grid row col vals  -- backtracking
            else                  tryValues puzzle grid row col vals  -- poda

-- Preenche uma célula por vez (esquerda→direita, cima→baixo).
-- Retorna Nothing se não há solução a partir do estado atual.
solve :: Puzzle -> Grid -> Maybe Grid
solve puzzle grid =
  case findEmpty grid of
    Nothing        -> if checkAllClues puzzle grid then Just grid else Nothing
    Just (row,col) -> tryValues puzzle grid row col (candidates puzzle)

-- Valores candidatos: 1..maxH, mais -1 (vazio) quando maxH < n.
candidates :: Puzzle -> [Int]
candidates puzzle = [1 .. maxHeight puzzle] ++ [ -1 | maxHeight puzzle < gridSize puzzle ]

-- =============================================================================
-- SAÍDA
-- =============================================================================

-- Imprime o grid no terminal, uma linha por vez.
printGrid :: Grid -> IO ()
printGrid = mapM_ (putStrLn . unwords . map show)

-- =============================================================================
-- MAIN
-- =============================================================================

main :: IO ()
main = do
  putStrLn "=== Wolkenkratzer ==="
  case solve puzzle (initial puzzle) of
    Nothing   -> putStrLn "Nenhuma solução encontrada."
    Just grid -> printGrid grid
