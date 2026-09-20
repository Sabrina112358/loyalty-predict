 with tb_transacao as (
    select *,
        substr(DtCriacao, 0, 11) as dataCriacao
    from transacoes
    where dtCriacao < '2025-10-01'
),

tb_agg_transacoes as (
    select 
        idCliente, 

        count(distinct dataCriacao) as qtdAtivacoesVida,
        count(distinct case when dataCriacao >= date('2025-10-01', '-7 day') then dataCriacao end) as qtdAtivacoesVidaD7,
        count(distinct case when dataCriacao >= date('2025-10-01', '-14 day') then dataCriacao end) as qtdAtivacoesVidaD14,
        count(distinct case when dataCriacao >= date('2025-10-01', '-28 day') then dataCriacao end) as qtdAtivacoesVidaD28,
        count(distinct case when dataCriacao >= date('2025-10-01', '-56 day') then dataCriacao end) as qtdAtivacoesVidaD56,

        count(distinct idTransacao) as qtdTransacoesVida,
        count(distinct case when dataCriacao >= date('2025-10-01', '-7 day') then idTransacao end) as qtdTransacoesVidaD7,
        count(distinct case when dataCriacao >= date('2025-10-01', '-14 day') then idTransacao end) as qtdTransacoesVidaD14,
        count(distinct case when dataCriacao >= date('2025-10-01', '-28 day') then idTransacao end) as qtdTransacoesVidaD28,
        count(distinct case when dataCriacao >= date('2025-10-01', '-56 day') then idTransacao end) as qtdTransacoesVidaD56,

        sum(case when qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVida,
        sum(case when dataCriacao >= date('2025-10-01', '-7 day')  and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD7,
        sum(case when dataCriacao >= date('2025-10-01', '-14 day') and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD14,
        sum(case when dataCriacao >= date('2025-10-01', '-28 day') and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD28,
        sum(case when dataCriacao >= date('2025-10-01', '-56 day') and qtdePontos > 0 then qtdePontos else 0 end) as qtdPontosVidaD56,

        sum(case when qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVida,
        sum(case when dataCriacao >= date('2025-10-01', '-7 day')  and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD7,
        sum(case when dataCriacao >= date('2025-10-01', '-14 day') and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD14,
        sum(case when dataCriacao >= date('2025-10-01', '-28 day') and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD28,
        sum(case when dataCriacao >= date('2025-10-01', '-56 day') and qtdePontos < 0 then qtdePontos else 0 end) as qtdPontosNegVidaD56
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
        dataCriacao,
        24 * (max(julianday(DtCriacao)) - min(julianday(DtCriacao))) as duracao
    from tb_transacao
    group by idCliente, dataCriacao
),

tb_hora_cliente as(
    select
        idCliente,
        sum(duracao) as duracaoHorasVida,
        sum(case when dataCriacao >= date('2025-10-01', '-7 day') then duracao else 0 end) as qtdHorasD7,
        sum(case when dataCriacao >= date('2025-10-01', '-14 day') then duracao else 0 end) as qtdHorasD14,
        sum(case when dataCriacao >= date('2025-10-01', '-28 day') then duracao else 0 end) as qtdHorasD28,
        sum(case when dataCriacao >= date('2025-10-01', '-56 day') then duracao else 0 end) as qtdHorasD56
    from tb_horas_dia
    group by idCliente
),

tb_lag_dia as (
    select 
        idCliente,
        dataCriacao,
        lag(dataCriacao) over (partition by idCliente order by dataCriacao) as lagdia
    from tb_horas_dia
),

tb_intervalo_dias as (
    select 
        idCliente,
        avg(julianday(dataCriacao) - julianday(lagdia)) as avgIntervaloDiasVida,
        avg(case when dataCriacao >= date('2025-10-01', '-28 day') then julianday(dataCriacao) - julianday(lagdia) end) as avgIntervaloDiasD28
    from tb_lag_dia
    group by idCliente
)

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
    