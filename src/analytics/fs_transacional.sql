 with tb_transacao as (
    select *,
        substr(DtCriacao, 0, 11) as  dtDia,
        cast(substr(DtCriacao, 12, 2) as int) as dtHora
    from transacoes
    where dtCriacao < '2025-10-01'
),

tb_agg_transacoes as (
    select 
        idCliente, 

        max(julianday(date('2025-10-01', '-1 day')) - julianday(DtCriacao)) as idadeDias,

        count(distinct  dtDia) as qtdAtivacoesVida,
        count(distinct case when  dtDia >= date('2025-10-01', '-7 day') then  dtDia end) as qtdAtivacoesVidaD7,
        count(distinct case when  dtDia >= date('2025-10-01', '-14 day') then  dtDia end) as qtdAtivacoesVidaD14,
        count(distinct case when  dtDia >= date('2025-10-01', '-28 day') then  dtDia end) as qtdAtivacoesVidaD28,
        count(distinct case when  dtDia >= date('2025-10-01', '-56 day') then  dtDia end) as qtdAtivacoesVidaD56,

        count(distinct idTransacao) as qtdTransacoesVida,
        count(distinct case when  dtDia >= date('2025-10-01', '-7 day') then idTransacao end) as qtdTransacoesVidaD7,
        count(distinct case when  dtDia >= date('2025-10-01', '-14 day') then idTransacao end) as qtdTransacoesVidaD14,
        count(distinct case when  dtDia >= date('2025-10-01', '-28 day') then idTransacao end) as qtdTransacoesVidaD28,
        count(distinct case when  dtDia >= date('2025-10-01', '-56 day') then idTransacao end) as qtdTransacoesVidaD56,

        sum(case when qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVida,
        sum(case when  dtDia >= date('2025-10-01', '-7 day')  and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD7,
        sum(case when  dtDia >= date('2025-10-01', '-28 day') and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD28,
        sum(case when  dtDia >= date('2025-10-01', '-56 day') and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD56,

        sum(case when qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVida,
        sum(case when  dtDia >= date('2025-10-01', '-7 day')  and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD7,
        sum(case when  dtDia >= date('2025-10-01', '-14 day') and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD14,
        sum(case when  dtDia >= date('2025-10-01', '-28 day') and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD28,
        sum(case when  dtDia >= date('2025-10-01', '-56 day') and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD56,

        -- Hora está em utc-0, portanto foram somadas 3 horas para coincidir com o horario do
        count(case when dtHora between 10 and 14 then IdTransacao end) as qtdTransacaoManha,
        count(case when dtHora between 15 and 21 then IdTransacao end) as qtdTransacaoTarde,
        count(case when dtHora > 21 or dtHora < 10 then IdTransacao end) as qtdTransacaoNoite,

        1.* count(case when dtHora between 10 and 14 then IdTransacao end) / count(IdTransacao) as pctTransacoesManha,    
        1.* count(case when dtHora between 15 and 21 then IdTransacao end) / count(IdTransacao) as pctTransacoesTarde,
        1.* count(case when dtHora > 21 or dtHora < 10 then IdTransacao end)/ count(IdTransacao) as pctTransacoesNoite
    from tb_transacao
    group by idCliente
),

tb_agg_calc as (
    select
        *,
        coalesce( 1. * qtdTransacoesVida / qtdAtivacoesVida, 0) as QtdTransacoesDiaVida,
        coalesce( 1. * qtdTransacoesVidaD7 / qtdAtivacoesVidaD7, 0) as QtdTransacoesDiaD7,
        coalesce( 1. * qtdTransacoesVidaD14 / qtdAtivacoesVidaD14, 0) as QtdTransacoesDiaD14,
        coalesce( 1. * qtdTransacoesVidaD28 / qtdAtivacoesVidaD28, 0) as QtdTransacoesDiaD28,
        coalesce( 1. * qtdTransacoesVidaD56 / qtdAtivacoesVidaD56, 0) as QtdTransacoesDiaD56,

        coalesce ( 1. * qtdAtivacoesVidaD28 / 28, 0) as pctAtivacaoMau
    from tb_agg_transacoes
),

tb_horas_dia as (
    select 
        idCliente,
         dtDia,
        24 * (max(julianday(DtCriacao)) - min(julianday(DtCriacao))) as duracao
    from tb_transacao
    group by idCliente,  dtDia
),

tb_hora_cliente as(
    select
        idCliente,
        sum(duracao) as duracaoHorasVida,
        sum(case when  dtDia >= date('2025-10-01', '-7 day') then duracao else 0 end) as qtdHorasD7,
        sum(case when  dtDia >= date('2025-10-01', '-14 day') then duracao else 0 end) as qtdHorasD14,
        sum(case when  dtDia >= date('2025-10-01', '-28 day') then duracao else 0 end) as qtdHorasD28,
        sum(case when  dtDia >= date('2025-10-01', '-56 day') then duracao else 0 end) as qtdHorasD56
    from tb_horas_dia
    group by idCliente
),

tb_lag_dia as (
    select 
        idCliente,
         dtDia,
        lag( dtDia) over (partition by idCliente order by  dtDia) as lagdia
    from tb_horas_dia
),

tb_intervalo_dias as (
    select 
        idCliente,
        avg(julianday( dtDia) - julianday(lagdia)) as avgIntervaloDiasVida,
        avg(case when  dtDia >= date('2025-10-01', '-28 day') then julianday( dtDia) - julianday(lagdia) end) as avgIntervaloDiasD28
    from tb_lag_dia
    group by idCliente
),

tb_share_produtos as (
    select distinct 
        t1.idCliente,
        1. * count(case when DescNomeProduto = 'ChatMessage' then t1.IdTransacao end) / count(t1.IdTransacao) as pctChatMessage,
        1. * count(case when DescNomeProduto = 'Airflow Lover' then t1.IdTransacao end) / count(t1.IdTransacao) as pctAirflowLover,
        1. * count(case when DescNomeProduto = 'R Lover' then t1.IdTransacao end) / count(t1.IdTransacao) as pctRLover,
        1. * count(case when DescNomeProduto = 'Resgatar Ponei' then t1.IdTransacao end) / count(t1.IdTransacao) as pctResgatarPonei,
        1. * count(case when DescNomeProduto = 'Lista de presença' then t1.IdTransacao end) / count(t1.IdTransacao) as pctListadepresenca,
        1. * count(case when DescNomeProduto = 'Presença Streak' then t1.IdTransacao end) / count(t1.IdTransacao) as pctPresencaStreak,
        1. * count(case when DescNomeProduto = 'Troca de Pontos StreamElements' then t1.IdTransacao end) / count(t1.IdTransacao) as pctTrocadePontosStreamElements,
        1. * count(case when DescNomeProduto = 'Reembolso: Troca de Pontos StreamElements' then t1.IdTransacao end) / count(t1.IdTransacao) as pctReembolsoTrocadePontosStreamElements,
        1. * count(case when DescCategoriaProduto = 'rpg' then t1.IdTransacao end) /count(t1.IdTransacao) as pctrpg,
        1. * count(case when DescCategoriaProduto = 'rpg' then t1.IdTransacao end) /count(t1.IdTransacao) as pctchurn_model
    from tb_transacao t1
    left join transacao_produto t2
    on t1.IdTransacao = t2.IdTransacao 
    left join produtos t3
    on t2.IdProduto = t3.IdProduto
    group by t1.idCliente
),

tb_join as (
    select
        t1.*,
        t2.qtdHorasD7,
        t2.qtdHorasD14,
        t2.qtdHorasD28,
        t2.qtdHorasD56,
        t3.avgIntervaloDiasVida,
        t3.avgIntervaloDiasD28
    from
        tb_agg_calc t1
    left join 
        tb_hora_cliente t2
        on t1.idCliente = t2.idCliente
    left join 
        tb_intervalo_dias t3
        on t1.idCliente = t3.idCliente
    left join 
        tb_share_produtos t4
        on t1.idCliente = t4.idCliente
)

select 
    date('2025-10-01', '-1 day') as dtRef,
    *
from tb_join 
