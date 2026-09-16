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
    where DtCriacao < '{date}'
),

idade_transacoes AS (
    SELECT IdCliente,
           cast(max(julianday('{date}') - julianday(dtDia)) as int) AS qtdDiasPrimTransacao,
           cast(min(julianday('{date}') - julianday(dtDia)) as int) AS qtdDiasUltTransacao
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
           CAST(julianday('{date}') - julianday(dtDia) AS INT) AS qtdDiasPenultimaTransacao
    FROM row_numbered
    WHERE rnDia = 2
),

tb_life_cycle AS (
    SELECT t1.*,
        t2.qtdDiasPenultimaTransacao,
        CASE
            WHEN qtdDiasPrimTransacao <= 7 THEN '01-Curioso'
            WHEN qtdDiasUltTransacao <= 7 AND qtdDiasPenultimaTransacao - qtdDiasUltTransacao <= 14 THEN '02-Fiel'
            WHEN qtdDiasUltTransacao BETWEEN 8 AND 14 THEN '03-Turista'
            WHEN qtdDiasUltTransacao BETWEEN 15 AND 28 THEN '04-Desencantado'
            WHEN qtdDiasUltTransacao > 28 THEN '05-Perdido'
            WHEN qtdDiasUltTransacao <= 7 AND qtdDiasPenultimaTransacao - qtdDiasUltTransacao BETWEEN 15 AND 27 THEN '02-Reconquistado'
            WHEN qtdDiasUltTransacao <= 7 AND qtdDiasPenultimaTransacao - qtdDiasUltTransacao > 27 THEN '02-Recuperado'
        END AS descLifeCycle
    FROM idade_transacoes AS t1
    LEFT JOIN penultima_ativacao AS t2
    ON t1.idCliente = t2.idCliente
),

tb_freq_valor as(
    select idCliente,
            count( distinct substr(DtCriacao,0,11)) as qtdFrequencia,
            sum(case when QtdePontos > 0 then QtdePontos else 0 end) as qtdPontos 
    from transacoes
    where DtCriacao < '{date}' 
        and DtCriacao > date('{date}', '-28 day')
    group by idCliente
    order by qtdFrequencia desc
),

tb_cluster as (
    select
        *,
        case 
            when qtdFrequencia <= 10 and qtdPontos > 1500 then '1.2-Hypers'
            when qtdFrequencia > 10 and qtdPontos >= 1500 then '2.2-Eficientes'
            when qtdFrequencia < 10 and qtdPontos >= 750 then  '1.1-Experimentadores'
            when qtdFrequencia > 10 and qtdPontos >= 750 then '2.1-Esforçados'
            when qtdFrequencia < 5 then '0.0-Lurkers'
            when qtdFrequencia <= 10 then '1.0-Novatos'
            when qtdFrequencia > 10 then '2.0-Potencial'
        end as cluster
    from tb_freq_valor
)

select 
    date('{date}', '-1 day') as dtRef,
    t1.*,
    t2.qtdPontos,
    t2.qtdFrequencia,
    t2.cluster
from tb_life_cycle t1
left join tb_cluster t2
on t1.idCliente = t2.idCliente