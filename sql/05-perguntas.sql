-- =====================================================================================
--  ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 04-fato.sql
--
--  Cada pergunta e UMA consulta: um SELECT com JOIN e GROUP BY. A subconsulta
--  aparece na P2 e na P5, e serve para trazer o total da rede como denominador.
-- =====================================================================================

USE dw_pata_amiga;

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================
--  Media (AVG) dos quatro intervalos ja calculados na carga, agrupada por porte
--  de loja. AVG ignora NULL - por isso a etapa nao cumprida foi gravada como NULL.
--  dias_total_ate_entrega e o processo inteiro, nao um dos quatro intervalos.

-- >>> ESCREVA AQUI a consulta da P1

DROP TABLE IF EXISTS gold_gargalo_entrega;
CREATE TABLE gold_gargalo_entrega AS
SELECT
    dl.porte as porte_empresa,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS media_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2)       AS media_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2)        AS media_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2)     AS media_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 2)    AS media_total_ate_entrega
FROM fato_pedido f
JOIN dim_loja dl 
    ON dl.sk_loja = f.sk_loja
GROUP BY dl.porte;

DROP VIEW IF EXISTS vw_gargalo_entrega;
CREATE VIEW vw_gargalo_entrega AS
SELECT
    dl.porte as porte_empresa,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS media_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2)       AS media_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2)        AS media_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2)     AS media_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 2)    AS media_total_ate_entrega
FROM fato_pedido f
JOIN dim_loja dl ON dl.sk_loja = f.sk_loja
GROUP BY dl.porte;

-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_categoria. Agrupe pelo nome_categoria
--  PADRONIZADO (nunca pela grafia crua). O percentual do total usa uma
--  subconsulta com o faturamento da rede como denominador.

-- >>> ESCREVA AQUI a consulta da P2

DROP TABLE IF EXISTS gold_categoria_faturamento;
CREATE TABLE gold_categoria_faturamento AS
SELECT
    dc.nome_categoria AS nome_categoria,
    dc.grupo_categoria AS grupo_categoria,
    ROUND(SUM(fp.vl_liquido), 2) AS faturamento,
    ROUND(100 * SUM(fp.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_total
FROM fato_pedido fp
JOIN dim_categoria dc ON dc.sk_categoria = fp.sk_categoria
GROUP BY dc.nome_categoria, dc.grupo_categoria
ORDER BY Faturamento DESC;

DROP VIEW IF EXISTS vw_categoria_faturamento;
CREATE VIEW vw_categoria_faturamento AS
SELECT
    dc.nome_categoria AS nome_categoria,
    dc.grupo_categoria AS grupo_categoria,
    ROUND(SUM(fp.vl_liquido), 2) AS faturamento,
    ROUND(100 * SUM(fp.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_total
FROM fato_pedido fp
JOIN dim_categoria dc ON dc.sk_categoria = fp.sk_categoria
GROUP BY dc.nome_categoria, dc.grupo_categoria
ORDER BY Faturamento DESC;

-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--  Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--  propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--  Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--  de WHATS.

-- >>> ESCREVA AQUI a consulta da P3

DROP TABLE IF EXISTS gold_funcionamento_desconto;
CREATE TABLE gold_funcionamento_desconto AS
SELECT
    canal_pedido,
    houve_desconto,
    ROUND(AVG(vl_liquido), 2) AS ticket_medio,
    COUNT(*) AS qtd_pedidos
FROM fato_pedido
GROUP BY canal_pedido, houve_desconto
ORDER BY canal_pedido, houve_desconto;

DROP VIEW IF EXISTS vw_funcionamento_desconto ;
CREATE VIEW vw_funcionamento_desconto  AS
SELECT
    canal_pedido,
    houve_desconto,
    ROUND(AVG(vl_liquido), 2) AS ticket_medio,
    COUNT(*) AS qtd_pedidos
FROM fato_pedido
GROUP BY canal_pedido, houve_desconto
ORDER BY canal_pedido, houve_desconto;

-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_praca e a ponte.
--  Caminho: fato_pedido -> dim_loja -> bridge_loja_praca -> dim_praca (a ponte
--  entra pelo cod_loja). O JOIN com a ponte DUPLICA a linha do pedido, uma por
--  praca - isso esta certo. Multiplique por b.fator_publico para o faturamento
--  nao ser contado duas vezes.

-- >>> ESCREVA AQUI a consulta da P4

DROP TABLE IF EXISTS gold_praca_faturamento;
CREATE TABLE gold_praca_faturamento AS
SELECT
    dp.nome_praca,
    dp.domicilios_com_pet,
    ROUND(SUM(fp.vl_liquido * b.fator_publico), 2) AS faturamento_rateado
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
JOIN bridge_loja_praca b ON b.cod_loja = dl.cod_loja
JOIN dim_praca dp ON dp.sk_praca = b.sk_praca
GROUP BY dp.nome_praca, dp.domicilios_com_pet
ORDER BY faturamento_rateado DESC;

DROP VIEW IF EXISTS vw_praca_faturamento ;
CREATE VIEW vw_praca_faturamento  AS
SELECT
    dp.nome_praca,
    dp.domicilios_com_pet,
    ROUND(SUM(fp.vl_liquido * b.fator_publico), 2) AS faturamento_rateado
FROM fato_pedido fp
JOIN dim_loja dl ON dl.sk_loja = fp.sk_loja
JOIN bridge_loja_praca b ON b.cod_loja = dl.cod_loja
JOIN dim_praca dp ON dp.sk_praca = b.sk_praca
GROUP BY dp.nome_praca, dp.domicilios_com_pet
ORDER BY faturamento_rateado DESC;

-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--  (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--      denominador na dimensao), calculado AQUI na consulta - nunca gravado
--      pronto. Cruze com o tempo medio de entrega.
--  (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--      responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--      cadastro so tem a foto de hoje.
--  (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--      itens e valores em branco.

-- >>> ESCREVA AQUI as consultas da P5
-- =====================================================================================
-- P5 - CONSULTAS DE ANALISE
-- =====================================================================================

-- (a) RANQUEAMENTO DAS LOJAS POR ITENS POR MIL HABITANTES

DROP TABLE IF EXISTS gold_rank_loja_por_mil_habitante_pergunta_A;
CREATE TABLE gold_rank_loja_por_mil_habitante_pergunta_A AS
SELECT
    dl.nome_loja,
    dl.populacao_cidade,
    ROUND(SUM(fp.qt_itens) / (dl.populacao_cidade / 1000), 2) AS itens_por_mil_habitantes,
    ROUND(AVG(fp.dias_total_ate_entrega), 2) AS tempo_medio_entrega
FROM fato_pedido fp
JOIN dim_loja dl 
    ON dl.sk_loja = fp.sk_loja
WHERE dl.sk_loja <> -1
GROUP BY dl.nome_loja, dl.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;


DROP VIEW IF EXISTS vw_rank_loja_por_mil_habitante_pergunta_A;
CREATE VIEW vw_rank_loja_por_mil_habitante_pergunta_A AS
SELECT
    dl.nome_loja,
    dl.populacao_cidade,
    ROUND(SUM(fp.qt_itens) / (dl.populacao_cidade / 1000), 2) AS itens_por_mil_habitantes,
    ROUND(AVG(fp.dias_total_ate_entrega), 2) AS tempo_medio_entrega
FROM fato_pedido fp
JOIN dim_loja dl 
    ON dl.sk_loja = fp.sk_loja
WHERE dl.sk_loja <> -1
GROUP BY dl.nome_loja, dl.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;

-- (b) FATURAMENTO POR FAIXA DE FRANQUIA
DROP TABLE IF EXISTS gold_faturamento_faixa_franquia_pergunta_B;
CREATE TABLE gold_faturamento_faixa_franquia_pergunta_B AS
SELECT
    dl.faixa_franquia,
    ROUND(SUM(fp.vl_liquido), 2) AS faturamento
FROM fato_pedido fp
JOIN dim_loja dl 
    ON dl.sk_loja = fp.sk_loja
GROUP BY dl.faixa_franquia
ORDER BY faturamento DESC;

DROP VIEW IF EXISTS vw_faturamento_faixa_franquia_pergunta_B;
CREATE VIEW vw_faturamento_faixa_franquia_pergunta_B AS
SELECT
    dl.faixa_franquia,
    ROUND(SUM(fp.vl_liquido), 2) AS faturamento
FROM fato_pedido fp
JOIN dim_loja dl 
    ON dl.sk_loja = fp.sk_loja
GROUP BY dl.faixa_franquia
ORDER BY faturamento DESC;

-- (c) CONFERENCIA DO QUE FICOU DE FORA

DROP TABLE IF EXISTS gold_ficou_de_fora_pergunta_C;
CREATE TABLE gold_ficou_de_fora_pergunta_C AS
SELECT 
    'pedidos sem loja' AS medida, 
    COUNT(*) AS valor 
FROM fato_pedido fp 
WHERE fp.sk_loja = -1

UNION ALL

SELECT 
    'entregas nao concluidas', 
    COUNT(*) 
FROM fato_pedido fp 
WHERE fp.sk_tempo_entrega = -1

UNION ALL

SELECT 
    'itens em branco', 
    COUNT(*) 
FROM fato_pedido fp 
WHERE fp.qt_itens IS NULL

UNION ALL

SELECT 
    'valores em branco', 
    COUNT(*) 
FROM fato_pedido fp 
WHERE fp.vl_liquido IS NULL;

DROP VIEW IF EXISTS vw_gold_ficou_de_fora_pergunta_C;
CREATE VIEW vw_gold_ficou_de_fora_pergunta_C AS

SELECT 
    'pedidos sem loja' AS medida, 
    COUNT(*) AS valor 
FROM fato_pedido fp 
WHERE fp.sk_loja = -1

UNION ALL

SELECT 
    'entregas nao concluidas', 
    COUNT(*) 
FROM fato_pedido fp 
WHERE fp.sk_tempo_entrega = -1

UNION ALL

SELECT 
    'itens em branco', 
    COUNT(*) 
FROM fato_pedido fp 
WHERE fp.qt_itens IS NULL

UNION ALL

SELECT 
    'valores em branco', 
    COUNT(*) 
FROM fato_pedido fp 
WHERE fp.vl_liquido IS NULL;