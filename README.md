# Projeto de Business Intelligence - Rede Pata Amiga




# Projeto de Business Intelligence - Rede Pata Amiga

## Diagnóstico da Origem (Tarefa 1)

A análise inicial dos dados da Rede Pata Amiga foi realizada a partir das tabelas de staging `stg_pedido`, `stg_loja` e `stg_loja_praca`.

A carga inicial apresentou as seguintes quantidades de registros:

| Tabela         | Quantidade de registros |
| -------------- | ----------------------: |
| stg_pedido     |                   4.044 |
| stg_loja       |                      32 |
| stg_loja_praca |                      48 |

### Problemas de qualidade identificados

Durante o diagnóstico foram identificadas inconsistências de padronização e dados ausentes na base de origem.

| Problema identificado                        | Resultado |
| -------------------------------------------- | --------: |
| Grafias distintas de categorias de produtos  |        37 |
| Grafias distintas de nomes de lojas          |       128 |
| Grafias distintas de canal de pedido         |        20 |
| Grafias distintas de indicação de desconto |        17 |
| Pedidos sem código da loja                  |     1.575 |
| Pedidos sem nome da loja                     |         3 |

Os resultados demonstram que os dados de origem apresentam problemas de qualidade que precisam ser tratados antes da construção do modelo dimensional.

As 37 grafias distintas de categorias mostram a necessidade de padronização dos nomes das categorias. O mesmo problema ocorre nos nomes das lojas, nos canais de venda e na indicação da existência de desconto.

Também foram encontrados 1.575 pedidos sem código de loja, aproximadamente 39% dos pedidos. Esses registros precisarão receber tratamento durante a construção da tabela fato para evitar chaves estrangeiras nulas.

### Marcos logísticos em branco

Também foram encontrados registros sem preenchimento em diferentes etapas do processo logístico:

| Marco logístico             | Registros em branco |
| ---------------------------- | ------------------: |
| Separação de estoque       |               1.077 |
| Emissão da nota fiscal      |               1.338 |
| Despacho pela transportadora |               1.665 |
| Entrega ao cliente           |               1.953 |

Os campos em branco dos marcos logísticos representam processos que ainda não haviam alcançado determinada etapa dentro da janela observada.

Por esse motivo, esses valores não devem ser convertidos para zero. Na construção da tabela fato, os prazos correspondentes deverão permanecer como `NULL` quando o marco necessário para o cálculo ainda não existir.

### Decisão de tratamento

As tabelas de staging serão preservadas com os dados originais, sem alterações.

A limpeza e a padronização dos dados serão realizadas durante a carga das dimensões e da tabela fato. Registros que não puderem ser associados corretamente às dimensões serão direcionados para a chave coringa `-1` (`Nao Informado`), evitando chaves estrangeiras nulas na tabela fato.
