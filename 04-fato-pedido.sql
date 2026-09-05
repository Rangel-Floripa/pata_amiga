-- =====================================================================================
-- 04-FATO-PEDIDO.SQL
-- Case: Pata Amiga
-- Grao: uma linha por pedido
-- Rode depois de: 03-suas-dimensoes.sql
-- =====================================================================================

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

    -- =========================================================================
    -- 1. NUMERO DO PEDIDO
    -- =========================================================================

    s."NumeroPedido" AS numero_pedido,


    -- =========================================================================
    -- 2. FK DA DATA DO PEDIDO
    -- DtHoraPedido vem no formato americano:
    -- MM/DD/YYYY HH12:MI AM
    -- Exemplo: 09/01/2023 10:07 AM
    -- =========================================================================

    TO_CHAR(
        TO_TIMESTAMP(
            s."DtHoraPedido",
            'MM/DD/YYYY HH12:MI AM'
        ),
        'YYYYMMDD'
    )::INTEGER AS sk_tempo_pedido,


    -- =========================================================================
    -- 3. FK DA DATA DE ENTREGA
    -- Se ainda nao houve entrega, aponta para a linha coringa -1.
    -- =========================================================================

    CASE
        WHEN NULLIF(TRIM(s."DtEntregaCliente"), '') IS NULL
            THEN -1

        ELSE TO_CHAR(
            s."DtEntregaCliente"::DATE,
            'YYYYMMDD'
        )::INTEGER
    END AS sk_tempo_entrega,


    -- =========================================================================
    -- 4. FK DA LOJA
    -- A loja e encontrada atraves da chave_loja padronizada.
    -- Se nao encontrar, usa -1.
    -- =========================================================================

    COALESCE(
        l.sk_loja,
        -1
    ) AS sk_loja,


    -- =========================================================================
    -- 5. FK DA CATEGORIA
    -- categoria_origem guarda exatamente a grafia que veio da staging.
    -- =========================================================================

    COALESCE(
        c.sk_categoria,
        -1
    ) AS sk_categoria,


    -- =========================================================================
    -- 6. HOUVE DESCONTO
    -- Padroniza as 17 grafias da origem em:
    -- Sim / Nao / Nao Informado
    -- =========================================================================

    CASE

        WHEN UPPER(TRIM(s."HouveDesconto"))
             IN ('S', 'SIM', '1', 'X', 'TRUE', 'V')
            THEN 'Sim'

        WHEN UPPER(TRIM(s."HouveDesconto"))
             IN ('N', 'NAO', '0', 'FALSE', 'F')
            THEN 'Nao'

        ELSE 'Nao Informado'

    END AS houve_desconto,


    -- =========================================================================
    -- 7. CANAL DO PEDIDO
    -- IMPORTANTE:
    -- WHATS deve ser testado ANTES de APP,
    -- pois WHATSAPP contem a palavra APP.
    -- =========================================================================

    CASE

        WHEN UPPER(TRIM(s."CanalPedido")) LIKE '%WHATS%'
            THEN 'WhatsApp'

        WHEN UPPER(TRIM(s."CanalPedido")) LIKE '%APP%'
            THEN 'App'

        WHEN UPPER(TRIM(s."CanalPedido")) LIKE '%SITE%'
            THEN 'Site'

        WHEN UPPER(TRIM(s."CanalPedido")) LIKE '%LOJA%'
            THEN 'Loja Fisica'

        WHEN UPPER(TRIM(s."CanalPedido")) LIKE '%TEL%'
            THEN 'Telefone'

        ELSE 'Nao Informado'

    END AS canal_pedido,


    -- =========================================================================
    -- 8. DATA E HORA DO PEDIDO
    -- =========================================================================

    TO_TIMESTAMP(
        s."DtHoraPedido",
        'MM/DD/YYYY HH12:MI AM'
    ) AS dt_pedido,


    -- =========================================================================
    -- 9. QUANTIDADE DE ITENS
    -- =========================================================================

    CASE

        WHEN TRIM(s."QTD.Itens") IN ('', '-')
            THEN NULL

        ELSE CAST(
            TRIM(s."QTD.Itens")
            AS INTEGER
        )

    END AS qt_itens,


    -- =========================================================================
    -- 10. VALOR LIQUIDO
    --
    -- Exemplos encontrados na origem:
    --
    -- R$ 1.850,00
    -- 1850.00
    -- 1.200
    -- -
    -- vazio
    --
    -- vazio e "-" viram NULL, nunca zero.
    -- =========================================================================

       CASE
        -- vazio ou "-" => NULL
        WHEN TRIM(REPLACE(s."ValorLiquidoPedido(R$)", 'R$', ''))
             IN ('', '-')
            THEN NULL

        -- Ex.: R$ 1.850,00 / 654,81
        WHEN s."ValorLiquidoPedido(R$)" LIKE '%,%'
            THEN CAST(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                s."ValorLiquidoPedido(R$)",
                                'R$',
                                ''
                            ),
                            ' ',
                            ''
                        ),
                        '.',
                        ''
                    ),
                    ',',
                    '.'
                )
                AS DECIMAL(15,2)
            )

        -- Ex.: 1.200 => 1200
        WHEN TRIM(
                 REPLACE(
                     REPLACE(s."ValorLiquidoPedido(R$)", 'R$', ''),
                     ' ',
                     ''
                 )
             ) ~ '^[0-9]{1,3}(\.[0-9]{3})+$'
            THEN CAST(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            s."ValorLiquidoPedido(R$)",
                            'R$',
                            ''
                        ),
                        ' ',
                        ''
                    ),
                    '.',
                    ''
                )
                AS DECIMAL(15,2)
            )

        -- Ex.: 1850.00 / 769 / 1058
        ELSE CAST(
            REPLACE(
                REPLACE(
                    s."ValorLiquidoPedido(R$)",
                    'R$',
                    ''
                ),
                ' ',
                ''
            )
            AS DECIMAL(15,2)
        )

    END AS vl_liquido,

    -- =========================================================================
    -- 11. DIAS ENTRE INTEGRACAO NO ERP E SEPARACAO
    --
    -- Se a separacao ainda nao ocorreu, grava NULL.
    -- =========================================================================

    CASE

        WHEN NULLIF(
            TRIM(s."Dt Separacao Estoque"),
            ''
        ) IS NULL
            THEN NULL

        ELSE

            s."Dt Separacao Estoque"::DATE

            -

            TO_TIMESTAMP(
                s."DtHoraIntegracaoERP",
                'MM/DD/YYYY HH12:MI AM'
            )::DATE

    END AS dias_integracao_separacao,


    -- =========================================================================
    -- 12. DIAS ENTRE SEPARACAO E NOTA FISCAL
    -- =========================================================================

    CASE

        WHEN NULLIF(
            TRIM(s."DtNotaFiscal"),
            ''
        ) IS NULL
            THEN NULL

        WHEN NULLIF(
            TRIM(s."Dt Separacao Estoque"),
            ''
        ) IS NULL
            THEN NULL

        ELSE

            s."DtNotaFiscal"::DATE
            -
            s."Dt Separacao Estoque"::DATE

    END AS dias_separacao_nota,


    -- =========================================================================
    -- 13. DIAS ENTRE NOTA FISCAL E DESPACHO
    -- =========================================================================

    CASE

        WHEN NULLIF(
            TRIM(s."Dt_Despacho_Transportadora"),
            ''
        ) IS NULL
            THEN NULL

        WHEN NULLIF(
            TRIM(s."DtNotaFiscal"),
            ''
        ) IS NULL
            THEN NULL

        ELSE

            s."Dt_Despacho_Transportadora"::DATE
            -
            s."DtNotaFiscal"::DATE

    END AS dias_nota_despacho,


    -- =========================================================================
    -- 14. DIAS ENTRE DESPACHO E ENTREGA
    -- =========================================================================

    CASE

        WHEN NULLIF(
            TRIM(s."DtEntregaCliente"),
            ''
        ) IS NULL
            THEN NULL

        WHEN NULLIF(
            TRIM(s."Dt_Despacho_Transportadora"),
            ''
        ) IS NULL
            THEN NULL

        ELSE

            s."DtEntregaCliente"::DATE
            -
            s."Dt_Despacho_Transportadora"::DATE

    END AS dias_despacho_entrega,


    -- =========================================================================
    -- 15. TEMPO TOTAL:
    -- INTEGRACAO ERP -> ENTREGA AO CLIENTE
    -- =========================================================================

    CASE

        WHEN NULLIF(
            TRIM(s."DtEntregaCliente"),
            ''
        ) IS NULL
            THEN NULL

        WHEN NULLIF(
            TRIM(s."DtHoraIntegracaoERP"),
            ''
        ) IS NULL
            THEN NULL

        ELSE

            s."DtEntregaCliente"::DATE

            -

            TO_TIMESTAMP(
                s."DtHoraIntegracaoERP",
                'MM/DD/YYYY HH12:MI AM'
            )::DATE

    END AS dias_total_ate_entrega


-- =============================================================================
-- TABELA DE ORIGEM
-- =============================================================================

FROM stg_pedido s


-- =============================================================================
-- JOIN DA CATEGORIA
--
-- A dim_categoria preservou CategoriaProduto exatamente como veio da origem
-- na coluna categoria_origem.
-- =============================================================================

LEFT JOIN dim_categoria c
    ON c.categoria_origem = s."CategoriaProduto"


-- =============================================================================
-- JOIN DA LOJA
--
-- A dim_loja possui chave_loja em:
-- caixa alta + sem acento.
--
-- Primeiro limpamos o nome da staging.
-- Depois corrigimos manualmente os tres casos conhecidos.
-- =============================================================================

LEFT JOIN dim_loja l

    ON l.chave_loja =

        CASE

            -- -------------------------------------------------------------
            -- Erro de digitacao:
            -- BLUMENAL -> BLUMENAU
            -- -------------------------------------------------------------

            WHEN
                UPPER(
                    TRANSLATE(
                        TRIM(
                            REPLACE(
                                REPLACE(
                                    s."Loja-Nome",
                                    '/SC',
                                    ''
                                ),
                                '  ',
                                ' '
                            )
                        ),
                        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇáàãâäéèêëíìîïóòõôöúùûüç',
                        'AAAAAEEEEIIIIOOOOOUUUUCaaaaaeeeeiiiiooooouuuuc'
                    )
                )
                = 'PATA AMIGA BLUMENAL CENTRO'

                THEN 'PATA AMIGA BLUMENAU CENTRO'


            -- -------------------------------------------------------------
            -- Apelido:
            -- FLORIPA -> FLORIANOPOLIS
            -- -------------------------------------------------------------

            WHEN
                UPPER(
                    TRANSLATE(
                        TRIM(
                            REPLACE(
                                REPLACE(
                                    s."Loja-Nome",
                                    '/SC',
                                    ''
                                ),
                                '  ',
                                ' '
                            )
                        ),
                        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇáàãâäéèêëíìîïóòõôöúùûüç',
                        'AAAAAEEEEIIIIOOOOOUUUUCaaaaaeeeeiiiiooooouuuuc'
                    )
                )
                = 'PATA AMIGA FLORIPA NORTE'

                THEN 'PATA AMIGA FLORIANOPOLIS NORTE'


            -- -------------------------------------------------------------
            -- Abreviacao:
            -- JGUA DO SUL -> JARAGUA DO SUL
            -- -------------------------------------------------------------

            WHEN
                UPPER(
                    TRANSLATE(
                        TRIM(
                            REPLACE(
                                REPLACE(
                                    s."Loja-Nome",
                                    '/SC',
                                    ''
                                ),
                                '  ',
                                ' '
                            )
                        ),
                        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇáàãâäéèêëíìîïóòõôöúùûüç',
                        'AAAAAEEEEIIIIOOOOOUUUUCaaaaaeeeeiiiiooooouuuuc'
                    )
                )
                = 'PATA AMIGA JGUA DO SUL'

                THEN 'PATA AMIGA JARAGUA DO SUL'


            -- -------------------------------------------------------------
            -- Todas as demais lojas:
            -- usa apenas a normalizacao comum.
            -- -------------------------------------------------------------

            ELSE

                UPPER(
                    TRANSLATE(
                        TRIM(
                            REPLACE(
                                REPLACE(
                                    s."Loja-Nome",
                                    '/SC',
                                    ''
                                ),
                                '  ',
                                ' '
                            )
                        ),
                        'ÁÀÃÂÄÉÈÊËÍÌÎÏÓÒÕÔÖÚÙÛÜÇáàãâäéèêëíìîïóòõôöúùûüç',
                        'AAAAAEEEEIIIIOOOOOUUUUCaaaaaeeeeiiiiooooouuuuc'
                    )
                )

        END;