-- =====================================================================================
-- 03-SUAS-DIMENSOES.SQL
-- Case: Pata Amiga
-- Preenche dim_categoria, dim_praca e bridge_loja_praca
-- Rode depois de: 02-dimensoes-prontas.sql
-- =====================================================================================


-- =====================================================================================
-- 1. DIM_CATEGORIA
-- Grao: uma linha para cada grafia de categoria encontrada na origem
-- =====================================================================================

-- Linha coringa:
-- utilizada quando uma categoria nao puder ser identificada.
INSERT INTO dim_categoria (
    sk_categoria,
    categoria_origem,
    nome_categoria,
    grupo_categoria
)
VALUES (
    -1,
    'Nao Informado',
    'Nao Informado',
    'Nao Informado'
);


-- Carrega as grafias distintas existentes na staging.
-- categoria_origem guarda a grafia ORIGINAL, sem alteracao.
-- O CASE cria a categoria padronizada.

INSERT INTO dim_categoria (
    categoria_origem,
    nome_categoria,
    grupo_categoria
)
SELECT DISTINCT

    "CategoriaProduto" AS categoria_origem,

    CASE
        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%MED%'
            THEN 'Medicamento'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%PETISC%'
            THEN 'Petisco'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%RA%'
            THEN 'Racao'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%HIG%'
            THEN 'Higiene'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%BRINQ%'
            THEN 'Brinquedo'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%ACESS%'
            THEN 'Acessorio'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%SERV%'
            THEN 'Servico'

        ELSE 'Nao Informado'
    END AS nome_categoria,

    CASE
        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%MED%'
            THEN 'Saude e Higiene'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%PETISC%'
            THEN 'Alimentacao'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%RA%'
            THEN 'Alimentacao'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%HIG%'
            THEN 'Saude e Higiene'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%BRINQ%'
            THEN 'Bem-estar'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%ACESS%'
            THEN 'Bem-estar'

        WHEN UPPER(TRANSLATE(
            "CategoriaProduto",
            'ÁÀÂÃÉÊÍÓÔÕÚÇáàâãéêíóôõúç',
            'AAAAEEIOOOUCaaaaeeiooouc'
        )) LIKE '%SERV%'
            THEN 'Bem-estar'

        ELSE 'Nao Informado'
    END AS grupo_categoria

FROM stg_pedido;

-- =====================================================================================
-- 2. DIM_PRACA
-- Grao: uma linha para cada praca de atendimento
-- =====================================================================================

-- Linha coringa:
-- utilizada quando uma praca nao puder ser identificada.
INSERT INTO dim_praca (
    sk_praca,
    cod_praca,
    nome_praca,
    regional,
    domicilios_com_pet
)
VALUES (
    -1,
    'N/I',
    'Nao Informado',
    'Nao Informado',
    0
);


-- Carrega as pracas distintas existentes na staging.
-- DomiciliosComPet chega como texto, por exemplo '148.000'.
-- O ponto representa milhar e deve ser removido antes da conversao para INTEGER.

INSERT INTO dim_praca (
    cod_praca,
    nome_praca,
    regional,
    domicilios_com_pet
)
SELECT DISTINCT
    "CodPraca",
    "NomePraca",
    "Regional",
    CAST(REPLACE("DomiciliosComPet", '.', '') AS INTEGER)
FROM stg_loja_praca;

-- =====================================================================================
-- 3. BRIDGE_LOJA_PRACA
-- Grao: uma linha para cada combinacao loja x praca
-- =====================================================================================

INSERT INTO bridge_loja_praca (
    cod_loja,
    sk_praca,
    fator_publico
)
SELECT
    s."CodLoja",
    p.sk_praca,
    CAST(REPLACE(s."PercentualPublico", ',', '.') AS DECIMAL(6,4))
FROM stg_loja_praca s
JOIN dim_praca p
    ON p.cod_praca = s."CodPraca";