DROP TABLE IF EXISTS abt_fiel;
CREATE TABLE IF NOT EXISTS abt_fiel AS

with tb_join as (
    select 
        t1.dtRef,
        t1.IdCliente,
        t1.descLifeCycle,
        t2.descLifeCycle,
        CASE WHEN t2.descLifeCycle = '02-Fiel' THEN 1 ELSE 0 END AS flFiel,
        row_number() over (partition by t1.idCliente order by random()) as RandomCol
    from life_cycle t1
    left join life_cycle t2
        on t1.IdCliente = t2.IdCliente
        and date(t1.dtRef, '+28 day') = date(t2.dtRef)
    where ((t1.dtRef >= '2024-03-01' and t1.dtRef <= '2025-08-01')
        or t1.dtRef in ('2025-09-01', '2025-10-01', '2025-11-01', 
        '2025-12-01', '2026-01-01', '2026-02-01', 
        '2026-03-01', '2026-04-01', '2026-05-01', 
        '2026-06-01', '2026-07-01', '2026-08-01'))
        and t1.descLifeCycle <> '05-Perdido'
),

tb_cohort as (
    select 
        t1.dtRef,
        t1.idCliente,
        t1.flFiel
    from tb_join t1
    where RandomCol <= 2
    order by idCliente, dtRef
)

select 
    t1.*,
    t2.idadeDias, 
    t2.qtdAtivacoesVida, 
    t2.qtdAtivacoesVidaD7, 
    t2.qtdAtivacoesVidaD14, 
    t2.qtdAtivacoesVidaD28, 
    t2.qtdAtivacoesVidaD56, 
    t2.qtdTransacoesVida, 
    t2.qtdTransacoesVidaD7, 
    t2.qtdTransacoesVidaD14, 
    t2.qtdTransacoesVidaD28, 
    t2.qtdTransacoesVidaD56, 
    t2.qtdePontosPosVida,
    t2.qtdePontosPosD7,
    t2.qtdePontosPosD14,
    t2.qtdePontosPosD28,
    t2.qtdePontosPosD56,
    t2.qtdePontosNegVida,
    t2.qtdePontosNegD7,
    t2.qtdePontosNegD14,
    t2.qtdePontosNegD28,
    t2.qtdePontosNegD56,
    t2.qtdTransacaoManha, 
    t2.qtdTransacaoTarde, 
    t2.qtdTransacaoNoite, 
    t2.pctTransacoesManha, 
    t2.pctTransacoesTarde, 
    t2.pctTransacoesNoite, 
    t2.QtdTransacoesDiaVida, 
    t2.QtdTransacoesDiaD7, 
    t2.QtdTransacoesDiaD14, 
    t2.QtdTransacoesDiaD28, 
    t2.QtdTransacoesDiaD56, 
    t2.pctAtivacaoMau, 
    t2.qtdHorasD7, 
    t2.qtdHorasD14, 
    t2.qtdHorasD28, 
    t2.qtdHorasD56, 
    t2.avgIntervaloDiasVida, 
    t2.avgIntervaloDiasD28,
    t2.pctChatMessage,
    t2.pctAirflowLover,
    t2.pctRLover,
    t2.pctResgatarPonei,
    t2.pctListadepresenca,
    t2.pctPresencaStreak,
    t2.pctTrocadePontosStreamElements,
    t2.pctReembolsoTrocadePontosStreamElements,
    t2.pctRPG,
    t2.pctChurnModel,
    t3.qtdFrequencia,
    t3.descLifeCycleAtual,
    t3.descLifeCycleD28,
    t3.pctCurioso,
    t3.pctFiel,
    t3.pctTurista,
    t3.pctDesencantado,
    t3.pctPerdido,
    t3.pctReconquistado,
    t3.pctRecuperado,
    t3.ratioFreqGrupo,
    t4.qtdCursosCompletos,
    t4.qtdCursosIncompletos,
    t4.github2025,
    t4.python2025,
    t4.loyaltyPredict2025,
    t4.estatistica2025,
    t4.machineLearning2025,
    t4.sql2025,
    t4.carreira,
    t4.pandas2025,
    t4.sql2020,
    t4.pandas2024,
    t4.plataformaMl2026,
    t4.python2024,
    t4.ragia,
    t4.estatistica2024,
    t4.mlflow2025,
    t4.github2024,
    t4.dsDatabricks2024,
    t4.ml2024,
    t4.nekt2025,
    t4.streamlit2025,
    t4.lagoMago2024,
    t4.tramparLakehouse2024,
    t4.go2026,
    t4.f1Lake,
    t4.speedF1,
    t4.coletaDados2024,
    t4.dsPontos2024,
    t4.matchmakingTramparDeCasa2024,
    t4.tseAnalytics2024,
    t4.iaCanal2025,
    t4.qtdDiasUltiAtividade
from
    tb_cohort as t1
left join 
    fs_transacional t2
        on t1.idCliente = t2.idCliente
        and t1.dtRef = t2.dtRef
left join 
    fs_life_cycle t3
        on t1.idCliente = t3.idCliente
        and t1.dtRef = t3.dtRef
left join 
    fs_education t4
        on t1.idCliente = t4.idCliente
        and t1.dtRef = t4.dtRef
WHERE t3.dtRef IS NOT NULL
;