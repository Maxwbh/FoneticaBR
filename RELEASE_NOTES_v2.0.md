# Release Notes — FoneticaBR v2.0

**Data:** Fevereiro de 2026
**Autor:** Maxwell Oliveira (maxwbh@gmail.com)
**Compatibilidade:** Oracle 9i · 10g · 11g · 12c · 18c · 19c · 21c · 23ai

---

## Visão Geral

A versão 2.0 do FoneticaBR representa uma revisão profunda do algoritmo original (v1.0, 2019), corrigindo bugs críticos que comprometiam a precisão fonética, adicionando novas regras validadas por pesquisa comparativa com 5 algoritmos de referência, e introduzindo documentação completa em português brasileiro.

O número de regras fonéticas foi expandido de **45 para 51**, cobrindo dígrafos e padrões anteriormente ausentes.

---

## Correções de Bugs Críticos

### 🔴 [BUG] Off-by-one no loop de substituições

**Impacto:** A última regra fonética (`Z → S`) nunca era processada.

```
Antes:  FOR pos IN 1 .. regexp_count(chars_s, ',') LOOP      -- 44 iterações (faltava 1)
Depois: FOR pos IN 1 .. regexp_count(chars_s, ',') + 1 LOOP  -- 45 iterações (correto)
```

**Exemplo afetado:**

| Entrada | v1.0 (errado) | v2.0 (correto) |
|---------|--------------|----------------|
| FAZENDA | FAZEMDA | **FASEMDA** |
| GONZAGA | GOMZAGA | **GOMSAGA** |

---

### 🔴 [BUG] Ordenação incorreta da regra N → M

**Impacto:** A regra `N → M` era aplicada antes de `NH → N`, `NG → G` e `NJ → J`, tornando esses três dígrafos completamente inoperantes.

```
Antes:  ...,N,NG,NH,NJ,...   ← N converte antes, NH/NG/NJ nunca disparam
Depois: ...,NG,NH,NJ,N,...   ← dígrafos processados primeiro (correto)
```

**Exemplos afetados:**

| Entrada | v1.0 (errado) | v2.0 (correto) |
|---------|--------------|----------------|
| NINHO | MIMO | **NINO** |
| ANGOLA | AMGORA | **AGORA** |
| NINJA | MIMJA | **MIJA** |

---

### 🔴 [BUG] Conflito Ç: normalização vs. regra fonética

**Impacto:** A função `normalize()` convertia `Ç → C`, tornando a regra `Ç → S` em `foneticabr()` código morto. Em português brasileiro, Ç representa o fonema /s/.

```
Antes:  chr(199) = Ç → 'C'  (em normalize)  →  regra Ç→S nunca dispara
Depois: chr(199) removido de normalize        →  regra Ç→S funciona corretamente
```

**Exemplo afetado:**

| Entrada | v1.0 (errado) | v2.0 (correto) |
|---------|--------------|----------------|
| AÇÚCAR | AKUKAR | **ASUKAR** |
| ALVOROÇO | ARVOROKO | **ARVOROSO** |

---

### 🔴 [BUG] Caractere À (chr 192) ausente na normalização

**Impacto:** O caractere `À` não era normalizado. O código possuía `chr(198)` duplicado no lugar de `chr(192)`.

```
Antes:  chr(198) || chr(198) || chr(223) ...   ← À ignorado, Æ duplicado
Depois: chr(192) || chr(198) || chr(223) ...   ← À → A, Æ → A (correto)
```

---

### 🟡 [BUG] Mapeamento incorreto RM → SM

**Impacto:** A regra `RM → SM` produzia resultados incorretos. O padrão correto (BuscaBR) é `RM → M`.

```
Antes:  RM → SM   (ex: ARMANDO → ASMADO)
Depois: RM → M    (ex: ARMANDO → AMADO)
```

---

### 🟡 [BUG] Remoção de duplicatas incompleta

**Impacto:** O loop `FOR a IN 65..90` só eliminava pares (`AA → A`), deixando triplas intactas (`AAA → AA`).

```
Antes:  FOR a IN 65..90 LOOP REPLACE(str, chr(a)||chr(a), chr(a)); END LOOP;
Depois: regexp_replace(str, '(.)\1+', '\1')   -- elimina qualquer sequência repetida
```

---

## Novas Regras Fonéticas

Baseadas em pesquisa comparativa com **BuscaBR**, **Metaphone-ptBR**, **MTFN** e fonologia da língua portuguesa (Bisol, 1996).

### QUE / QUI → KE / KI

**Fundamentação:** Em português, o dígrafo QU antes de E ou I possui U silencioso. "Queijo" soa como /keʒu/, não /kweʒu/.

| Entrada | v1.0 | v2.0 |
|---------|------|------|
| QUEIJO | KUEIO | **KEIO** |
| QUILOMBO | KUIROMBO | **KIROMBO** |
| ESQUEMA | ESKUEMA | **ESKEMA** |

---

### SCE / SCI → SE / SI

**Fundamentação:** No dígrafo SC antes de E ou I, o C é silencioso. "Nascer" soa como /naseɾ/, não /naskeɾ/.

| Entrada | v1.0 | v2.0 |
|---------|------|------|
| NASCER | NAS | **NASE** |
| DESCIDA | DESDA | **DESIDA** |
| NASCIMENTO | - | **NASIMEMTO** |

---

### TH → T

**Fundamentação:** Em palavras de origem grega ou inglesa incorporadas ao português, TH tem pronúncia de /t/.

| Entrada | v1.0 | v2.0 |
|---------|------|------|
| THEATRO | - | **TEATRO** |
| THOMAS | - | **TOMA** |
| THIAGO | IAGO | **TIAGO** |

---

### SM → M

**Fundamentação:** Regra presente no BuscaBR e ausente na v1.0. O grupo SM se reduz ao fonema nasal M.

| Entrada | v1.0 | v2.0 |
|---------|------|------|
| ESMERALDA | ESMERARDA | **EMERARDA** |

---

## Equivalências Fonéticas Validadas

Pares de nomes que agora produzem o mesmo código fonético:

| Par | Código v2.0 |
|-----|------------|
| RAFAEL ~ RAPHAEL | `RAFA` |
| THIAGO ~ TIAGO | `TIAGO` |
| QUEIJO ~ KEIJO | `KEIO` |
| CECILIA ~ SESILIA | `SESIRA` |
| GONZAGA ~ GONSAGA | `GOMSAGA` |
| CHRISTIANO ~ CRISTIANO | `KRISTIANO` |

---

## Melhorias Técnicas

| Item | v1.0 | v2.0 |
|------|------|------|
| Regras fonéticas | 45 | **51** |
| Casos de teste | 1 (sem estrutura) | **29 (automatizados)** |
| Documentação | 13 linhas | **~570 linhas** |
| Acentuação nos comentários | Parcial | **Completa (PT-BR)** |
| Badges no README | Nenhum | **4 (Oracle, Licença, Versão, pt-BR)** |
| Seção de contribuição | Não | **Sim** |
| Tabela de caracteres acentuados | Não | **Sim (com símbolos reais)** |

---

## Fontes e Referências

| Algoritmo / Obra | Contribuição para v2.0 |
|---|---|
| BISOL, Leda (1996) — _Fonologia do Português Brasileiro_ | Base teórica, fonemas do PT-BR |
| BuscaBR — Fred Jorge (2007) | Regras SM→M, RM→M, ordenação N |
| Metaphone-ptBR — Carlos Jordão | Regras QUE/QUI, TH→T |
| MTFN — Ruliana | Validação cruzada de regras |
| Fonologia da Língua Portuguesa (Wikipedia) | Dígrafos SCE/SCI, QUE/QUI |

---

## Arquivos Alterados

| Arquivo | Alterações |
|---------|-----------|
| `PKG_UTIL_BODY.sql` | 5 correções de bugs, 6 novas regras |
| `PKG_UTIL_SPEC.sql` | Correção de comentário |
| `Script_Teste.sql` | Reescrita completa — 29 casos automatizados |
| `README.md` | Reescrita completa — documentação metodológica |
| `RELEASE_NOTES_v2.0.md` | Novo arquivo (este documento) |

---

## Instalação / Atualização

```sql
-- 1. Recompilar a especificação
@PKG_UTIL_SPEC.sql

-- 2. Recompilar o corpo
@PKG_UTIL_BODY.sql

-- 3. Validar
SELECT object_name, status
FROM user_objects
WHERE object_name = 'PKG_UTIL';

-- 4. Executar testes
SET SERVEROUTPUT ON;
@Script_Teste.sql
```

> **Atenção:** Se existir índice fonético baseado em coluna virtual, reconstrua-o após a atualização:
>
> ```sql
> ALTER INDEX idx_clientes_fonetico REBUILD;
> ```

---

## Comparação de Saída — v1.0 vs v2.0

```
Entrada:        "NINHO DA ANGOLA"

v1.0 (bugs):    "MIMO DA AMGORA"   ← NH e NG quebrados por N→M antecipado
v2.0 (correto): "NINO DA AGORA"    ← dígrafos processados na ordem correta
```

```
Entrada:        "QUEIJO COM AÇÚCAR"

v1.0 (bugs):    "KUEIO KO AKUKAR"  ← QUE não silenciado, Ç→C incorreto
v2.0 (correto): "KEIO KO ASUKAR"   ← QUE→KE e Ç→S funcionando
```

---

_FoneticaBR v2.0 — Pesquisa Fonética para o Padrão Brasileiro (PL/SQL)_
_https://github.com/Maxwbh/FoneticaBR_
