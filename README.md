# FoneticaBR

Pesquisa Fonetica para o padrao Brasileiro - PL/SQL (Oracle Database).

Esta funcao retorna uma string fonetica de um texto passado como parametro, podendo ser utilizada para a busca de nomes com sonoridade proximas, totalmente voltada para o portugues brasileiro (pt-BR).

---

## Sumario

- [Objetivo](#objetivo)
- [Metodologia](#metodologia)
  - [Fundamentacao Linguistica](#fundamentacao-linguistica)
  - [Algoritmos de Referencia](#algoritmos-de-referencia)
  - [Abordagem do FoneticaBR](#abordagem-do-foneticabr)
- [Arquitetura](#arquitetura)
  - [Funcao normalize](#funcao-normalize)
  - [Funcao foneticabr](#funcao-foneticabr)
- [Tabela Completa de Regras Foneticas](#tabela-completa-de-regras-foneticas)
- [Etapas do Algoritmo](#etapas-do-algoritmo)
- [Instalacao](#instalacao)
- [Utilizacao](#utilizacao)
- [Testes](#testes)
- [Compatibilidade](#compatibilidade)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Bibliografia](#bibliografia)
- [Historico de Alteracoes](#historico-de-alteracoes)

---

## Objetivo

Prover uma funcao PL/SQL capaz de gerar codigos foneticos para textos em portugues brasileiro, permitindo:

- Busca por nomes com grafias diferentes mas pronuncia semelhante (ex: Rafael / Raphael)
- Comparacao fonetica entre palavras (ex: Cecilia / Sesilia)
- Indexacao fonetica em bases de dados Oracle para consultas _fuzzy_

O algoritmo SOUNDEX, registrado por Robert Russell e Margaret Odell em 1918 nos Estados Unidos, foi concebido para a lingua inglesa e nao atende adequadamente as particularidades do portugues brasileiro. O FoneticaBR foi desenvolvido como alternativa especifica para o pt-BR.

---

## Metodologia

### Fundamentacao Linguistica

O projeto tem como base a fonologia do portugues brasileiro, com referencia principal na obra de **Leda Bisol (1996)** - _"Introducao a estudos de fonologia do portugues brasileiro"_, que cataloga os fonemas e processos fonologicos do idioma.

A lingua portuguesa apresenta desafios especificos para algoritmos foneticos:

| Desafio | Exemplo | Explicacao |
|---------|---------|------------|
| Uma letra com multiplos fonemas | X | "exame" (som de Z), "taxi" (som de KS), "enxame" (som de CH) |
| Multiplas letras com mesmo fonema | S, SS, C, Ç | Todos produzem o som /s/ em contextos especificos |
| Digrafos consonantais | LH, NH, CH, QU, GU | Duas letras representando um unico som |
| Digrafos com letra muda | SCE, SCI, QUE, QUI | O C em "nascer" e o U em "queijo" sao silenciosos |
| Letras estrangeiras | W, Y, K | Usadas em nomes proprios e estrangeirismos |
| Consoantes finais mudas | S, Z, R, M, N, L | Frequentemente ignoradas ou alteradas na fala |

### Algoritmos de Referencia

O FoneticaBR foi desenvolvido e aprimorado com base no estudo comparativo dos seguintes algoritmos:

| Algoritmo | Autor(es) | Ano | Linguagem | Referencia |
|-----------|-----------|-----|-----------|------------|
| SOUNDEX | Robert Russell, Margaret Odell | 1918 | - | Patente US 1261167 (ingles) |
| BuscaBR | Fred Jorge; Marcos Rodrigues; Gabriel Sobrinho | 2007-2011 | PL/SQL | linhadecodigo.com.br |
| Metaphone-ptBR | Carlos Jordao | - | PHP/Python | github.com/carlosjordao/metaphone-ptbr |
| MTFN | Ruliana | - | Ruby | github.com/ruliana/MTFN |
| Fonetizacao InCor/USP | Instituto do Coracao - FMUSP | - | Java | devmedia.com.br |
| FoneticaBR (este projeto) | Maxwell Oliveira | 2019 | PL/SQL | github.com/Maxwbh/FoneticaBR |

### Abordagem do FoneticaBR

O FoneticaBR adota uma abordagem distinta dos demais algoritmos:

| Caracteristica | FoneticaBR | BuscaBR | Metaphone-ptBR |
|---------------|------------|---------|----------------|
| Preserva vogais | Sim | Nao (elimina) | Nao (elimina) |
| Linguagem nativa | PL/SQL | PL/SQL | PHP/Python |
| Legibilidade do resultado | Alta | Baixa | Baixa |
| Regras foneticas | 51 | ~30 | ~40 |
| Contexto de posicao | Nao | Nao | Sim (parcial) |

**Escolha de preservar vogais:** enquanto BuscaBR e Metaphone-ptBR eliminam todas as vogais para gerar codigos compactos, o FoneticaBR as preserva, resultando em saidas mais legiveis e adequadas para nomes brasileiros com alta incidencia de vogais.

Exemplo comparativo:

```
Entrada:     "JOAO DA SILVA E OLIVEIRA"
FoneticaBR:  "JO DA SIRVA E ORIVEIRA"    (legivel)
BuscaBR:     "J D SRV ORVR"              (compacto)
```

---

## Arquitetura

O projeto e implementado como um **Oracle PL/SQL Package** (`PKG_UTIL`) com duas funcoes:

```
PKG_UTIL
  |-- normalize(str1)     -- Funcao interna: normalizacao de caracteres
  |-- foneticabr(str1)    -- Funcao publica: conversao fonetica
```

### Funcao `normalize`

**Proposito:** Preparar o texto de entrada removendo acentos, caracteres especiais e padronizando a caixa.

**Etapas:**
1. Converte para maiusculas (`UPPER`)
2. Substitui caracteres acentuados por seus equivalentes ASCII (30 mapeamentos)
3. Remove espacos duplicados
4. Remove caracteres invalidos via regex, mantendo: `A-Z`, `0-9`, `Ç`, `&`, `@`, `_`, espaco, `+`, `-`

**Mapeamento de caracteres acentuados:**

| Caractere | Chr | Substituto | Caractere | Chr | Substituto |
|-----------|-----|-----------|-----------|-----|-----------|
| A (grave) | 192 | A | I (circ.) | 206 | I |
| AE (lig.) | 198 | A | I (trema) | 207 | I |
| sz (lig.) | 223 | B | ETH       | 208 | D |
| A (agudo) | 193 | A | N (til)   | 209 | N |
| A (circ.) | 194 | A | O (grave) | 210 | O |
| A (til)   | 195 | A | O (agudo) | 211 | O |
| A (trema) | 196 | A | O (circ.) | 212 | O |
| A (anel)  | 197 | A | O (til)   | 213 | O |
| E (grave) | 200 | E | O (trema) | 214 | O |
| E (agudo) | 201 | E | O (barra) | 216 | O |
| E (circ.) | 202 | E | U (grave) | 217 | U |
| E (trema) | 203 | E | U (agudo) | 218 | U |
| I (grave) | 204 | I | U (circ.) | 219 | U |
| I (agudo) | 205 | I | U (trema) | 220 | U |
|           |     |   | Y (agudo) | 221 | Y |

> **Nota:** O caractere `Ç` (chr 199) **nao** e normalizado nesta etapa. Ele e preservado para ser tratado pela regra `Ç -> S` na funcao `foneticabr`.

### Funcao `foneticabr`

**Proposito:** Converter o texto normalizado em sua representacao fonetica brasileira.

**Etapas:**
1. Chama `normalize()` para limpar a entrada
2. Aplica 51 regras de substituicao fonetica (ver tabela abaixo)
3. Elimina consoantes finais de palavra: S, Z, R, M, N, AO, L
4. Remove todas as ocorrencias da letra H
5. Reduz letras consecutivas duplicadas (ex: SS -> S, RR -> R, AAA -> A)

---

## Tabela Completa de Regras Foneticas

As 51 regras sao aplicadas na ordem listada. **A ordenacao e critica** — regras de padroes mais longos (multi-caractere) devem preceder padroes mais curtos para evitar conflitos.

### Encontros Consonantais com B

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 1 | BL | B | BLUSA | BUSA |
| 2 | BR | B | BRASIL | BASIR |

### Cedilha

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 3 | Ç | S | Fonologia pt-BR | AÇUCAR | ASUKAR |

### Regras com C

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 4 | CHR | KR | CHRISTIANO | KRISTIANO |
| 5 | CA | K | CARLOS | KARROS |
| 6 | SCE | SE | NASCER | NASER |
| 7 | SCI | SI | DESCIDA | DESIDA |
| 8 | CE | S | CESAR | SESAR |
| 9 | CH | S | CHAVE | SAVE |
| 10 | CI | S | CIDADE | SIDADE |
| 11 | CK | K | BECKHAM | BEKAM |
| 12 | CO | K | CORREA | KOREA |
| 13 | CS | S | - | - |
| 14 | CT | T | FACTO | FATO |
| 15 | CU | K | CURITIBA | KURITIBA |
| 16 | C | K | CARRO | KARO |

> **SCE/SCI (novas):** Baseadas nos digrafos do portugues onde SC antes de E/I tem som de /s/ (o C e silencioso). Fonte: ortografia da lingua portuguesa, BuscaBR.

### Regras com G

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 17 | GE | J | GENTE | JEMTE |
| 18 | GI | J | GIRAFA | JIRAFA |
| 19 | GL | G | GLÓRIA | GORIA |
| 20 | GM | M | DOGMA | DOMA |
| 21 | GR | G | GRANDE | GAMDE |

### Regras com L

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 22 | LH | L | FILHO | FILO |
| 23 | LT | T | ALTO | ATO |
| 24 | L | R | SILVA | SIRVA |

### Regras com M

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 25 | MD | M | - | - |
| 26 | MG | G | - | - |
| 27 | MJ | J | - | - |

### Regras com N

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 28 | NG | G | ANGOLA | AGORA |
| 29 | NH | N | NINHO | NINO |
| 30 | NJ | J | NINJA | MIJA |
| 31 | N | M | NOME | MOME |

> **Ordenacao critica:** As regras `NG`, `NH` e `NJ` devem preceder `N -> M` para que os digrafos sejam processados antes da substituicao generica.

### Regras com P

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 32 | PH | F | PHELIPE | FERIPE |
| 33 | PR | P | PRETO | PETO |

### Regras com Q

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 34 | QUE | KE | Digrafo pt-BR | QUEIJO | KEIJO |
| 35 | QUI | KI | Digrafo pt-BR | QUILOMBO | KIROMBO |
| 36 | Q | K | - | QUATRO | KUATRO |

> **QUE/QUI (novas):** Na ortografia portuguesa, o U em QU antes de E/I e silencioso (digrafo). "QUEIJO" soa como "KEIJO", nao "KUEIJO". Fonte: fonologia da lingua portuguesa, Metaphone-ptBR.

### Regras com R

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 37 | RG | G | - | - |
| 38 | RJ | J | - | - |
| 39 | RM | M | ARMANDO | AMANDO |
| 40 | RS | S | - | - |
| 41 | RT | T | PARTO | PATO |

> **RM -> M (corrigido):** Anteriormente mapeava `RM -> SM` (incorreto). Corrigido para `RM -> M` conforme padrao BuscaBR.

### Regras com S

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 42 | SM | M | BuscaBR | ESMERALDA | EMERARDA |
| 43 | ST | T | - | ESTRADA | ETADA |

> **SM -> M (nova):** Regra presente no BuscaBR e ausente na versao original. Reduz SM ao som nasal M.

### Regras com T

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 44 | TH | T | BuscaBR/Metaphone | THEATRO | TEATRO |
| 45 | TL | T | - | ATLAS | ATAS |
| 46 | TR | T | - | ESTRADA | ETADA |
| 47 | TS | S | - | - | - |

> **TH -> T (nova):** Para palavras historicas e estrangeiras onde TH tem som de T em portugues (THEATRO, THOMAS, THIAGO). Fonte: BuscaBR, Metaphone-ptBR.

### Letras Estrangeiras

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 48 | W | U | WILSON | UIRSON |
| 49 | X | S | XAVIER | SAVIER |
| 50 | Y | I | YURI | IURI |
| 51 | Z | S | FAZENDA | FASENDA |

### Eliminacao de Terminacoes

Apos as substituicoes, sao removidas as consoantes finais de cada palavra:

| Terminacao | Exemplo | Antes | Depois |
|-----------|---------|-------|--------|
| S | CARLOS | KARO**S** | KARO |
| Z | GONZALEZ | GOMSARE**S** | GOMSARE |
| R | NASCER | NASE**R** | NASE |
| M | ARMANDO | - | - |
| N | - | - | - |
| AO | JOAO | JO**AO** | JO |
| L | BRASIL | BASIR | BASI |

### Pos-processamento

| Etapa | Descricao | Exemplo |
|-------|-----------|---------|
| Remocao de H | Remove todas as ocorrencias de H | BAHIA -> BAIA |
| Reducao de duplicatas | `(.)\1+` -> `\1` (regex) | ANNA -> ANA, AAALPHA -> ALFA |

---

## Etapas do Algoritmo

Resumo sequencial de todas as etapas executadas pela funcao `foneticabr`:

```
ENTRADA: "João da Silva e Oliveira"
    |
    v
[1] UPPER()         -> "JOÃO DA SILVA E OLIVEIRA"
    |
[2] Remover acentos -> "JOAO DA SILVA E OLIVEIRA"
    (Ç preservado)
    |
[3] TRIM + espaços  -> "JOAO DA SILVA E OLIVEIRA"
    |
[4] Regex limpeza   -> "JOAO DA SILVA E OLIVEIRA"
    |
[5] 51 substituicoes foneticas (em ordem)
    |                  L->R: SIRVA, ORIVEIRA
    v
    "JOAO DA SIRVA E ORIVEIRA"
    |
[6] Remover terminacoes (S,Z,R,M,N,AO,L)
    |                  AO final em JOAO -> JO
    v
    "JO DA SIRVA E ORIVEIRA"
    |
[7] Remover H        -> "JO DA SIRVA E ORIVEIRA"
    |
[8] Remover duplicatas -> "JO DA SIRVA E ORIVEIRA"
    |
    v
SAIDA: "JO DA SIRVA E ORIVEIRA"
```

---

## Instalacao

### Pre-requisitos

- Oracle Database 9i ou superior
- Acesso para criar packages no schema desejado

### Passos

1. Execute o script de especificacao do package:

```sql
@PKG_UTIL_SPEC.sql
```

2. Execute o script do corpo do package:

```sql
@PKG_UTIL_BODY.sql
```

3. Verifique a compilacao:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_name = 'PKG_UTIL'
  AND object_type = 'PACKAGE BODY';
```

O status deve retornar `VALID`.

---

## Utilizacao

### Chamada basica

```sql
SELECT pkg_util.foneticabr('JOAO DA SILVA') FROM DUAL;
-- Resultado: JO DA SIRVA
```

### Busca fonetica em tabela

```sql
SELECT nome
FROM clientes
WHERE pkg_util.foneticabr(nome) = pkg_util.foneticabr('RAFAEL OLIVEIRA');
```

Esta consulta retornara registros como "RAPHAEL OLIVEIRA", "RAFAEL ORIVEIRA", etc.

### Criacao de indice fonetico (recomendado para performance)

```sql
-- Coluna virtual com o codigo fonetico
ALTER TABLE clientes ADD nome_fonetico VARCHAR2(3000)
  GENERATED ALWAYS AS (pkg_util.foneticabr(nome)) VIRTUAL;

-- Indice sobre a coluna virtual
CREATE INDEX idx_clientes_fonetico ON clientes(nome_fonetico);

-- Consulta otimizada
SELECT nome
FROM clientes
WHERE nome_fonetico = pkg_util.foneticabr('RAFAEL');
```

> **Nota:** Colunas virtuais com indices sao suportadas a partir do Oracle 11g.

---

## Testes

O arquivo `Script_Teste.sql` contem um conjunto de testes automatizados organizados em 3 categorias:

### Executar testes

```sql
SET SERVEROUTPUT ON;
@Script_Teste.sql
```

### Categorias de teste

| Categoria | Quantidade | Descricao |
|-----------|-----------|-----------|
| Testes basicos | 3 | Funcionalidade geral, acentos, duplicatas |
| Regras originais | 7 | LH, NH, NG, Z, PH, W, Y, CH, GE, CE |
| Novas regras | 9 | QUE/QUI, SCE/SCI, TH, RM, SM |
| Equivalencias foneticas | 7 | Comparacao de pares (RAFAEL~RAPHAEL, etc.) |
| **Total** | **27** | |

### Saida esperada

```
=== TESTES BASICOS ===
OK   [basico] JOAO DA SILVA E OLIVEIRA => JO DA SIRVA E ORIVEIRA
OK   [acento-a] JOSE => JOSE
OK   [duplicata] ANNA => ANA

=== REGRAS ORIGINAIS ===
OK   [LH->L] FILHO => FIRO
OK   [NH->N (fix)] NINHO => NINO
...

=== RESULTADO: 27/27 testes OK ===
```

---

## Compatibilidade

| Versao Oracle | Status |
|--------------|--------|
| Oracle 9i | Compativel |
| Oracle 10g | Compativel |
| Oracle 11g | Compativel |
| Oracle 12c | Compativel |
| Oracle 18c | Compativel |
| Oracle 19c | Compativel |
| Oracle 21c | Compativel |
| Oracle 23ai | Compativel |

> A funcao utiliza apenas recursos basicos de PL/SQL (`REPLACE`, `REGEXP_REPLACE`, `REGEXP_COUNT`, `REGEXP_SUBSTR`). Funcoes `REGEXP_*` requerem Oracle 10g+.

---

## Estrutura do Projeto

```
FoneticaBR/
  PKG_UTIL_SPEC.sql    -- Especificacao do package (interface publica)
  PKG_UTIL_BODY.sql    -- Corpo do package (implementacao)
  Script_Teste.sql     -- Suite de testes automatizados (27 casos)
  README.md            -- Esta documentacao
  .gitignore           -- Ignora arquivos compilados Oracle Forms (*.fmx, *.mmx, *.plx)
```

---

## Bibliografia

1. **BISOL, Leda** (1996). _Introducao a estudos de fonologia do portugues brasileiro_. Porto Alegre: EDIPUCRS. ISBN 85-7430-957-5.

2. **JORGE, Fred** (2007). _BuscaBR - Algoritmo de Busca Fonetica para o Portugues Brasileiro_. Disponivel em: http://www.linhadecodigo.com.br/artigo/2237/implementando-algoritmo-buscabr.aspx

3. **JORDAO, Carlos**. _Metaphone-ptBR - Adaptacao do Metaphone para Portugues Brasileiro_. Disponivel em: https://github.com/carlosjordao/metaphone-ptbr

4. **RIBEIRO, Israel**. _Algoritmo de Consulta Fonetica Soundex para Lojas Virtuais_. Universidade Federal do Parana (UFPR). Disponivel em: https://acervodigital.ufpr.br/xmlui/bitstream/handle/1884/50408/

5. **Wikipedia**. _Fonologia da lingua portuguesa_. Disponivel em: https://pt.wikipedia.org/wiki/Fonologia_da_l%C3%ADngua_portuguesa

6. **InCor/FMUSP**. _Implementacao de Funcao para Fonetizacao em Portugues - SGBD Oracle_. Disponivel em: https://www.devmedia.com.br/sgbd-oracle-implementacao-de-funcao-para-fonetizacao-em-portugues/6300

7. **SBC**. _Adaptacao do Metaphone para o Portugues Brasileiro_. Escola Regional de Banco de Dados. Disponivel em: https://sol.sbc.org.br/index.php/erbd/article/download/3035/2997/

---

## Historico de Alteracoes

### v2.0 (2026)

**Correcoes criticas:**
- Corrigido off-by-one no loop de substituicoes: ultimo elemento (Z->S) nao era processado
- Corrigida ordenacao N->M: regra N era aplicada antes de NH/NG/NJ, impedindo o funcionamento dos digrafos
- Corrigido conflito Ç: funcao `normalize` convertia Ç->C, tornando a regra Ç->S do `foneticabr` codigo morto
- Adicionado chr(192) 'A grave': caractere estava ausente (chr(198) duplicado em seu lugar)
- Corrigido RM->SM para RM->M (padrao BuscaBR)

**Novas regras foneticas (baseadas em pesquisa):**
- QUE/QUI -> KE/KI: U silencioso no digrafo QU antes de E/I
- SCE/SCI -> SE/SI: C silencioso no digrafo SC antes de E/I
- TH -> T: palavras historicas e estrangeiras
- SM -> M: regra BuscaBR ausente na versao original

**Melhorias tecnicas:**
- Reducao de duplicatas via regex `(.)\1+` (suporta 3+ caracteres consecutivos)
- Script de teste reescrito: 27 casos automatizados com comparacao de resultado
- Documentacao completa com metodologia, tabela de regras e bibliografia

### v1.0 (2019)

- Versao inicial por Maxwell Oliveira
- 45 regras de substituicao fonetica
- Baseada na obra de Leda Bisol (1996)

---

## Licenca

Este projeto e de codigo aberto. Consulte o repositorio para detalhes da licenca.

---

**Autor:** Maxwell Oliveira (2019) | **Contribuicoes:** Pesquisa e melhorias (2026)
