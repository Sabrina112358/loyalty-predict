-- DAU: Daily Active Users

select substr(DtCriacao, 0, 11) as dtdia,
        count(distinct IdCliente) as dau
from transacoes
group by dtdia
order by dtdia