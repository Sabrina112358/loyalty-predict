-- MAU: monthly active user

-- versao 1.0 
-- select substr(DtCriacao, 0, 8) as dtmes,
--         count(distinct IdCliente) as mau
-- from transacoes
-- group by dtmes
-- order by dtmes

-- versao 2.0: considerando somente 28 dias por mes, com a mesma quantidade de dias da semana para todos os meses

-- dias distintos que tiveram uma transacao na base
with tb_diario as (
    select distinct
        date(substr(DtCriacao, 0, 11)) as DtDia,
        IdCliente
    from transacoes
    order by DtDia
),

tb_dias_distintos as (
    select distinct DtDia as dtref
    from tb_diario
)

select
    t1.dtref,
    count(distinct t2.IdCliente) as mau,
    count(distinct t2.DtDia) as dias_ativos
from
    tb_dias_distintos t1
left join tb_diario t2 
    on  t2.DtDia <= t1.dtref
    and julianday(t1.dtref) - julianday(t2.DtDia) < 28
group by t1.dtref 
order by t1.dtref asc
