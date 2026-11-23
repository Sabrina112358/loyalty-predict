# %%

import pandas as pd
import sqlalchemy
from sklearn import model_selection
import math
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import numpy as np 

from feature_engine import selection, imputation, encoding

pd.set_option("display.max_columns", None)
pd.set_option("display.max_rows", None)

con = sqlalchemy.create_engine("sqlite:///../../data/analytics/database.db")

# %%

## Funções Auxiliares

def plot_distribuicao(df, features, target=None, n_cols=4, bins=30, kde=True,
                      save_dir=None, filename="distribuicao.png", dpi=150):
    """
    Plota a distribuição de probabilidade (histograma normalizado + KDE)
    de cada variável numérica do dataframe.

    Parâmetros
    ----------
    df        : DataFrame com os dados (ex.: df_train)
    features  : lista com os nomes das colunas numéricas
    target    : (opcional) coluna binária; se informada, sobrepõe a
                distribuição de cada classe para comparar
    n_cols    : quantidade de gráficos por linha
    bins      : número de bins do histograma
    kde       : se True, desenha a curva de densidade (KDE)
    save_dir  : (opcional) diretório onde a imagem será salva;
                se None, a imagem não é salva
    filename  : nome do arquivo de saída (usado só se save_dir for informado)
    dpi       : resolução da imagem salva
    """
    n_rows = math.ceil(len(features) / n_cols)
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(4.5 * n_cols, 3.2 * n_rows))
    axes = axes.flatten() if len(features) > 1 else [axes]

    for ax, feature in zip(axes, features):
        serie = df[feature].dropna()

        # KDE falha em variáveis constantes, então desativa nesses casos
        usar_kde = kde and serie.nunique() > 1

        sns.histplot(
            data=df,
            x=feature,
            hue=target,
            bins=bins,
            stat="density",       # área total = 1 -> distribuição de probabilidade
            common_norm=False,    # normaliza cada classe separadamente
            kde=usar_kde,
            element="step",
            ax=ax,
        )
        ax.set_title(feature, fontsize=10)
        ax.set_xlabel("")
        ax.set_ylabel("Densidade")
        ax.grid(alpha=0.3)

    # Remove eixos vazios no final da grade
    for ax in axes[len(features):]:
        ax.set_visible(False)

    plt.tight_layout()

    # Step opcional: salvar a imagem (antes do show, que pode limpar a figura)
    if save_dir is not None:
        save_dir = Path(save_dir)
        save_dir.mkdir(parents=True, exist_ok=True)
        caminho = save_dir / filename
        fig.savefig(caminho, dpi=dpi, bbox_inches="tight")

    plt.show()

def analise_outliers(df, features, k=1.5, metodo="iqr", z=3.0):
    """
    Resume os outliers de cada variável numérica.

    Parâmetros
    ----------
    df       : DataFrame (ex.: df_train)
    features : lista de colunas numéricas
    k        : multiplicador do IQR (1.5 = padrão; 3 = apenas outliers extremos)
    metodo   : "iqr" (robusto, padrão) ou "zscore"
    z        : limite do z-score, usado só se metodo="zscore"

    Retorna
    -------
    DataFrame com uma linha por feature, ordenado por pctOutliers.
    """
    linhas = []

    for feature in features:
        serie = df[feature].astype(float).dropna()
        if serie.empty:
            continue

        q1, q3 = serie.quantile([0.25, 0.75])
        iqr = q3 - q1

        if metodo == "iqr":
            lim_inf, lim_sup = q1 - k * iqr, q3 + k * iqr
        elif metodo == "zscore":
            lim_inf = serie.mean() - z * serie.std()
            lim_sup = serie.mean() + z * serie.std()
        else:
            raise ValueError("metodo deve ser 'iqr' ou 'zscore'")

        qtd_inf = (serie < lim_inf).sum()
        qtd_sup = (serie > lim_sup).sum()
        p99 = serie.quantile(0.99)

        linhas.append({
            "feature": feature,
            "qtdNulos": df[feature].isna().sum(),
            "pctZeros": (serie == 0).mean() * 100,
            "media": serie.mean(),
            "mediana": serie.median(),
            "min": serie.min(),
            "q1": q1,
            "q3": q3,
            "p99": p99,
            "max": serie.max(),
            "limInf": lim_inf,
            "limSup": lim_sup,
            "qtdOutInf": qtd_inf,
            "qtdOutSup": qtd_sup,
            "pctOutliers": 100 * (qtd_inf + qtd_sup) / len(serie),
            # quanto o máximo está distante do p99: valores altos sugerem bug/valor isolado
            "ratioMaxP99": serie.max() / p99 if p99 != 0 else np.nan,
            "iqrZero": iqr == 0,  # sinal de que o método IQR não é confiável aqui
        })

    resumo = pd.DataFrame(linhas).set_index("feature")
    return resumo.sort_values("pctOutliers", ascending=False)


def plot_outliers(df, features, target=None, n_cols=4, clip_p99=False,
                  save_dir=None, filename="outliers.png", dpi=150):
    """
    Boxplot por feature. Com `target`, separa por classe.
    clip_p99=True limita o eixo ao percentil 99 para enxergar o corpo da distribuição.
    """
    n_rows = math.ceil(len(features) / n_cols)
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(4.5 * n_cols, 3.2 * n_rows))
    axes = np.array(axes).flatten()

    for ax, feature in zip(axes, features):
        sns.boxplot(
            data=df,
            x=target,
            y=feature,
            hue=target,
            legend=False,
            flierprops={"marker": ".", "markersize": 3, "alpha": 0.4},
            ax=ax,
        ) if target else sns.boxplot(
            data=df, y=feature,
            flierprops={"marker": ".", "markersize": 3, "alpha": 0.4}, ax=ax,
        )

        if clip_p99:
            ax.set_ylim(df[feature].min(), df[feature].quantile(0.99))

        ax.set_title(feature, fontsize=10)
        ax.set_xlabel("")
        ax.set_ylabel("")
        ax.grid(alpha=0.3)

    for ax in axes[len(features):]:
        ax.set_visible(False)

    plt.tight_layout()

    if save_dir is not None:
        save_dir = Path(save_dir)
        save_dir.mkdir(parents=True, exist_ok=True)
        fig.savefig(save_dir / filename, dpi=dpi, bbox_inches="tight")
        print(f"Imagem salva em: {save_dir / filename}")

    plt.show()

# %%

# Sample - Import dos Dados via SQlAlchemy

df = pd.read_sql("select * from abt_fiel", con=con)
df.head()

# %%

# Check - Dtypes
df.dtypes

# %%

# Sample - OOT

df_oot = df[df["dtRef"]>= "2025-09-01"]
df_oot

# %%

target = 'flFiel'
features = df.columns.tolist()[3:]

df_train_test = df[df["dtRef"] < "2025-09-01"].reset_index(drop=True)

y = df_train_test[target]  # vetor
X = df_train_test[features] # matriz

X_train, X_test, y_train, y_test = model_selection.train_test_split(
        X, y,
        random_state=42, 
        test_size=0.2,
        stratify=y)

print(f"Base Treino: {y_train.shape[0]} Unid | Tx. Target {100 * y_train.mean():.2f}%")
print(f"Base Teste: {y_test.shape[0]} Unid | Tx. Target {100 * y_test.mean():.2f}%")

# %%

# Explore - Bivariada Numérica

categorical_features = ['descLifeCycleAtual', 'descLifeCycleD28']
print("Features Categóricas: ", categorical_features)
print("Quantidade de Features Categóricas: ", len(categorical_features))

numerical_features = list(set(features) - set(categorical_features))
print("Features Numéricas: ", numerical_features)
print("Quantidade de Features Numéricas: ", len(numerical_features))

df_train = X_train.copy()
df_train[target] = y_train

df_train[numerical_features] = df_train[numerical_features].astype(float)

bivariada = df_train.groupby(target)[numerical_features].median().T
bivariada['ratio'] = ((bivariada [1] + 0.001) / (bivariada [0] + 0.001))
bivariada = bivariada.sort_values(by='ratio', ascending=False)
bivariada

# %%
# Explore - Bivariada Categórica

bivariada_catAtual = df_train.groupby('descLifeCycleAtual')[target].mean()
bivariada_catD28 = df_train.groupby('descLifeCycleD28')[target].mean()

print(bivariada_catAtual, " ", bivariada_catD28)

# %%

# Modify - DROP

X_train[numerical_features] = X_train[numerical_features].astype(float)

remove_numerical_features = bivariada[bivariada["ratio"] == 1].index.tolist()

print("Features Numéricas com Razão 1 (sem relação com o target): ", remove_numerical_features)
print("Quantidade de Features Numéricas com Razão 1: ", len(remove_numerical_features))

drop_num_features_median = selection.DropFeatures(features_to_drop=remove_numerical_features)

X_train_transformed = drop_num_features_median.fit_transform(X_train)

# %%

# Explore - Missing Values

df_missings = X_train_transformed.isna().mean()
df_missings = df_missings[df_missings > 0].sort_values(ascending=True)
df_missings


# %%

# Modify - Fill

fill_0_vars = ['python2025', 'qtdCursosCompletos']
fill_0 = imputation.ArbitraryNumberImputer(arbitrary_number=0, variables = fill_0_vars)

# Modify - Fill Categorical
imput_categ_desc = imputation.CategoricalImputer(fill_value='Novo-usuario', 
                                                 variables=['descLifeCycleAtual', 'descLifeCycleD28'])


imput_1000 = imputation.ArbitraryNumberImputer(
    arbitrary_number=1000,
    variables=['avgIntervaloDiasVida',
            'avgIntervaloDiasD28',
            'qtdDiasUltiAtividade'],
    )

## Modify - One Hot Encoding
onehot = encoding.OneHotEncoder(variables=categorical_features)

X_train_transformed = fill_0.fit_transform(X_train_transformed)
X_train_transformed = imput_categ_desc.fit_transform(X_train_transformed)
X_train_transformed = imput_1000.fit_transform(X_train_transformed)
X_train_transformed = onehot.fit_transform(X_train_transformed)
 # %%

## Analysis - Outliers and Distribution

features_train = X_train_transformed.columns.tolist()

# Distribuição separada por classe do target (Fiel x Não Fiel)
plot_distribuicao(
    X_train_transformed,
    sorted(features_train),
    target=y_train,
    save_dir="/home/sabrina/Documents/projetos/loyalty-predict/img",
    filename="distribuicao_por_target.png",
)

# %%

resumo = analise_outliers(X_train_transformed, features_train)
resumo