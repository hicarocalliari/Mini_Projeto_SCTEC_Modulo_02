-- =====================================================================================
--  ARQUIVO 4:  A TABELA FATO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 03-dimensoes.sql
--
--  UMA fato, UM unico INSERT ... SELECT. A tabela ja existe, vazia (arquivo 02).
--  4.044 linhas = 4.044 pedidos.
--
--  Regra geral: a limpeza dos dados fica nas dimensoes; a fato apenas procura a
--  linha correta (por JOIN). Nenhuma FK fica nula: quando o dado falta, ela
--  aponta para a linha -1 (CASE WHEN ... IS NULL THEN -1).
--
--  Sugestao: comece pelo esqueleto (numero_pedido + as duas FKs de tempo +
--  FROM), rode e confira 4.044 linhas; depois acrescente as colunas aos poucos.
-- =====================================================================================

USE dw_pata_amiga;

-- >>> ESCREVA AQUI o INSERT INTO fato_pedido (...) SELECT ... FROM stg_pedido ...
--
TRUNCATE TABLE fato_pedido;

INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT
# numero_pedido
p.`NumeroPedido`,

# sk_tempo_pedido
CAST(
    DATE_FORMAT(
        STR_TO_DATE(p.`DtHoraPedido`, '%m/%d/%Y %h:%i %p'),
        '%Y%m%d'
    ) AS SIGNED
),

# sk_tempo_entrega
# Verifica se DtEntregaCliente está vazia; se sim, recebe -1.
# Caso contrário, pega somente a data, muda o formato para AAAAMMDD
# e transforma o texto em um número inteiro sem sinal.
CASE
    WHEN p.`DtEntregaCliente` = '' THEN -1
    ELSE CAST(
        DATE_FORMAT(
            DATE(p.`DtEntregaCliente`),
            '%Y%m%d'
        ) AS SIGNED
    )
END,

#sk_loja
# Se nao encontrar correspondencia na dimensao, recebe -1.
COALESCE(dl.sk_loja, -1),
#sk_categoria
# Se nao encontrar correspondencia na dimensao, recebe -1.
COALESCE(dc.sk_categoria, -1),


#houve_desconto
# Verificado todos os distincts da tabela stg_pedido coluna HouveDesconto, e gerado um case para todas as condições
CASE
    WHEN UPPER(TRIM(p.`HouveDesconto`)) IN ('TRUE', 'X', 'SIM', 'V', 'S', '1')
        THEN 'Sim'

    WHEN UPPER(TRIM(p.`HouveDesconto`)) IN ('NAO', 'N', 'FALSE', 'F', '0')
        THEN 'Nao'

    ELSE 'Nao Informado'
END,

#canal_pedido 
# Verificado todos os distincts da tabela stg_pedido coluna CanalPedido, e gerado um case para todas as condições
CASE
    WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%WHATS%'
        THEN 'WhatsApp'
    WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%APP%'
        THEN 'App'
    WHEN UPPER(TRIM(p.`CanalPedido`)) = 'SITE'
        THEN 'Site'
    WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%LOJA%'
        THEN 'Loja Fisica'
    WHEN UPPER(TRIM(p.`CanalPedido`)) LIKE '%TEL%'
        THEN 'Telefone'
    ELSE 'Nao Informado'
END,

#dt_pedido 
STR_TO_DATE(p.`DtHoraPedido`, '%m/%d/%Y %h:%i %p'),

#qt_itens
# Remove espacos com TRIM e trata valores vazios ou '-'.
# Em seguida, verifica se o valor e negativo.
# Valores vazios, '-' ou negativos recebem NULL;
# os demais sao convertidos para numero inteiro.
CASE
    WHEN TRIM(p.`QTD.Itens`) IN ('', '-')
        THEN NULL
    WHEN CAST(p.`QTD.Itens` AS SIGNED) < 0
        THEN NULL
    ELSE CAST(p.`QTD.Itens` AS SIGNED)
END,

# vl_liquido
# Remove espacos e o 'R$'.
# Valores negativos recebem NULL.
# Ajusta a pontuacao para o formato decimal antes da conversao.
CASE
    WHEN TRIM(REPLACE(p.`ValorLiquidoPedido(R$)`, 'R$', '')) IN ('', '-')
        THEN NULL

    WHEN p.`ValorLiquidoPedido(R$)` LIKE '%,%'
        THEN CAST(
            REPLACE(
                REPLACE(
                    REPLACE(
                        p.`ValorLiquidoPedido(R$)`,
                        'R$', ''
                    ),
                    ' ', ''
                ),
                '.',
                ''
            ) AS DECIMAL(15,2)
        )
END,

#dias_integracao_separacao
#Calcula a diferença de dias entre a integração do ERP e a separação do estoque
CASE
    WHEN p.`Dt Separacao Estoque` = '' THEN NULL
    ELSE DATEDIFF(p.`Dt Separacao Estoque`, 
		DATE(STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p')))
END,

#dias_separacao_nota
#Calcula a diferença de dias entre a separação do estoque e a emissão da nota fiscal
CASE
    WHEN p.`DtNotaFiscal` = '' OR p.`Dt Separacao Estoque` = '' THEN NULL
    ELSE DATEDIFF(p.`DtNotaFiscal`, 
				  p.`Dt Separacao Estoque`)
END,

#dias_nota_despacho
#Calcula a diferença de dias entre a emissão da nota fiscal e o despacho para a transportadora
CASE WHEN p.`Dt_Despacho_Transportadora` = '' OR p.`DtNotaFiscal` = '' THEN NULL
	 ELSE DATEDIFF(DATE(p.`Dt_Despacho_Transportadora`), 
			       DATE(p.`DtNotaFiscal`))
END,

#dias_despacho_entrega
#Calcula a diferença de dias entre o despacho para a transportadora e a entrega ao cliente
CASE 
    WHEN p.`Dt_Despacho_Transportadora` = '' OR p.`DtEntregaCliente` = '' THEN NULL
    ELSE DATEDIFF( DATE(p.`DtEntregaCliente`),
				  DATE(p.`Dt_Despacho_Transportadora`))
END,

#dias_total_ate_entrega
#Calcula a diferença de dias entre a integração do ERP e a entrega ao cliente
CASE 
    WHEN p.`DtHoraIntegracaoERP` = '' OR p.`DtEntregaCliente` = '' THEN NULL
    ELSE DATEDIFF( DATE(p.`DtEntregaCliente`),
				   DATE(STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p'))
    )
END

#Foram localizados 3 casos que haviam erros de digitação errada/abreviação que tiveram que ser tratados isoladamente no Case, e as demais o TRIM/REPLACE resolve
FROM stg_pedido p
LEFT JOIN dim_loja dl
    ON dl.chave_loja =
       CASE
           WHEN TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' ')) = 'PATA AMIGA BLUMENAL CENTRO'
                THEN 'PATA AMIGA BLUMENAU CENTRO'
           WHEN TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' ')) = 'PATA AMIGA FLORIPA NORTE'
                THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
           WHEN TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' ')) = 'PATA AMIGA JGUA DO SUL'
                THEN 'PATA AMIGA JARAGUA DO SUL'
           ELSE TRIM(
               REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''),'  ',' ')
           )
       END

LEFT JOIN dim_categoria dc
    ON dc.categoria_origem = p.`CategoriaProduto`;





--  Roteiro das colunas:
--
--  * sk_tempo_pedido / sk_tempo_entrega: a chave e a data no formato AAAAMMDD.
--    Monte com CAST(DATE_FORMAT(<a data>, '%Y%m%d') AS SIGNED). A data do PEDIDO
--    vem no formato americano com AM/PM: a mascara e '%m/%d/%Y %h:%i %p'
--    (STR_TO_DATE). Usar '%d/%m/%Y' NAO da erro - ela devolve NULL e datas
--    erradas em silencio, que e pior. Os marcos da entrega ja vem em ISO:
--    DATE() basta. Entrega em branco -> -1.
--
--  * sk_loja, sk_categoria: vem de LEFT JOIN; se nao achou par, -1.
--
--  * LOJA (LEFT JOIN dim_loja): limpe o nome no ON. REPLACE tira '/SC' e o espaco
--    duplo; um CASE resolve 3 grafias (digitacao, apelido, abreviacao). Acento e
--    maiuscula nao atrapalham: a collation padrao do MySQL trata 'Timbo', 'TIMBO'
--    e 'Timbo' com acento como o mesmo texto.
--
--  * CATEGORIA (LEFT JOIN dim_categoria): uma linha so -
--    ON dc.categoria_origem = p.`CategoriaProduto`.
--
--  * houve_desconto e canal_pedido: padronize com CASE e grave na PROPRIA fato
--    (nao ha dimensao para eles). O de-para completo dos dois campos esta no
--    ENUNCIADO, na secao 7 ("Como padronizar o desconto e o canal").
--    A ordem importa: 'WHATSAPP' contem 'APP',
--    entao teste WHATS antes de APP.
--
--  * dinheiro e itens: '' e '-' viram NULL; tire "R$" e trate o milhar.
--
--  * os lags em dias: DATEDIFF(<fim>, <inicio>). Etapa nao cumprida grava NULL,
--    nunca 0. Use DATE() em volta da integracao (ela tem hora).

-- =====================================================================================
--  Confira o resultado com o 00-conferencia.sql (bloco "DEPOIS DO 04").
-- =====================================================================================
