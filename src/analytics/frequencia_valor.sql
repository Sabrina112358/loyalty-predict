with tb_freq_valor as(
    select idCliente,
            count( distinct substr(DtCriacao,0,11)) as qtdFrequencia,
            sum(case when QtdePontos > 0 then QtdePontos else 0 end) as qtdPontos 
    from transacoes
    where DtCriacao < '2025-09-01' 
        and DtCriacao > date('2025-09-01', '-28 day')
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

select *
from tb_cluster

