### Mini Projeto SCTEC Módulo 02 - Hicaro Calliari Bottenberg - ANÁLISE DE DADOS T2

## Como executar este projeto

1. **Clone este repositório** em seu computador.

2. **Abra o MySQL Workbench** e conecte-se ao banco de dados que será utilizado no projeto.

3. **Execute o arquivo `01-carga-staging.sql`** no MySQL Workbench.
   Este arquivo é responsável pela **criação e carga dos dados** nas tabelas de staging:

   * `stg_pedido`
   * `stg_loja`
   * `stg_loja_praca`

Resultado que obtemos são as seguintes tabelas:

<img width="438" height="509" alt="image" src="https://github.com/user-attachments/assets/c1b34f18-d8db-4a19-91c7-76f3779d7b51" />


4. **Execute o arquivo `02-dimensoes-prontas.sql`** no MySQL Workbench.
   Este arquivo é responsável pela **criação e carga inicial** das tabelas:

   * `dim_tempo`
   * `dim_loja`
Resultado que obtemos são as seguintes tabelas:

<img width="323" height="320" alt="image" src="https://github.com/user-attachments/assets/04579539-bdd9-46e5-b69d-0f89ffcde73e" />


   Além disso, realiza a **criação** das seguintes tabelas:

   * `dim_categoria`
   * `dim_praca`
   * `bridge_loja_praca`
   * `fato_pedido`
Resultado que obtemos são as seguintes tabelas:

<img width="367" height="449" alt="image" src="https://github.com/user-attachments/assets/7bf2dec3-b8d8-408c-8821-814223e482a5" />

5. **Execute o arquivo `03-dimensoes.sql`** no MySQL Workbench.
   Este arquivo é responsável pela **padronização e carga** das tabelas:

   * `dim_categoria`
   * `dim_praca`
   * `bridge_loja_praca`
Resultado que obtemos são as seguintes tabelas:

<img width="362" height="322" alt="image" src="https://github.com/user-attachments/assets/167b8247-c450-4685-9756-aacc12f6bf34" />


## Etapa 01 Diagnóstico da origem

## Inconsistências identificadas nos dados

Durante a etapa de análise da tabela `stg_pedido`, foram identificadas inconsistências relacionadas à **padronização, qualidade e preenchimento dos dados**. Os principais problemas encontrados foram:

### 1. Coluna `CategoriaProduto`

Foram identificadas 18 diferentes grafias para categorias que representam o mesmo tipo de produto. Há variações de abreviações, utilização de letras maiúsculas e minúsculas, singular/plural e diferentes formas de escrita.

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

**Valores encontrados Após o tratamento:**
* `Nao Informado`
* `Medicamento`
* `Racao`
* `Acessorio`
* `Servico`
* `Brinquedo`
* `Higiene`
* `Petisco`

Essas variações difultavam a realização de agrupamentos e análises, pois registros pertencentes à mesma categoria podem ser interpretados como categorias distintas.

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

### 4. Coluna `Loja-Nome`
3 pedidos vieram sem Loja-Nome
Na dim_loja foi realizado o tratamento para "Não Informado"

### 5. Coluna `Bairro Entrega`

Foram identificados **311 registros preenchidos como string vazia (`''`)**.

A ausência dessa informação limita análises geográficas relacionadas à distribuição dos pedidos e à concentração de entregas por região.

---

### 6. Colunas de valores

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

### 7. Coluna `CanalPedido`

Também foram identificadas inconsistências na padronização dos valores da coluna `CanalPedido`.

A existência de diferentes grafias ou formatos para um mesmo canal pode gerar categorias duplicadas durante agrupamentos e análises, comprometendo indicadores relacionados à origem dos pedidos.

## Etapa 02 Tratamentos e Padronização

### 1. Máscara de datas

Nas colunas DtHoraPedido e DtHoraIntegracaoERP, foi aplicado o tratamento STR_TO_DATE(<coluna>, '%m/%d/%Y %h:%i %p') para converter os valores do formato original para o padrão de data e hora do MySQL.

Exemplo:

Original: 11/16/2023 02:30 PM
Após o tratamento: 2023-11-16 14:30:00

Os quatro marcos da entrega (Dt Separacao Estoque, DtNotaFiscal, Dt_Despacho_Transportadora, DtEntregaCliente) já vêm em ISO (AAAA-MM-DD), então bastou DATE(<coluna>).

### 2. Valores
Onde havia dados vazios ou '-' foi aplicado NULL
Aplicado padronização usando CAST, REPLACE para remover os sinais, ajustar os pontos de milhar, trocar ponto por virgula

### 3. Desconto

Os valores encontrados na origem foram padronizados para representar apenas três situações:

| Valores encontrados               | Valor padronizado |
| --------------------------------- | ----------------- |
| `S`, `SIM`, `1`, `X`, `TRUE`, `V` | `Sim`             |
| `N`, `NAO`, `0`, `FALSE`, `F`     | `Nao`             |
| Vazio ou qualquer outro valor     | `Nao Informado`   |

### 4. Canal do pedido

Os diferentes formatos encontrados na origem também foram padronizados. A ordem das regras é importante, pois WHATSAPP contém APP:

| Valor encontrado        | Valor padronizado |
| ----------------------- | ----------------- |
| `WHATS`                 | `WhatsApp`        |
| `APP`                   | `App`             |
| `SITE`                  | `Site`            |
| `LOJA`                  | `Loja Fisica`     |
| `TEL`                   | `Telefone`        |
| Nenhuma correspondência | `Nao Informado`   |


Essa padronização reduz as variações existentes nos dados de origem e garante maior consistência nas análises e agrupamentos realizados posteriormente.

## Perguntas

### P1 — Onde está o gargalo do processo de entrega?

Para responder essa pergunta, foram criadas uma gold e uma view

<img width="271" height="229" alt="image" src="https://github.com/user-attachments/assets/13cc6c99-dc68-4f8e-b23c-ce7e27f3c308" />

<img width="1021" height="141" alt="image" src="https://github.com/user-attachments/assets/95770309-5d28-46af-b8ee-60a95d6e68c2" />

Conclusão: o gargalo está concentrado na etapa Nota Fiscal → Despacho, com impacto significativamente maior nas lojas pequenas. Uma possível causa é uma menor capacidade operacional ou processos menos automatizados nessas lojas.

### P2 — Qual categoria concentra o faturamento?

Para responder essa pergunta, foram criadas uma gold e uma view

<img width="238" height="172" alt="image" src="https://github.com/user-attachments/assets/1b00c239-6c69-43ea-8d94-325e6b7bc64b" /><br>

<img width="588" height="195" alt="image" src="https://github.com/user-attachments/assets/3433c127-9675-4779-8372-e3809e77dbea" />

Conclusão: Conforme os dados apresentados, a categoria que maior concentra o faturamento é a "Racao", com faturamento de 10762202.55, totalizando o total de 60.01%.

### P3 — O desconto funciona igual em todo canal?

Para responder essa pergunta, foram criadas uma gold e uma view

<img width="267" height="179" alt="image" src="https://github.com/user-attachments/assets/b7195759-e3b5-418a-8676-2c70d466b6ce" /><br>

<img width="421" height="413" alt="image" src="https://github.com/user-attachments/assets/e440b194-413b-4f85-8b43-597a82e640b6" />

Conclusão: o desconto não funciona de forma exatamente igual em todos os canais, mas existe um padrão claro: pedidos com desconto possuem ticket médio muito superior aos pedidos sem desconto. O maior ticket médio com desconto ocorre no WhatsApp (R$ 514,33), enquanto o menor ocorre no App (R$ 488,04).

### P4 — Qual praça de atendimento concentra o faturamento?

Para responder essa pergunta, foram criadas uma gold e uma view

<img width="239" height="165" alt="image" src="https://github.com/user-attachments/assets/db2b2a45-6c63-4c87-86f6-1cd732c3121b" /><br>

<img width="559" height="289" alt="image" src="https://github.com/user-attachments/assets/0015c34b-c20f-4779-a54e-b7fe2811365d" />

Conclusão: 'Vale do Itajai' concentra o maior faturamento, com um total de '633746.09', sendo bem superior a segundo colocado.

### P5 — Onde abrir a próxima loja, e o que os dados não permitem afirmar?

(a) Ranking por itens vendidos por mil habitantes

<img width="331" height="175" alt="image" src="https://github.com/user-attachments/assets/dbc07020-5a6d-4d44-9d54-f5348173ba4a" /><br>

<img width="714" height="711" alt="image" src="https://github.com/user-attachments/assets/55f536f5-783f-430d-a925-33e2cfae6f7b" />

Conclusão: Na liderança do ranking estamos com :

| Loja                          | População da cidade | Itens por mil habitantes | Tempo médio de entrega (dias) |
| ----------------------------- | ------------------: | -----------------------: | ----------------------------: |
| Pata Amiga Rio dos Cedros     |              11.322 |                    41,87 |                         14,24 |
| Pata Amiga Presidente Getulio |              16.359 |                    34,84 |                         14,16 |
| Pata Amiga Ibirama            |              18.613 |                    32,07 |                         15,39 |

(b) Faturamento por faixa de franquia

<img width="331" height="136" alt="image" src="https://github.com/user-attachments/assets/0f360f0d-bf88-4349-b415-43467087089c" /><br>

<img width="211" height="145" alt="image" src="https://github.com/user-attachments/assets/96845a1a-92de-4f43-ae57-de47bea9160a" />

Conclusão: Na liderança do faturamento possuímos:
| Categoria |           Valor |
| --------- | --------------: |
| Ouro      | R$ 1.011.264,38 |

(c) O que ficou de fora

<img width="255" height="137" alt="image" src="https://github.com/user-attachments/assets/6cac6f88-cab9-4137-bc42-0191c9281658" /><br>

<img width="226" height="122" alt="image" src="https://github.com/user-attachments/assets/3bd81be9-6197-48c1-99a5-3f1820e6085d" />

| Medida                  | Quantidade |
| ----------------------- | ---------: |
| Pedidos sem loja        |          3 |
| Entregas não concluídas |      1.953 |
| Itens em branco         |        257 |
| Valores em branco       |        121 |

Os dados indicam Rio dos Cedros como o destaque do ranking, com 41,87 itens vendidos por mil habitantes, seguido por Presidente Getúlio (34,84) e Ibirama (32,07). Isso demonstra uma maior quantidade de itens vendidos proporcionalmente à população nessas cidades e pode indicar um potencial de mercado para uma nova unidade. Além disso, o tempo médio de entrega em Rio dos Cedros é de 14,24 dias, semelhante ao observado nas demais cidades do ranking.

## Diagrama do Projeto:

<img width="1009" height="720" alt="image" src="https://github.com/user-attachments/assets/b0e17c9c-a4ae-4523-9978-8726d6ed4989" />
