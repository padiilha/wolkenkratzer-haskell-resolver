# Wolkenkratzer — Resolvedor em Haskell

**Disciplina:** INE5416 – Paradigmas de Programação  
**Alunos:**

- Cauã Pablo Padilha (22100895)
- Lucas Pagotto Coutinho de Oliveira (18201971)

---

## O puzzle

Wolkenkratzer é um puzzle lógico, derivado do Sudoku, jogado em uma grade N×N.

**Regras:**

- Cada célula recebe um número de 1 até `maxH` (altura máxima).
- Numa mesma linha ou coluna, nenhum valor pode se repetir (células vazias não contam).
- As dicas nas bordas indicam quantos prédios são **visíveis** olhando de fora para dentro.
- Um prédio é visível quando nenhum prédio mais alto está na frente dele.
- Células marcadas com `-1` não recebem prédio (podem se repetir livremente na linha/coluna).

**Exemplo de visibilidade** — linha `[1, 3, 2, 4]` vista da esquerda:

- `1` → visível (nada na frente)
- `3` → visível (mais alto que `1`)
- `2` → **oculto** (bloqueado por `3`)
- `4` → visível (mais alto que `3`)
- Resultado: **3 prédios visíveis**

---

## Como executar

```
runhaskell Main.hs
```

Não são necessárias bibliotecas externas além de `Data.List` da biblioteca padrão.

---

## Como configurar um puzzle

Edite as constantes no topo do arquivo `Main.hs`:

```haskell
n    = 6   -- tamanho da grade (n×n)
maxH = 5   -- altura máxima dos prédios
```

Defina as dicas de cada borda (use `Nothing` quando não houver dica naquela posição):

```haskell
cluesTop    = [Just 4, Nothing, Nothing, Just 4, Just 3, Just 5]
cluesBottom = [Nothing, Just 3, Just 3, Just 2, Just 3, Nothing]
cluesLeft   = [Nothing, Nothing, Nothing, Nothing, Just 2, Nothing]
cluesRight  = [Nothing, Just 3, Just 2, Nothing, Nothing, Just 1]
```

Defina a grade inicial (células já preenchidas pelo enunciado):

```haskell
startGrid =
  [ [ 0,  0,  0,  0,  0,  0 ]   -- linha 0
  , [ 0,  0,  1,  5,  0,  0 ]   -- linha 1: col 2 = 1, col 3 = 5 (dados)
  , [ 0,  0,  0,  0,  0,  0 ]   -- ...
  , ...
  ]
-- 0 = célula vazia (o solver preenche)
-- 1..maxH = altura pré-preenchida pelo enunciado
```

---

## Estrutura do código (`Main.hs`)

| Seção                    | O que faz                                                                                                    |
| ------------------------ | ------------------------------------------------------------------------------------------------------------ |
| **Tipos**                | Define `Grid` (`[[Int]]`) e `Puzzle` (tamanho, alturas, dicas, grade inicial)                                |
| **Utilitários de grade** | `getRow`, `getCol`, `setCell`, `findEmpty` — operações puras sobre listas                                    |
| **Validação**            | `noDups` — garante que valores positivos não se repetem na linha/coluna                                      |
| **Visibilidade**         | `countVisible` — conta prédios visíveis da esquerda; `reverse` para o lado direito/baixo                     |
| **Checagem de dicas**    | Verifica dicas de borda só quando a linha/coluna está completa; poda antecipada de células vazias em excesso |
| **Solver**               | `solve` + `tryValues` — backtracking: tenta valores um a um, recua ao encontrar contradição                  |

### Algoritmo (backtracking)

```
solve:
  achar a primeira célula vazia
  se não há célula vazia → grade completa → verificar dicas → sucesso ou falha

tryValues (tentando valor v):
  v gera duplicata na linha/coluna? → pular
  colocar v; verificar dicas da linha e coluna afetadas
  dica falhou? → podar (pular v)
  recursão bem-sucedida? → retornar solução
  recursão falhou? → backtrack, tentar próximo v
```
