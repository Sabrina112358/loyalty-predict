select dtRef,
     descLifeCycle,
     cluster,
     count(*) as qtdClientes
from life_cycle
group by dtRef, descLifeCycle
order by dtRef, descLifeCycle
