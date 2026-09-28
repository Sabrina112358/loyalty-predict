with tb_life_cycle_atual as (
    select
        IdCliente,
        qtdFrequencia,
        descLifeCycle as descLifeCycleAtual
    from life_cycle
    where dtRef = date('{date}', '-1 day')
),

tb_life_cycle_d28 as (
    select
        IdCliente,
        descLifeCycle as descLifeCycleD28
    from life_cycle
    where dtRef = date('{date}', '-29 day')
), 

tb_share_ciclos as (
    select IdCliente,
        1. * sum(case when descLifeCycle = '01-Curioso' then 1 else 0 end) / count(*) as pctCurioso,
        1. * sum(case when descLifeCycle = '02-Fiel' then 1 else 0 end) / count(*) as pctFiel,
        1. * sum(case when descLifeCycle = '03-Turista' then 1 else 0 end) / count(*) as pctTurista,
        1. * sum(case when descLifeCycle = '04-Desencantado' then 1 else 0 end) / count(*) as pctDesencantado,
        1. * sum(case when descLifeCycle = '05-Perdido' then 1 else 0 end) / count(*) as pctPerdido,
        1. * sum(case when descLifeCycle = '02-Reconquistado' then 1 else 0 end) / count(*) as pctReconquistado,
        1. * sum(case when descLifeCycle = '02-Recuperado' then 1 else 0 end) / count(*) as pctRecuperado
    from life_cycle
    where dtRef < '2025-09-01'
    group by IdCliente
),

tb_avg_ciclo as (
    select descLifeCycleAtual,
            avg(qtdFrequencia) as avgFreqGrupo
    from tb_life_cycle_atual
    group by descLifeCycleAtual
),

tb_join as (
    select 
        t1.*,
        t2.descLifeCycleD28,
        t3.pctCurioso,
        t3.pctFiel,
        t3.pctTurista,
        t3.pctDesencantado,
        t3.pctPerdido,
        t3.pctReconquistado,
        t3.pctRecuperado,
        t4.avgFreqGrupo,
        1. * t1.qtdFrequencia / t4.avgFreqGrupo as ratioFreqGrupo
    from tb_life_cycle_atual t1
    left join tb_life_cycle_d28 t2
        on t1.IdCliente = t2.IdCliente
    left join tb_share_ciclos t3
        on t1.IdCliente = t3.IdCliente
    left join tb_avg_ciclo t4
        on t1.descLifeCycleAtual = t4.descLifeCycleAtual
)

select 
    date('{date}', '-1 day') as dtRef,
    *
from tb_join