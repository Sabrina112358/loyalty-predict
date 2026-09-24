with tb_usuario_cursos as (
    select 
        idUsuario,
        descSlugCurso,
        count(descSlugCurso) as qtdEps
    from cursos_episodios_completos
    where dtCriacao < '2025-10-01'
    group by idUsuario, descSlugCurso
),

tb_cursos_total_eps as (
    select
        descSlugCurso,
        count(descEpisodio) as qtdTotalEps
    from cursos_episodios
    group by descSlugCurso
),

tb_pct_cursos as (
    select
        t1.idUsuario,
        t1.descSlugCurso,
        1. * t1.qtdEps / t2.qtdTotalEps as pctCursoCompleto
    from 
        tb_usuario_cursos t1
    left join 
        tb_cursos_total_eps t2
        on t1. descSlugCurso = t2.descSlugCurso
),

tb_pivot_cursos as (
    select
        idUsuario,

        sum(case when pctCursoCompleto = 1 then 1 else 0 end) as qtdCursosCompletos,
        sum(case when pctCursoCompleto < 1 and pctCursoCompleto > 0 then 1 else 0 end) as qtdCursosIncompletos,
        sum(case when descSlugCurso = 'github-2025' then pctCursoCompleto else 0 end) as github2025,
        sum(case when descSlugCurso = 'python-2025' then pctCursoCompleto else 0 end) as python2025,
        sum(case when descSlugCurso = 'loyalty-predict-2025' then pctCursoCompleto else 0 end) as loyaltyPredict2025,
        sum(case when descSlugCurso = 'estatistica-2025' then pctCursoCompleto else 0 end) as estatistica2025,
        sum(case when descSlugCurso = 'machine-learning-2025' then pctCursoCompleto else 0 end) as machineLearning2025,
        sum(case when descSlugCurso = 'sql-2025' then pctCursoCompleto else 0 end) as sql2025,
        sum(case when descSlugCurso = 'carreira' then pctCursoCompleto else 0 end) as carreira,
        sum(case when descSlugCurso = 'pandas-2025' then pctCursoCompleto else 0 end) as pandas2025,
        sum(case when descSlugCurso = 'sql-2020' then pctCursoCompleto else 0 end) as sql2020,
        sum(case when descSlugCurso = 'pandas-2024' then pctCursoCompleto else 0 end) as pandas2024,
        sum(case when descSlugCurso = 'plataforma-ml-2026' then pctCursoCompleto else 0 end) as plataformaMl2026,
        sum(case when descSlugCurso = 'python-2024' then pctCursoCompleto else 0 end) as python2024,
        sum(case when descSlugCurso = 'ragia' then pctCursoCompleto else 0 end) as ragia,
        sum(case when descSlugCurso = 'estatistica-2024' then pctCursoCompleto else 0 end) as estatistica2024,
        sum(case when descSlugCurso = 'mlflow-2025' then pctCursoCompleto else 0 end) as mlflow2025,
        sum(case when descSlugCurso = 'github-2024' then pctCursoCompleto else 0 end) as github2024,
        sum(case when descSlugCurso = 'ds-databricks-2024' then pctCursoCompleto else 0 end) as dsDatabricks2024,
        sum(case when descSlugCurso = 'ml-2024' then pctCursoCompleto else 0 end) as ml2024,
        sum(case when descSlugCurso = 'nekt-2025' then pctCursoCompleto else 0 end) as nekt2025,
        sum(case when descSlugCurso = 'streamlit-2025' then pctCursoCompleto else 0 end) as streamlit2025,
        sum(case when descSlugCurso = 'lago-mago-2024' then pctCursoCompleto else 0 end) as lagoMago2024,
        sum(case when descSlugCurso = 'trampar-lakehouse-2024' then pctCursoCompleto else 0 end) as tramparLakehouse2024,
        sum(case when descSlugCurso = 'go-2026' then pctCursoCompleto else 0 end) as go2026,
        sum(case when descSlugCurso = 'f1-lake' then pctCursoCompleto else 0 end) as f1Lake,
        sum(case when descSlugCurso = 'speed-f1' then pctCursoCompleto else 0 end) as speedF1,
        sum(case when descSlugCurso = 'coleta-dados-2024' then pctCursoCompleto else 0 end) as coletaDados2024,
        sum(case when descSlugCurso = 'ds-pontos-2024' then pctCursoCompleto else 0 end) as dsPontos2024,
        sum(case when descSlugCurso = 'matchmaking-trampar-de-casa-2024' then pctCursoCompleto else 0 end) as matchmakingTramparDeCasa2024,
        sum(case when descSlugCurso = 'tse-analytics-2024' then pctCursoCompleto else 0 end) as tseAnalytics2024,
        sum(case when descSlugCurso = 'ia-canal-2025' then pctCursoCompleto else 0 end) as iaCanal2025

    from tb_pct_cursos
    group by idUsuario
),

tb_atividade as (
    select
        idUsuario,
        max(dtCriacao) as dtCriacao
    from habilidades_usuarios
    where dtCriacao < '2025-10-01'
    group by idUsuario
    union all
    select 
        idUsuario,
        max(dtCriacao) as dtCriacao
    from cursos_episodios_completos
    where dtCriacao < '2025-10-01'
    group by idUsuario
    union all 
    select 
        idUsuario,
        max(dtRecompensa) as dtCriacao
    from recompensas_usuarios
    where dtRecompensa < '2025-10-01'
    group by idUsuario
),

tb_ultima_atividade AS (
    select idUsuario,
            MIN( julianday('{date}') - julianday(dtCriacao)) AS qtdDiasUltiAtividade
    from tb_atividade
    group by idUsuario
),

tb_join as (
    select t3.idTMWCliente as idCliente,
        t1.qtdCursosCompletos,
        t1.qtdCursosIncompletos,
        t1.github2025,
        t1.python2025,
        t1.loyaltyPredict2025,
        t1.estatistica2025,
        t1.machineLearning2025,
        t1.sql2025,
        t1.carreira,
        t1.pandas2025,
        t1.sql2020,
        t1.pandas2024,
        t1.plataformaMl2026,
        t1.python2024,
        t1.ragia,
        t1.estatistica2024,
        t1.mlflow2025,
        t1.github2024,
        t1.dsDatabricks2024,
        t1.ml2024,
        t1.nekt2025,
        t1.streamlit2025,
        t1.lagoMago2024,
        t1.tramparLakehouse2024,
        t1.go2026,
        t1.f1Lake,
        t1.speedF1,
        t1.coletaDados2024,
        t1.dsPontos2024,
        t1.matchmakingTramparDeCasa2024,
        t1.tseAnalytics2024,
        t1.iaCanal2025,
        t2.qtdDiasUltiAtividade
    from tb_pivot_cursos t1
    left join tb_ultima_atividade t2
        on t1.idUsuario = t2.idUsuario
    inner join usuarios_tmw t3
        on t1.idUsuario = t3.idUsuario
)

select date('2025-10-01', '-1 day') as dtRef,
    *
from tb_join