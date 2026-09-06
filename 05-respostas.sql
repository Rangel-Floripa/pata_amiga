-- ============================================================
-- 05-RESPOSTAS.SQL
-- Case: Pata Amiga
-- Tarefa 5 - Perguntas de Negocio
--
-- Revisao:
--   - usa apenas recursos SQL permitidos no enunciado
--   - subconsultas somente nas perguntas de negocio
--   - sem recursos SQL avancados fora da lista do projeto
-- ============================================================


-- ============================================================
-- P1 - ONDE ESTA O GARGALO DA ENTREGA?
-- ============================================================

-- ------------------------------------------------------------
-- P1.1 - Medias gerais dos tempos logisticos
-- NULL nao entra no AVG.
-- ------------------------------------------------------------

SELECT
    ROUND(AVG(dias_integracao_separacao), 2)
        AS media_integracao_separacao,

    ROUND(AVG(dias_separacao_nota), 2)
        AS media_separacao_nota,

    ROUND(AVG(dias_nota_despacho), 2)
        AS media_nota_despacho,

    ROUND(AVG(dias_despacho_entrega), 2)
        AS media_despacho_entrega,

    ROUND(AVG(dias_total_ate_entrega), 2)
        AS media_total_ate_entrega

FROM fato_pedido;


-- ------------------------------------------------------------
-- P1.2 - Identificacao objetiva do maior gargalo
-- ------------------------------------------------------------

SELECT
    etapa,
    ROUND(media_dias, 2) AS media_dias

FROM (
    SELECT
        'Integracao -> Separacao' AS etapa,
        AVG(dias_integracao_separacao) AS media_dias
    FROM fato_pedido

    UNION ALL

    SELECT
        'Separacao -> Nota',
        AVG(dias_separacao_nota)
    FROM fato_pedido

    UNION ALL

    SELECT
        'Nota -> Despacho',
        AVG(dias_nota_despacho)
    FROM fato_pedido

    UNION ALL

    SELECT
        'Despacho -> Entrega',
        AVG(dias_despacho_entrega)
    FROM fato_pedido
) tempos

ORDER BY media_dias DESC;


-- ------------------------------------------------------------
-- P1.3 - Medias dos tempos logisticos por porte da loja
-- ------------------------------------------------------------

SELECT
    l.porte,
    COUNT(*) AS qtd_pedidos,

    ROUND(AVG(f.dias_integracao_separacao), 2)
        AS media_integracao_separacao,

    ROUND(AVG(f.dias_separacao_nota), 2)
        AS media_separacao_nota,

    ROUND(AVG(f.dias_nota_despacho), 2)
        AS media_nota_despacho,

    ROUND(AVG(f.dias_despacho_entrega), 2)
        AS media_despacho_entrega,

    ROUND(AVG(f.dias_total_ate_entrega), 2)
        AS media_total_ate_entrega

FROM fato_pedido f

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY l.porte

ORDER BY l.porte;


-- ------------------------------------------------------------
-- P1.4 - Gargalo principal por porte
-- ------------------------------------------------------------

SELECT
    l.porte,

    ROUND(AVG(f.dias_integracao_separacao), 2)
        AS integracao_separacao,

    ROUND(AVG(f.dias_separacao_nota), 2)
        AS separacao_nota,

    ROUND(AVG(f.dias_nota_despacho), 2)
        AS nota_despacho,

    ROUND(AVG(f.dias_despacho_entrega), 2)
        AS despacho_entrega

FROM fato_pedido f

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY l.porte

ORDER BY l.porte;


-- ============================================================
-- P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- ============================================================

-- ------------------------------------------------------------
-- P2.1 - Faturamento por categoria padronizada
-- Percentual calculado sobre o faturamento total da rede.
-- ------------------------------------------------------------

SELECT
    c.nome_categoria,

    ROUND(
        SUM(f.vl_liquido),
        2
    ) AS faturamento_categoria,

    ROUND(
        100.0 * SUM(f.vl_liquido)
        /
        (
            SELECT SUM(vl_liquido)
            FROM fato_pedido
        ),
        2
    ) AS percentual_faturamento

FROM fato_pedido f

JOIN dim_categoria c
    ON c.sk_categoria = f.sk_categoria

GROUP BY c.nome_categoria

ORDER BY faturamento_categoria DESC;


-- ------------------------------------------------------------
-- P2.2 - Faturamento por categoria dentro de cada porte
-- O percentual e calculado dentro de cada porte.
-- ------------------------------------------------------------

SELECT
    l.porte,
    c.nome_categoria,

    ROUND(
        SUM(f.vl_liquido),
        2
    ) AS faturamento_categoria,

    ROUND(
        100.0 * SUM(f.vl_liquido)
        /
        (
            SELECT SUM(f2.vl_liquido)

            FROM fato_pedido f2

            JOIN dim_loja l2
                ON l2.sk_loja = f2.sk_loja

            WHERE f2.sk_loja <> -1
              AND l2.porte = l.porte
        ),
        2
    ) AS percentual_no_porte

FROM fato_pedido f

JOIN dim_categoria c
    ON c.sk_categoria = f.sk_categoria

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY
    l.porte,
    c.nome_categoria

ORDER BY
    l.porte,
    faturamento_categoria DESC;


-- ------------------------------------------------------------
-- P2.3 - Categoria campea em cada porte
--
-- Mantem somente a categoria cujo faturamento e igual
-- ao maior faturamento de categoria dentro daquele porte.
-- ------------------------------------------------------------

SELECT
    l.porte,
    c.nome_categoria AS categoria_campea,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento

FROM fato_pedido f

JOIN dim_categoria c
    ON c.sk_categoria = f.sk_categoria

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY
    l.porte,
    c.nome_categoria

HAVING SUM(f.vl_liquido) = (
    SELECT MAX(totais.faturamento_categoria)

    FROM (
        SELECT
            l2.porte,
            c2.nome_categoria,
            SUM(f2.vl_liquido) AS faturamento_categoria

        FROM fato_pedido f2

        JOIN dim_categoria c2
            ON c2.sk_categoria = f2.sk_categoria

        JOIN dim_loja l2
            ON l2.sk_loja = f2.sk_loja

        WHERE f2.sk_loja <> -1

        GROUP BY
            l2.porte,
            c2.nome_categoria
    ) totais

    WHERE totais.porte = l.porte
)

ORDER BY l.porte;


-- ============================================================
-- P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- ============================================================

-- ------------------------------------------------------------
-- P3.1 - Ticket medio COM e SEM desconto por canal
-- CASE dentro do AVG separa pedidos com e sem desconto.
-- ------------------------------------------------------------

SELECT
    canal_pedido,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Sim'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS ticket_medio_com_desconto,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Nao'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS ticket_medio_sem_desconto,

    SUM(
        CASE
            WHEN houve_desconto = 'Sim'
            THEN 1
            ELSE 0
        END
    ) AS pedidos_com_desconto,

    SUM(
        CASE
            WHEN houve_desconto = 'Nao'
            THEN 1
            ELSE 0
        END
    ) AS pedidos_sem_desconto

FROM fato_pedido

GROUP BY canal_pedido

ORDER BY canal_pedido;


-- ------------------------------------------------------------
-- P3.2 - Diferenca do ticket COM desconto x SEM desconto
-- ------------------------------------------------------------

SELECT
    canal_pedido,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Sim'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS ticket_com_desconto,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Nao'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS ticket_sem_desconto,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Sim'
                THEN vl_liquido
                ELSE NULL
            END
        )
        -
        AVG(
            CASE
                WHEN houve_desconto = 'Nao'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS diferenca_ticket,

    ROUND(
        100.0 *
        (
            AVG(
                CASE
                    WHEN houve_desconto = 'Sim'
                    THEN vl_liquido
                    ELSE NULL
                END
            )
            -
            AVG(
                CASE
                    WHEN houve_desconto = 'Nao'
                    THEN vl_liquido
                    ELSE NULL
                END
            )
        )
        /
        CASE
            WHEN AVG(
                CASE
                    WHEN houve_desconto = 'Nao'
                    THEN vl_liquido
                    ELSE NULL
                END
            ) = 0
            THEN NULL
            ELSE AVG(
                CASE
                    WHEN houve_desconto = 'Nao'
                    THEN vl_liquido
                    ELSE NULL
                END
            )
        END,
        2
    ) AS variacao_percentual

FROM fato_pedido

GROUP BY canal_pedido

ORDER BY canal_pedido;


-- ------------------------------------------------------------
-- P3.3 - Participacao dos canais no faturamento total
-- ------------------------------------------------------------

SELECT
    canal_pedido,
    COUNT(*) AS qtd_pedidos,

    ROUND(
        SUM(vl_liquido),
        2
    ) AS faturamento_canal,

    ROUND(
        100.0 * SUM(vl_liquido)
        /
        (
            SELECT SUM(vl_liquido)
            FROM fato_pedido
        ),
        2
    ) AS percentual_faturamento

FROM fato_pedido

GROUP BY canal_pedido

ORDER BY faturamento_canal DESC;


-- ------------------------------------------------------------
-- P3.4 - Resumo consolidado da P3
-- ------------------------------------------------------------

SELECT
    canal_pedido,

    COUNT(*) AS qtd_pedidos,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Sim'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS ticket_com_desconto,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Nao'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS ticket_sem_desconto,

    ROUND(
        AVG(
            CASE
                WHEN houve_desconto = 'Sim'
                THEN vl_liquido
                ELSE NULL
            END
        )
        -
        AVG(
            CASE
                WHEN houve_desconto = 'Nao'
                THEN vl_liquido
                ELSE NULL
            END
        ),
        2
    ) AS diferenca_ticket,

    ROUND(
        SUM(vl_liquido),
        2
    ) AS faturamento_canal,

    ROUND(
        100.0 * SUM(vl_liquido)
        /
        (
            SELECT SUM(vl_liquido)
            FROM fato_pedido
        ),
        2
    ) AS percentual_faturamento

FROM fato_pedido

GROUP BY canal_pedido

ORDER BY faturamento_canal DESC;


-- ============================================================
-- P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- ============================================================

-- ------------------------------------------------------------
-- P4.1 - Faturamento total por loja identificada
-- ------------------------------------------------------------

SELECT
    l.nome_loja,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_loja

FROM fato_pedido f

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY
    l.sk_loja,
    l.nome_loja

ORDER BY faturamento_loja DESC;


-- ------------------------------------------------------------
-- P4.2 - Faturamento rateado por praca
--
-- Primeiro soma o faturamento de cada loja identificada.
-- Depois multiplica pelo fator_publico da bridge.
-- So entao soma por praca.
-- ------------------------------------------------------------

SELECT
    p.nome_praca,

    ROUND(
        SUM(
            faturamento_loja.faturamento_loja
            * b.fator_publico
        ),
        2
    ) AS faturamento_rateado

FROM (
    SELECT
        l.cod_loja,
        SUM(f.vl_liquido) AS faturamento_loja

    FROM fato_pedido f

    JOIN dim_loja l
        ON l.sk_loja = f.sk_loja

    WHERE f.sk_loja <> -1

    GROUP BY l.cod_loja
) faturamento_loja

JOIN bridge_loja_praca b
    ON b.cod_loja = faturamento_loja.cod_loja

JOIN dim_praca p
    ON p.sk_praca = b.sk_praca

GROUP BY
    p.sk_praca,
    p.nome_praca

ORDER BY faturamento_rateado DESC;


-- ------------------------------------------------------------
-- P4.3 - Reconciliacao exigida pelo projeto
--
-- faturamento rateado por praca
-- + faturamento dos pedidos sem loja
-- - faturamento total da rede
-- = 0
-- ------------------------------------------------------------

SELECT
    ROUND(conferencia.faturamento_total_rede, 2)
        AS faturamento_total_rede,

    ROUND(conferencia.faturamento_rateado_pracas, 2)
        AS faturamento_rateado_pracas,

    ROUND(conferencia.faturamento_sem_loja, 2)
        AS faturamento_sem_loja,

    ROUND(
        conferencia.faturamento_rateado_pracas
        + conferencia.faturamento_sem_loja
        - conferencia.faturamento_total_rede,
        2
    ) AS diferenca

FROM (

    SELECT

        (
            SELECT SUM(vl_liquido)
            FROM fato_pedido
        ) AS faturamento_total_rede,

        (
            SELECT
                SUM(
                    faturamento_loja.faturamento_loja
                    * b.fator_publico
                )

            FROM (

                SELECT
                    l.cod_loja,
                    SUM(f.vl_liquido) AS faturamento_loja

                FROM fato_pedido f

                JOIN dim_loja l
                    ON l.sk_loja = f.sk_loja

                WHERE f.sk_loja <> -1

                GROUP BY l.cod_loja

            ) faturamento_loja

            JOIN bridge_loja_praca b
                ON b.cod_loja = faturamento_loja.cod_loja

        ) AS faturamento_rateado_pracas,

        (
            SELECT SUM(vl_liquido)

            FROM fato_pedido

            WHERE sk_loja = -1

        ) AS faturamento_sem_loja

) conferencia;

-- ------------------------------------------------------------
-- P4.4 - Faturamento rateado por praca
--        x domicilios com pet
-- ------------------------------------------------------------

SELECT
    p.nome_praca,

    p.domicilios_com_pet,

    ROUND(
        SUM(
            faturamento_loja.faturamento_loja
            * b.fator_publico
        ),
        2
    ) AS faturamento_rateado,

    ROUND(
        SUM(
            faturamento_loja.faturamento_loja
            * b.fator_publico
        )
        /
        CASE
            WHEN p.domicilios_com_pet = 0
            THEN NULL
            ELSE p.domicilios_com_pet
        END,
        2
    ) AS faturamento_por_domicilio_com_pet

FROM (

    SELECT
        l.cod_loja,
        SUM(f.vl_liquido) AS faturamento_loja

    FROM fato_pedido f

    JOIN dim_loja l
        ON l.sk_loja = f.sk_loja

    WHERE f.sk_loja <> -1

    GROUP BY l.cod_loja

) faturamento_loja

JOIN bridge_loja_praca b
    ON b.cod_loja = faturamento_loja.cod_loja

JOIN dim_praca p
    ON p.sk_praca = b.sk_praca

GROUP BY
    p.sk_praca,
    p.nome_praca,
    p.domicilios_com_pet

ORDER BY faturamento_rateado DESC;


-- ============================================================
-- P5 - ONDE ABRIR A PROXIMA LOJA,
--      E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- ============================================================


-- ------------------------------------------------------------
-- P5.1 - Itens vendidos por mil habitantes
--        x tempo medio de entrega
-- ------------------------------------------------------------

SELECT
    l.nome_loja,
    l.cidade,
    l.porte,
    l.populacao_cidade,

    SUM(f.qt_itens) AS total_itens_vendidos,

    ROUND(
        1000.0 * SUM(f.qt_itens)
        /
        CASE
            WHEN l.populacao_cidade = 0
            THEN NULL
            ELSE l.populacao_cidade
        END,
        2
    ) AS itens_por_mil_habitantes,

    ROUND(
        AVG(f.dias_total_ate_entrega),
        2
    ) AS tempo_medio_entrega

FROM fato_pedido f

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY
    l.sk_loja,
    l.nome_loja,
    l.cidade,
    l.porte,
    l.populacao_cidade

ORDER BY
    itens_por_mil_habitantes DESC;

-- ------------------------------------------------------------
-- P5.2 - Faturamento por faixa ATUAL de franquia
-- ------------------------------------------------------------

SELECT
    l.faixa_franquia,

    COUNT(*) AS qtd_pedidos,

    ROUND(
        SUM(f.vl_liquido),
        2
    ) AS faturamento,

    ROUND(
        100.0 * SUM(f.vl_liquido)
        /
        (
            SELECT SUM(vl_liquido)
            FROM fato_pedido
        ),
        2
    ) AS percentual_faturamento

FROM fato_pedido f

JOIN dim_loja l
    ON l.sk_loja = f.sk_loja

WHERE f.sk_loja <> -1

GROUP BY l.faixa_franquia

ORDER BY faturamento DESC;

-- ------------------------------------------------------------
-- P5.3 - Impacto da qualidade dos dados
-- ------------------------------------------------------------

SELECT

    COUNT(*) AS total_pedidos,

    SUM(
        CASE
            WHEN sk_loja = -1
            THEN 1
            ELSE 0
        END
    ) AS pedidos_sem_loja,

    SUM(
        CASE
            WHEN sk_tempo_entrega = -1
            THEN 1
            ELSE 0
        END
    ) AS entregas_nao_concluidas,

    SUM(
        CASE
            WHEN qt_itens IS NULL
            THEN 1
            ELSE 0
        END
    ) AS pedidos_com_itens_em_branco,

    SUM(
        CASE
            WHEN vl_liquido IS NULL
            THEN 1
            ELSE 0
        END
    ) AS pedidos_com_valor_em_branco

FROM fato_pedido;