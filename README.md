# FoneticaBR

[![Oracle PL/SQL](https://img.shields.io/badge/Oracle-PL%2FSQL-F80000?logo=oracle&logoColor=white)](https://www.oracle.com/database/)
[![Licença](https://img.shields.io/badge/licença-MIT-blue.svg)](#licença)
[![Versão](https://img.shields.io/badge/versão-2.0-green.svg)](#histórico-de-alterações)
[![pt-BR](https://img.shields.io/badge/idioma-pt--BR-009c3b.svg)](#)

Pesquisa Fonética para o padrão Brasileiro - PL/SQL (Oracle Database).

Esta função retorna uma string fonética de um texto passado como parâmetro, podendo ser utilizada para a busca de nomes com sonoridades próximas, totalmente voltada para o português brasileiro (pt-BR).

```sql
SELECT pkg_util.foneticabr('JOAO DA SILVA') FROM DUAL;
-- Resultado: JO DA SIRVA
```

---

## Sumário

- [Objetivo](#objetivo)
- [Metodologia](#metodologia)
  - [Fundamentação Linguística](#fundamentação-linguística)
  - [Algoritmos de Referência](#algoritmos-de-referência)
  - [Abordagem do FoneticaBR](#abordagem-do-foneticabr)
- [Arquitetura](#arquitetura)
  - [Função normalize](#função-normalize)
  - [Função foneticabr](#função-foneticabr)
- [Tabela Completa de Regras Fonéticas](#tabela-completa-de-regras-fonéticas)
- [Etapas do Algoritmo](#etapas-do-algoritmo)
- [Instalação](#instalação)
- [Utilização](#utilização)
- [Testes](#testes)
- [Compatibilidade](#compatibilidade)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Como Contribuir](#como-contribuir)
- [Bibliografia](#bibliografia)
- [Histórico de Alterações](#histórico-de-alterações)

---

## Objetivo

Prover uma função PL/SQL capaz de gerar códigos fonéticos para textos em português brasileiro, permitindo:

- Busca por nomes com grafias diferentes mas pronúncia semelhante (ex: Rafael / Raphael)
- Comparação fonética entre palavras (ex: Cecília / Sesília)
- Indexação fonética em bases de dados Oracle para consultas _fuzzy_

O algoritmo SOUNDEX, registrado por Robert Russell e Margaret Odell em 1918 nos Estados Unidos, foi concebido para a língua inglesa e não atende adequadamente as particularidades do português brasileiro. O FoneticaBR foi desenvolvido como alternativa específica para o pt-BR.

---

## Metodologia

### Fundamentação Linguística

O projeto tem como base a fonologia do português brasileiro, com referência principal na obra de **Leda Bisol (1996)** - _"Introdução a estudos de fonologia do português brasileiro"_, que cataloga os fonemas e processos fonológicos do idioma.

A língua portuguesa apresenta desafios específicos para algoritmos fonéticos:

| Desafio | Exemplo | Explicação |
|---------|---------|------------|
| Uma letra com múltiplos fonemas | X | "exame" (som de Z), "táxi" (som de KS), "enxame" (som de CH) |
| Múltiplas letras com mesmo fonema | S, SS, C, Ç | Todos produzem o som /s/ em contextos específicos |
| Dígrafos consonantais | LH, NH, CH, QU, GU | Duas letras representando um único som |
| Dígrafos com letra muda | SCE, SCI, QUE, QUI | O C em "nascer" e o U em "queijo" são silenciosos |
| Letras estrangeiras | W, Y, K | Usadas em nomes próprios e estrangeirismos |
| Consoantes finais mudas | S, Z, R, M, N, L | Frequentemente ignoradas ou alteradas na fala |

### Algoritmos de Referência

O FoneticaBR foi desenvolvido e aprimorado com base no estudo comparativo dos seguintes algoritmos:

| Algoritmo | Autor(es) | Ano | Linguagem | Referência |
|-----------|-----------|-----|-----------|------------|
| SOUNDEX | Robert Russell, Margaret Odell | 1918 | - | Patente US 1261167 (inglês) |
| BuscaBR | Fred Jorge; Marcos Rodrigues; Gabriel Sobrinho | 2007-2011 | PL/SQL | linhadecodigo.com.br |
| Metaphone-ptBR | Carlos Jordão | - | PHP/Python | github.com/carlosjordao/metaphone-ptbr |
| MTFN | Ruliana | - | Ruby | github.com/ruliana/MTFN |
| Fonetização InCor/USP | Instituto do Coração - FMUSP | - | Java | devmedia.com.br |
| FoneticaBR (este projeto) | Maxwell Oliveira | 2019 | PL/SQL | github.com/Maxwbh/FoneticaBR |

### Abordagem do FoneticaBR

O FoneticaBR adota uma abordagem distinta dos demais algoritmos:

| Característica | FoneticaBR | BuscaBR | Metaphone-ptBR |
|---------------|------------|---------|----------------|
| Preserva vogais | Sim | Não (elimina) | Não (elimina) |
| Linguagem nativa | PL/SQL | PL/SQL | PHP/Python |
| Legibilidade do resultado | Alta | Baixa | Baixa |
| Regras fonéticas | 51 | ~30 | ~40 |
| Contexto de posição | Não | Não | Sim (parcial) |

**Escolha de preservar vogais:** enquanto BuscaBR e Metaphone-ptBR eliminam todas as vogais para gerar códigos compactos, o FoneticaBR as preserva, resultando em saídas mais legíveis e adequadas para nomes brasileiros com alta incidência de vogais.

Exemplo comparativo:

```
Entrada:     "JOAO DA SILVA E OLIVEIRA"
FoneticaBR:  "JO DA SIRVA E ORIVEIRA"    (legível)
BuscaBR:     "J D SRV ORVR"              (compacto)
```

---

## Arquitetura

O projeto é implementado como um **Oracle PL/SQL Package** (`PKG_UTIL`) com duas funções:

```
PKG_UTIL
  |-- normalize(str1)     -- Função interna: normalização de caracteres
  |-- foneticabr(str1)    -- Função pública: conversão fonética
```

### Função `normalize`

**Propósito:** Preparar o texto de entrada removendo acentos, caracteres especiais e padronizando a caixa.

**Etapas:**
1. Converte para maiúsculas (`UPPER`)
2. Substitui caracteres acentuados por seus equivalentes ASCII (30 mapeamentos)
3. Remove espaços duplicados
4. Remove caracteres inválidos via regex, mantendo: `A-Z`, `0-9`, `Ç`, `&`, `@`, `_`, espaço, `+`, `-`

**Mapeamento de caracteres acentuados:**

| Caractere | Chr | Substituto | Caractere | Chr | Substituto |
|-----------|-----|-----------|-----------|-----|-----------|
| À (grave) | 192 | A | Î (circ.) | 206 | I |
| Æ (lig.)  | 198 | A | Ï (trema) | 207 | I |
| ß (lig.)  | 223 | B | Ð (ETH)   | 208 | D |
| Á (agudo) | 193 | A | Ñ (til)   | 209 | N |
| Â (circ.) | 194 | A | Ò (grave) | 210 | O |
| Ã (til)   | 195 | A | Ó (agudo) | 211 | O |
| Ä (trema) | 196 | A | Ô (circ.) | 212 | O |
| Å (anel)  | 197 | A | Õ (til)   | 213 | O |
| È (grave) | 200 | E | Ö (trema) | 214 | O |
| É (agudo) | 201 | E | Ø (barra) | 216 | O |
| Ê (circ.) | 202 | E | Ù (grave) | 217 | U |
| Ë (trema) | 203 | E | Ú (agudo) | 218 | U |
| Ì (grave) | 204 | I | Û (circ.) | 219 | U |
| Í (agudo) | 205 | I | Ü (trema) | 220 | U |
|           |     |   | Ý (agudo) | 221 | Y |

> **Nota:** O caractere `Ç` (chr 199) **não** é normalizado nesta etapa. Ele é preservado para ser tratado pela regra `Ç -> S` na função `foneticabr`.

### Função `foneticabr`

**Propósito:** Converter o texto normalizado em sua representação fonética brasileira.

**Etapas:**
1. Chama `normalize()` para limpar a entrada
2. Aplica 51 regras de substituição fonética (ver tabela abaixo)
3. Elimina consoantes finais de palavra: S, Z, R, M, N, AO, L
4. Remove todas as ocorrências da letra H
5. Reduz letras consecutivas duplicadas (ex: SS -> S, RR -> R, AAA -> A)

---

## Tabela Completa de Regras Fonéticas

As 51 regras são aplicadas na ordem listada. **A ordenação é crítica** — regras de padrões mais longos (multi-caractere) devem preceder padrões mais curtos para evitar conflitos.

### Encontros Consonantais com B

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 1 | BL | B | BLUSA | BUSA |
| 2 | BR | B | BRASIL | BASIR |

### Cedilha

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 3 | Ç | S | Fonologia pt-BR | AÇÚCAR | ASÚKAR |

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

> **SCE/SCI (novas):** Baseadas nos dígrafos do português onde SC antes de E/I tem som de /s/ (o C é silencioso). Fonte: ortografia da língua portuguesa, BuscaBR.

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

> **Ordenação crítica:** As regras `NG`, `NH` e `NJ` devem preceder `N -> M` para que os dígrafos sejam processados antes da substituição genérica.

### Regras com P

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 32 | PH | F | PHELIPE | FERIPE |
| 33 | PR | P | PRETO | PETO |

### Regras com Q

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 34 | QUE | KE | Dígrafo pt-BR | QUEIJO | KEIJO |
| 35 | QUI | KI | Dígrafo pt-BR | QUILOMBO | KIROMBO |
| 36 | Q | K | - | QUATRO | KUATRO |

> **QUE/QUI (novas):** Na ortografia portuguesa, o U em QU antes de E/I é silencioso (dígrafo). "QUEIJO" soa como "KEIJO", não "KUEIJO". Fonte: fonologia da língua portuguesa, Metaphone-ptBR.

### Regras com R

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 37 | RG | G | - | - |
| 38 | RJ | J | - | - |
| 39 | RM | M | ARMANDO | AMANDO |
| 40 | RS | S | - | - |
| 41 | RT | T | PARTO | PATO |

> **RM -> M (corrigido):** Anteriormente mapeava `RM -> SM` (incorreto). Corrigido para `RM -> M` conforme padrão BuscaBR.

### Regras com S

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 42 | SM | M | BuscaBR | ESMERALDA | EMERARDA |
| 43 | ST | T | - | ESTRADA | ETADA |

> **SM -> M (nova):** Regra presente no BuscaBR e ausente na versão original. Reduz SM ao som nasal M.

### Regras com T

| # | De | Para | Fonte | Exemplo | Resultado |
|---|-----|------|-------|---------|-----------|
| 44 | TH | T | BuscaBR/Metaphone | THEATRO | TEATRO |
| 45 | TL | T | - | ATLAS | ATAS |
| 46 | TR | T | - | ESTRADA | ETADA |
| 47 | TS | S | - | - | - |

> **TH -> T (nova):** Para palavras históricas e estrangeiras onde TH tem som de T em português (THEATRO, THOMAS, THIAGO). Fonte: BuscaBR, Metaphone-ptBR.

### Letras Estrangeiras

| # | De | Para | Exemplo | Resultado |
|---|-----|------|---------|-----------|
| 48 | W | U | WILSON | UIRSON |
| 49 | X | S | XAVIER | SAVIER |
| 50 | Y | I | YURI | IURI |
| 51 | Z | S | FAZENDA | FASENDA |

### Eliminação de Terminações

Após as substituições, são removidas as consoantes finais de cada palavra:

| Terminação | Exemplo | Antes | Depois |
|-----------|---------|-------|--------|
| S | CARLOS | KARO**S** | KARO |
| Z | GONZALEZ | GOMSARE**S** | GOMSARE |
| R | NASCER | NASE**R** | NASE |
| M | ARMANDO | - | - |
| N | - | - | - |
| AO | JOAO | JO**AO** | JO |
| L | BRASIL | BASIR | BASI |

### Pós-processamento

| Etapa | Descrição | Exemplo |
|-------|-----------|---------|
| Remoção de H | Remove todas as ocorrências de H | BAHIA -> BAIA |
| Redução de duplicatas | `(.)\1+` -> `\1` (regex) | ANNA -> ANA, AAALPHA -> ALFA |

---

## Etapas do Algoritmo

Resumo sequencial de todas as etapas executadas pela função `foneticabr`:

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
[5] 51 substituições fonéticas (em ordem)
    |                  L->R: SIRVA, ORIVEIRA
    v
    "JOAO DA SIRVA E ORIVEIRA"
    |
[6] Remover terminações (S,Z,R,M,N,AO,L)
    |                  AO final em JOAO -> JO
    v
    "JO DA SIRVA E ORIVEIRA"
    |
[7] Remover H        -> "JO DA SIRVA E ORIVEIRA"
    |
[8] Remover duplicatas -> "JO DA SIRVA E ORIVEIRA"
    |
    v
SAÍDA: "JO DA SIRVA E ORIVEIRA"
```

---

## Instalação

### Pré-requisitos

- Oracle Database 9i ou superior
- Acesso para criar packages no schema desejado

### Passos

1. Execute o script de especificação do package:

```sql
@PKG_UTIL_SPEC.sql
```

2. Execute o script do corpo do package:

```sql
@PKG_UTIL_BODY.sql
```

3. Verifique a compilação:

```sql
SELECT object_name, status
FROM user_objects
WHERE object_name = 'PKG_UTIL'
  AND object_type = 'PACKAGE BODY';
```

O status deve retornar `VALID`.

---

## Utilização

### Chamada básica

```sql
SELECT pkg_util.foneticabr('JOAO DA SILVA') FROM DUAL;
-- Resultado: JO DA SIRVA
```

### Busca fonética em tabela

```sql
SELECT nome
FROM clientes
WHERE pkg_util.foneticabr(nome) = pkg_util.foneticabr('RAFAEL OLIVEIRA');
```

Esta consulta retornará registros como "RAPHAEL OLIVEIRA", "RAFAEL ORIVEIRA", etc.

### Criação de índice fonético (recomendado para performance)

```sql
-- Coluna virtual com o código fonético
ALTER TABLE clientes ADD nome_fonetico VARCHAR2(3000)
  GENERATED ALWAYS AS (pkg_util.foneticabr(nome)) VIRTUAL;

-- Índice sobre a coluna virtual
CREATE INDEX idx_clientes_fonetico ON clientes(nome_fonetico);

-- Consulta otimizada
SELECT nome
FROM clientes
WHERE nome_fonetico = pkg_util.foneticabr('RAFAEL');
```

> **Nota:** Colunas virtuais com índices são suportadas a partir do Oracle 11g.

---

## Testes

O arquivo `Script_Teste.sql` contém um conjunto de testes automatizados organizados em 4 categorias:

### Executar testes

```sql
SET SERVEROUTPUT ON;
@Script_Teste.sql
```

### Categorias de teste

| Categoria | Quantidade | Descrição |
|-----------|-----------|-----------|
| Testes básicos | 3 | Funcionalidade geral, acentos, duplicatas |
| Regras originais | 10 | LH, NH, NG, Z, PH, W, Y, CH, GE, CE |
| Novas regras | 9 | QUE/QUI, SCE/SCI, TH, RM, SM |
| Equivalências fonéticas | 7 | Comparação de pares (RAFAEL~RAPHAEL, etc.) |
| **Total** | **29** | |

### Saída esperada

```
=== TESTES BASICOS ===
OK   [basico] JOAO DA SILVA E OLIVEIRA => JO DA SIRVA E ORIVEIRA
OK   [acento-a] JOSE => JOSE
OK   [duplicata] ANNA => ANA

=== REGRAS ORIGINAIS ===
OK   [LH->L] FILHO => FIRO
OK   [NH->N (fix)] NINHO => NINO
...

=== RESULTADO: 29/29 testes OK ===
```

---

## Compatibilidade

| Versão Oracle | Status |
|--------------|--------|
| Oracle 9i | Compatível |
| Oracle 10g | Compatível |
| Oracle 11g | Compatível |
| Oracle 12c | Compatível |
| Oracle 18c | Compatível |
| Oracle 19c | Compatível |
| Oracle 21c | Compatível |
| Oracle 23ai | Compatível |

> A função utiliza apenas recursos básicos de PL/SQL (`REPLACE`, `REGEXP_REPLACE`, `REGEXP_COUNT`, `REGEXP_SUBSTR`). Funções `REGEXP_*` requerem Oracle 10g+.

---

## Estrutura do Projeto

```
FoneticaBR/
  PKG_UTIL_SPEC.sql    -- Especificação do package (interface pública)
  PKG_UTIL_BODY.sql    -- Corpo do package (implementação)
  Script_Teste.sql     -- Suíte de testes automatizados (29 casos)
  README.md            -- Esta documentação
  .gitignore           -- Ignora arquivos compilados Oracle Forms (*.fmx, *.mmx, *.plx)
```

---

## Como Contribuir

Contribuições são bem-vindas! Se você deseja colaborar com o projeto:

1. Faça um **fork** do repositório
2. Crie uma branch para sua feature (`git checkout -b minha-feature`)
3. Faça commit das alterações (`git commit -m 'Adiciona nova regra fonética'`)
4. Envie para a branch (`git push origin minha-feature`)
5. Abra um **Pull Request**

### Sugestões de contribuição

- Adicionar novas regras fonéticas para padrões regionais brasileiros
- Portar a função para outras linguagens (T-SQL, MySQL, PostgreSQL)
- Adicionar suporte a nomes de origem indígena e africana
- Melhorar o tratamento contextual da letra X (múltiplos fonemas)
- Criar benchmark comparativo com outros algoritmos (BuscaBR, Metaphone-ptBR)

---

## Bibliografia

1. **BISOL, Leda** (1996). _Introdução a estudos de fonologia do português brasileiro_. Porto Alegre: EDIPUCRS. ISBN 85-7430-957-5.

2. **JORGE, Fred** (2007). _BuscaBR - Algoritmo de Busca Fonética para o Português Brasileiro_. Disponível em: http://www.linhadecodigo.com.br/artigo/2237/implementando-algoritmo-buscabr.aspx

3. **JORDÃO, Carlos**. _Metaphone-ptBR - Adaptação do Metaphone para Português Brasileiro_. Disponível em: https://github.com/carlosjordao/metaphone-ptbr

4. **RIBEIRO, Israel**. _Algoritmo de Consulta Fonética Soundex para Lojas Virtuais_. Universidade Federal do Paraná (UFPR). Disponível em: https://acervodigital.ufpr.br/xmlui/bitstream/handle/1884/50408/

5. **Wikipedia**. _Fonologia da língua portuguesa_. Disponível em: https://pt.wikipedia.org/wiki/Fonologia_da_l%C3%ADngua_portuguesa

6. **InCor/FMUSP**. _Implementação de Função para Fonetização em Português - SGBD Oracle_. Disponível em: https://www.devmedia.com.br/sgbd-oracle-implementacao-de-funcao-para-fonetizacao-em-portugues/6300

7. **SBC**. _Adaptação do Metaphone para o Português Brasileiro_. Escola Regional de Banco de Dados. Disponível em: https://sol.sbc.org.br/index.php/erbd/article/download/3035/2997/

---

## Histórico de Alterações

### v2.0 (2026)

**Correções críticas:**
- Corrigido off-by-one no loop de substituições: último elemento (Z->S) não era processado
- Corrigida ordenação N->M: regra N era aplicada antes de NH/NG/NJ, impedindo o funcionamento dos dígrafos
- Corrigido conflito Ç: função `normalize` convertia Ç->C, tornando a regra Ç->S do `foneticabr` código morto
- Adicionado chr(192) 'À': caractere estava ausente (chr(198) duplicado em seu lugar)
- Corrigido RM->SM para RM->M (padrão BuscaBR)

**Novas regras fonéticas (baseadas em pesquisa):**
- QUE/QUI -> KE/KI: U silencioso no dígrafo QU antes de E/I
- SCE/SCI -> SE/SI: C silencioso no dígrafo SC antes de E/I
- TH -> T: palavras históricas e estrangeiras
- SM -> M: regra BuscaBR ausente na versão original

**Melhorias técnicas:**
- Redução de duplicatas via regex `(.)\1+` (suporta 3+ caracteres consecutivos)
- Script de teste reescrito: 29 casos automatizados com comparação de resultado
- Documentação completa com metodologia, tabela de regras e bibliografia

### v1.0 (2019)

- Versão inicial por Maxwell Oliveira
- 45 regras de substituição fonética
- Baseada na obra de Leda Bisol (1996)

---

## Licença

Este projeto é de código aberto. Contribuições são bem-vindas.

---

**Autor:** Maxwell Oliveira (2019) | **Melhorias:** Pesquisa e correções (2026)
