# =========================================================
# Proyecto: Marketing Analytics - Google Analytics Sample
# Nivel: Intermedio (KPIs + segmentación de canales con clustering)
# =========================================================

# ---- 1. Paquetes ----
# install.packages(c("bigrquery", "dplyr", "ggplot2", "scales", "factoextra"))
library(bigrquery)
library(dplyr)
library(ggplot2)
library(scales)
library(factoextra)  # para visualizar el clustering

# ---- 2. Conexión a BigQuery ----
bq_auth()
proyecto_id <- "TU_PROJECT_ID"  # reemplazar por tu Project ID de Google Cloud

consulta <- "
  SELECT
    CONCAT(fullVisitorId, CAST(visitId AS STRING)) AS session_id,
    PARSE_DATE('%Y%m%d', date) AS fecha,
    channelGrouping AS canal,
    trafficSource.source AS fuente,
    trafficSource.medium AS medio,
    trafficSource.campaign AS campaña,
    device.deviceCategory AS dispositivo,
    geoNetwork.country AS pais,
    totals.visits AS visitas,
    totals.pageviews AS pageviews,
    totals.timeOnSite AS tiempo_en_sitio,
    totals.bounces AS rebote,
    totals.transactions AS transacciones,
    ROUND(totals.transactionRevenue / 1e6, 2) AS ingresos_usd
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
"

tabla <- bq_project_query(proyecto_id, consulta)
datos <- bq_table_download(tabla)

# ---- 3. Limpieza básica ----
datos_limpios <- datos %>%
  mutate(
    pageviews = ifelse(is.na(pageviews), 0, pageviews),
    tiempo_en_sitio = ifelse(is.na(tiempo_en_sitio), 0, tiempo_en_sitio),
    transacciones = ifelse(is.na(transacciones), 0, transacciones),
    ingresos_usd = ifelse(is.na(ingresos_usd), 0, ingresos_usd),
    rebote = ifelse(is.na(rebote), 0, rebote),
    convirtio = transacciones > 0
  ) %>%
  distinct(session_id, .keep_all = TRUE)

glimpse(datos_limpios)

# ---- 4. KPIs por canal ----
kpis_canal <- datos_limpios %>%
  group_by(canal) %>%
  summarise(
    sesiones = n(),
    transacciones = sum(transacciones),
    ingresos = sum(ingresos_usd),
    tasa_conversion = round(mean(convirtio) * 100, 2),
    tasa_rebote = round(mean(rebote) * 100, 2),
    ingreso_por_sesion = round(sum(ingresos_usd) / n(), 2)
  ) %>%
  arrange(desc(sesiones))

print(kpis_canal)

# ---- 5. Gráfico: sesiones vs. tasa de conversión por canal ----
ggplot(kpis_canal, aes(x = sesiones, y = tasa_conversion, size = ingresos, label = canal)) +
  geom_point(color = "steelblue", alpha = 0.7) +
  geom_text(vjust = -1, size = 3) +
  scale_x_continuous(labels = comma) +
  labs(
    title = "Sesiones vs. Tasa de conversión por canal",
    subtitle = "Tamaño del punto = ingresos totales",
    x = "Sesiones", y = "Tasa de conversión (%)"
  ) +
  theme_minimal()

# ---- 6. Segmentación de canales con clustering (K-means) ----
# Agrupamos los canales según su performance: volumen, conversión e ingreso por sesión.
# Esto permite identificar, por ejemplo: "alto volumen/baja conversión" vs
# "bajo volumen/alta conversión" vs "canales de bajo rendimiento general".

datos_cluster <- kpis_canal %>%
  select(canal, sesiones, tasa_conversion, ingreso_por_sesion)

# Escalamos las variables (importante: kmeans es sensible a la escala)
datos_escalados <- datos_cluster %>%
  select(sesiones, tasa_conversion, ingreso_por_sesion) %>%
  scale()

set.seed(42)  # reproducibilidad
k_resultado <- kmeans(datos_escalados, centers = 3, nstart = 25)

datos_cluster$segmento <- factor(k_resultado$cluster)

print(datos_cluster)

# Visualización del clustering
fviz_cluster(k_resultado, data = datos_escalados,
             labelsize = 10,
             geom = "point",
             ellipse.type = "convex") +
  labs(title = "Segmentación de canales de marketing (K-means)") +
  theme_minimal()

# ---- 7. Embudo de conversión simplificado ----
# (usamos totales agregados; para el detalle por hit hay que traer la consulta 3 del SQL)
embudo <- data.frame(
  etapa = factor(c("Sesiones", "Con transacción"), levels = c("Sesiones", "Con transacción")),
  cantidad = c(nrow(datos_limpios), sum(datos_limpios$convirtio))
)

ggplot(embudo, aes(x = etapa, y = cantidad, fill = etapa)) +
  geom_col(width = 0.6) +
  scale_fill_manual(values = c("steelblue", "darkorange")) +
  scale_y_continuous(labels = comma) +
  labs(title = "Embudo simplificado: sesiones vs. conversiones", x = "", y = "Cantidad") +
  theme_minimal() +
  theme(legend.position = "none")

# ---- 8. Exportar datasets limpios para Tableau ----
write.csv(datos_limpios, "datos_limpios_marketing.csv", row.names = FALSE)
write.csv(datos_cluster, "segmentacion_canales.csv", row.names = FALSE)
