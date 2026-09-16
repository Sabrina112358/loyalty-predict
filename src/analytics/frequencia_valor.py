# %%

import pandas as pd
import sqlalchemy
import matplotlib.pyplot as plt
from sklearn import cluster
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from sklearn import preprocessing
import seaborn as sns


# %%

engine = sqlalchemy.create_engine("sqlite:///../../data/loyalty-system/database.db")
# %%

def import_query(path):
    with open(path) as open_file:
        return open_file.read()

query = import_query("frequencia_valor.sql")
# %%

df = pd.read_sql_query(query, engine)

# Correção de um outlier causado por um bug no sistema de pontos, distorcendo a analise
df = df[df["qtdPontos"] <= 4000]

df.head()

# %%

plt.plot(df['qtdFrequencia'], df['qtdPontos'], 'o')
plt.grid("True")
plt.xlabel("Frequência")
plt.ylabel("Valor")
plt.show()
 # %%

minmax = preprocessing.MinMaxScaler()

X = minmax.fit_transform(df[["qtdFrequencia", "qtdPontos"]])
df_X = pd.DataFrame(X, columns=["normFrequencia", "normPontos"])

# Evaluate K from 2 to min(10, n_samples - 1)
k_values = range(2, min(10, len(X) - 1) + 1)
silhouette_scores = []

for k in k_values:
    model = KMeans(n_clusters=k, n_init=10, random_state=42)
    labels = model.fit_predict(X)
    score = silhouette_score(X, labels)
    silhouette_scores.append((k, score))
    print(f"k={k}: silhouette={score:.4f}")

if not silhouette_scores:
    raise ValueError("Not enough data to evaluate clustering.")

best_k, best_score = max(silhouette_scores, key=lambda item: item[1])
print(f"Optimal number of clusters: {best_k} (silhouette={best_score:.4f})")
# %%

# Fit final model using the best k
kmean = KMeans(n_clusters=5, 
                  n_init=10, 
                  random_state=42, 
                  max_iter=1000)
kmean.fit(X)

df["cluster_calc"] = kmean.labels_
df_X["cluster_calc"] = kmean.labels_

# Plot silhouette score by number of clusters
plt.figure()
plt.plot([k for k, _ in silhouette_scores], [score for _, score in silhouette_scores], "o-")
plt.xlabel("Número de clusters")
plt.ylabel("Silhouette Score")
plt.title("Seleção do número ideal de clusters")
plt.grid(True)
plt.show()

# Plot clustered data
plt.figure()
plt.scatter(df["qtdFrequencia"], df["qtdPontos"], c=df["cluster_calc"], cmap="viridis", s=50)
plt.xlabel("Frequência")
plt.ylabel("Valor")
plt.title(f"Clusters (k={best_k})")
plt.grid(True)
plt.show()

# %%

sns.scatterplot(data=df_X, 
                x="normFrequencia", 
                y="normPontos", 
                hue="cluster_calc", 
                palette="viridis",
                )

plt.grid()
# %%

sns.scatterplot(data=df, 
                x="qtdFrequencia", 
                y="qtdPontos", 
                hue="cluster_calc", 
                palette="viridis",
                )

plt.hlines(y=1500, xmin = 0, xmax=25, colors='red')
plt.hlines(y=750, xmin = 0, xmax=25, colors='red')
plt.vlines(x=4, ymin=0, ymax=750, colors='red')
plt.vlines(x=10, ymin=0, ymax=3000, colors='red')

plt.grid()
# %%
sns.scatterplot(data=df, 
                x="qtdFrequencia", 
                y="qtdPontos", 
                hue="cluster", 
                palette="deep",
                )

plt.grid()
# %%
