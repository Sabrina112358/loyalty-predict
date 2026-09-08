-- curiosa -> idade < 7
-- fiel -> recencia < 7 e recencia anterior < 15
-- turista -> recencia < 15
-- desencantado -> recencia < 28
-- perdido -> recencia >= 28
-- reconquistado -> recencia < 7 e recencia anterior <= 28
-- recuperado -> recencia < 7 e recencia anterior > 28
WITH transacoes_diarias AS (
    SELECT 
        DISTINCT
        IdCliente,
        substr(DtCriacao,0,11) AS dtDia

    FROM transacoes
),

idade_transacoes AS (
    SELECT IdCliente,
           cast(max(julianday('now') - julianday(dtDia)) as int) AS qtdeDiasPrimTransacao,
           cast(min(julianday('now') - julianday(dtDia)) as int) AS qtdeDiasUltTransacao
    FROM transacoes_diarias
    GROUP BY IdCliente
),

row_numbered AS (
    SELECT *,
            row_number() OVER (PARTITION BY IdCliente ORDER BY dtDia DESC) AS rnDia
    FROM transacoes_diarias
),

penultima_ativacao As (
    SELECT *,
           CAST(julianday('now') - julianday(dtDia) AS INT) AS qtdeDiasPenultimaTransacao
    FROM row_numbered
    WHERE rnDia = 2
),

tb_life_cycle AS (
    SELECT t1.*,
        t2.qtdeDiasPenultimaTransacao,
        CASE
            WHEN qtdeDiasPrimTransacao <= 7 THEN '01-Curioso'
            WHEN qtdeDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdeDiasUltTransacao <= 14 THEN '02-Fiel'
            WHEN qtdeDiasUltTransacao BETWEEN 8 AND 14 THEN '03-Turista'
            WHEN qtdeDiasUltTransacao BETWEEN 15 AND 28 THEN '04-Desencantado'
            WHEN qtdeDiasUltTransacao > 28 THEN '05-Perdido'
            WHEN qtdeDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdeDiasUltTransacao BETWEEN 15 AND 27 THEN '02-Reconquistado'
            WHEN qtdeDiasUltTransacao <= 7 AND qtdeDiasPenultimaTransacao - qtdeDiasUltTransacao > 27 THEN '02-Recuperado'
        END AS descLifeCycle
    FROM idade_transacoes AS t1
    LEFT JOIN penultima_ativacao AS t2
    ON t1.idCliente = t2.idCliente
)

select descLifeCycle, count(*) as qtd_clientes
from tb_life_cycle
group by descLifeCycle