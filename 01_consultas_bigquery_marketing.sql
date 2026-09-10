-- =========================================================
-- Proyecto: Marketing Analytics - Google Analytics Sample
-- Dataset público de BigQuery: bigquery-public-data.google_analytics_sample
-- Cobertura: 2016-08-01 a 2017-08-01 (Google Merchandise Store)
-- =========================================================

-- 1) Sesiones, transacciones e ingresos por canal (channelGrouping)
SELECT
  channelGrouping AS canal,
  COUNT(DISTINCT CONCAT(fullVisitorId, CAST(visitId AS STRING))) AS sesiones,
  SUM(totals.transactions) AS transacciones,
  ROUND(SUM(totals.transactionRevenue) / 1e6, 2) AS ingresos_usd,
  ROUND(SAFE_DIVIDE(SUM(totals.transactions), COUNT(DISTINCT CONCAT(fullVisitorId, CAST(visitId AS STRING)))) * 100, 2) AS tasa_conversion_pct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY canal
ORDER BY sesiones DESC;

-- 2) Performance por fuente/medio de tráfico (source/medium) - útil para campañas pagas
SELECT
  trafficSource.source AS fuente,
  trafficSource.medium AS medio,
  COUNT(DISTINCT CONCAT(fullVisitorId, CAST(visitId AS STRING))) AS sesiones,
  SUM(totals.transactions) AS transacciones,
  ROUND(SUM(totals.transactionRevenue) / 1e6, 2) AS ingresos_usd,
  ROUND(SAFE_DIVIDE(SUM(totals.transactionRevenue) / 1e6, SUM(totals.transactions)), 2) AS ticket_promedio
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY fuente, medio
HAVING sesiones > 100
ORDER BY sesiones DESC
LIMIT 30;

-- 3) Embudo de conversión (funnel): vista de producto -> carrito -> compra
-- Usa los códigos de eCommerceAction: 2 = vista de producto, 3 = agregar al carrito, 6 = compra
SELECT
  COUNT(DISTINCT CASE WHEN hits.eCommerceAction.action_type = '2' THEN CONCAT(fullVisitorId, CAST(visitId AS STRING)) END) AS vieron_producto,
  COUNT(DISTINCT CASE WHEN hits.eCommerceAction.action_type = '3' THEN CONCAT(fullVisitorId, CAST(visitId AS STRING)) END) AS agregaron_carrito,
  COUNT(DISTINCT CASE WHEN hits.eCommerceAction.action_type = '6' THEN CONCAT(fullVisitorId, CAST(visitId AS STRING)) END) AS compraron
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS hits
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801';

-- 4) Sesiones y conversión por tipo de dispositivo
SELECT
  device.deviceCategory AS dispositivo,
  COUNT(DISTINCT CONCAT(fullVisitorId, CAST(visitId AS STRING))) AS sesiones,
  SUM(totals.transactions) AS transacciones,
  ROUND(SUM(totals.transactionRevenue) / 1e6, 2) AS ingresos_usd
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
GROUP BY dispositivo
ORDER BY sesiones DESC;

-- 5) Vista consolidada a nivel sesión, para exportar a R (segmentación de campañas/canales)
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
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801';
