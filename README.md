### Mini Projeto SCTEC Módulo 02 - Hicaro Calliari Bottenberg - ANÁLISE DE DADOS T2

<img width="959" height="815" alt="image" src="https://github.com/user-attachments/assets/6202e4de-6521-4fcb-aaae-54d57a2a8fd9" />

## Como executar este projeto

1. **Clone este repositório** em seu computador.

2. **Abra o MySQL Workbench** e conecte-se ao banco de dados que será utilizado no projeto.

3. **Execute o arquivo `01-carga-staging.sql`** no MySQL Workbench.
   Este arquivo é responsável pela **criação e carga dos dados** nas tabelas de staging:

   * `stg_pedido`
   * `stg_loja`
   * `stg_loja_praca`

4. **Execute o arquivo `02-dimensoes-prontas.sql`** no MySQL Workbench.
   Este arquivo é responsável pela **criação e carga inicial** das tabelas:

   * `dim_tempo`
   * `dim_loja`

   Além disso, realiza a **criação** das seguintes tabelas:

   * `dim_categoria`
   * `dim_praca`
   * `bridge_loja_praca`
   * `fato_pedido`

5. **Execute o arquivo `03-dimensoes.sql`** no MySQL Workbench.
   Este arquivo é responsável pela **padronização e carga** das tabelas:

   * `dim_categoria`
   * `dim_praca`
   * `bridge_loja_praca`


## Etapa 01 Diagnóstico da origem

## Inconsistências identificadas nos dados

Durante a etapa de análise da tabela `stg_pedido`, foram identificadas inconsistências relacionadas à **padronização, qualidade e preenchimento dos dados**. Os principais problemas encontrados foram:

### 1. Coluna `CategoriaProduto`

Foram identificadas diferentes grafias para categorias que representam o mesmo tipo de produto. Há variações de abreviações, utilização de letras maiúsculas e minúsculas, singular/plural e diferentes formas de escrita.

**Valores encontrados:**

* `MEDICAMENTO`
* `Medicamentos`
* `Med.`
* `RACAO`
* `Racao Seca`
* `Racao Medicamentosa`
* `Rac.`
* `ACESSORIO`
* `Acessorios`
* `Servico`
* `Servicos`
* `brinquedo`
* `Brinquedos`
* `Petiscos`
* `Petisco`
* `Hig.`
* `Higiene`
* `Higiene e Beleza`

Essas variações dificultam a realização de agrupamentos e análises, pois registros pertencentes à mesma categoria podem ser interpretados como categorias distintas.

---

### 2. Coluna `Loja-Nome`

Foram identificadas diversas inconsistências na identificação das lojas, principalmente relacionadas à **padronização de maiúsculas e minúsculas, espaços em branco no início do texto, acentuação, abreviações e utilização da sigla `/SC`**.

Também foram identificadas **3 ocorrências com string vazia (`''`)**.

**Exemplos de variações que representam a mesma loja:**

```text
' Pata Amiga Blumenau Centro'
'pata amiga blumenau centro'
'Pata Amiga Blumenau Centro/SC'
'PATA AMIGA GASPAR'
' Pata Amiga Gaspar'
'PATA AMIGA JOINVILLE SUL'
'Pata Amiga Joinville Sul/SC'
'Pata Amiga Jaraguá do Sul'
'Pata Amiga Jgua do Sul'
'Pata Amiga Florianopolis Norte/SC'
'Pata Amiga Florianópolis Norte'
'Pata Amiga Floripa Norte'
'Pata Amiga São Jose Kobrasol'
'Pata Amiga Sao Jose Kobrasol/SC'
```

Essas diferenças podem gerar duplicidade no momento de contabilizar vendas por loja e comprometer análises de desempenho, faturamento e quantidade de pedidos por unidade.

---

### 3. Coluna `Cod Loja`

Foram identificados **1.575 registros preenchidos como string vazia (`''`)**.

A ausência desse código dificulta a identificação e o relacionamento dos pedidos com suas respectivas lojas, podendo comprometer análises e relacionamentos entre tabelas.

---

### 4. Coluna `Bairro Entrega`

Foram identificados **311 registros preenchidos como string vazia (`''`)**.

A ausência dessa informação limita análises geográficas relacionadas à distribuição dos pedidos e à concentração de entregas por região.

---

### 5. Colunas de valores

Nas colunas:

* `ValorBrutoPedido(R$)`
* `Valor Desconto (R$)`
* `ValorLiquidoPedido(R$)`

foram identificadas inconsistências na **formatação dos valores monetários**.

Entre os problemas encontrados estão:

* registros contendo o símbolo de moeda (`R$`);
* registros contendo apenas o valor numérico;
* diferentes formatos de pontuação;
* ausência de padronização entre separadores decimais e de milhares.

Essa falta de padronização pode dificultar a conversão dos valores para tipos numéricos e provocar erros ou inconsistências durante os cálculos e análises.

---

### 6. Coluna `CanalPedido`

Também foram identificadas inconsistências na padronização dos valores da coluna `CanalPedido`.

A existência de diferentes grafias ou formatos para um mesmo canal pode gerar categorias duplicadas durante agrupamentos e análises, comprometendo indicadores relacionados à origem dos pedidos.

