USE dw_pata_amiga;
       
#'grafias distintas de nome de loja', '50', '(conte e descreva)'

SELECT 'qtd_lojas_unicas' as pergunta , 
	COUNT(DISTINCT nome_loja) AS resultado
FROM dim_loja
WHERE sk_loja <> -1;

#'grafias distintas de HouveDesconto', '12', '(conte)'
select 'qtd_graficas_houve_desconto' as pergunta, 
	COUNT(DISTINCT houve_desconto) AS resultado
FROM fato_pedido;

#'grafias distintas de CanalPedido', '8', '(conte)'
SELECT 
    'qtd_grafias_canal_pedido' AS pergunta,
    COUNT(DISTINCT canal_pedido) AS resultado
FROM
    fato_pedido;

#'pedidos sem Cod Loja preenchido', '1575', '1575  (~39%)'
SELECT 
    'pedidos sem Cod Loja preenchido' AS pergunta,
    COUNT(*) AS resultado,
    CONCAT(COUNT(*) * 100.0 / (SELECT 
                    COUNT(*)
                FROM
                    fato_pedido),
            '%') AS percentual
FROM
    fato_pedido
WHERE
     IS NULL;


#'pedidos sem nome de loja (vao para a -1)', '3', '3'


SELECT * FROM dw_pata_amiga.stg_loja;
###

SELECT COUNT(DISTINCT `Loja-Nome`) AS soma
FROM stg_pedido; # 50

SELECT COUNT(DISTINCT dl.nome_loja) AS qtd_lojas
FROM fato_pedido fp
JOIN dim_loja dl 
    ON fp.sk_loja = dl.sk_loja
   AND fp.sk_loja <> -1; # 32

##
SELECT COUNT(DISTINCT NomeLoja) AS qtd_lojas
FROM stg_loja; # 32

SELECT distinct NomeLoja
FROM stg_loja; # 32

#########
# 
SELECT COUNT(DISTINCT CategoriaProduto) AS qtd_categoria
FROM stg_pedido; # 18

SELECT COUNT(DISTINCT nome_categoria) AS qtd_categoria
FROM dim_categoria; # 8
