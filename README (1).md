# Marketing Analytics - Google Analytics Sample

Proyecto de portfolio: SQL (BigQuery) + R + Tableau.
Enfoque combinado: performance de campañas (conversión/ingreso por canal) +
comportamiento de usuario (funnel), con segmentación de canales por clustering.

## Dataset
`bigquery-public-data.google_analytics_sample` — dataset público y gratuito de
BigQuery con datos reales (anonimizados) de tráfico y e-commerce de la Google
Merchandise Store. Cobertura: agosto 2016 - agosto 2017.

## Requisitos
- Cuenta de Google Cloud con un proyecto creado.
- R con los paquetes: `bigrquery`, `dplyr`, `ggplot2`, `scales`, `factoextra`.
- Tableau Public.

## Pasos

### 1. SQL (BigQuery)
`01_consultas_bigquery_marketing.sql` incluye:
- Performance por canal (channelGrouping)
- Performance por fuente/medio (útil para campañas pagas específicas)
- Embudo de conversión (vista de producto → carrito → compra, con UNNEST)
- Sesiones por dispositivo
- Vista consolidada a nivel sesión (la que usa R)

### 2. R (RStudio / Posit Cloud)
`02_analisis_marketing.R`:
- Se conecta a BigQuery y trae ~903.000 sesiones a nivel individual
- Limpia valores nulos (NA → 0 en columnas de conteo/ingreso)
- Calcula KPIs por canal: sesiones, transacciones, ingresos, tasa de
  conversión, tasa de rebote, ingreso por sesión
- Segmenta los canales con **K-means clustering** (variables escaladas:
  sesiones, tasa de conversión, ingreso por sesión) en 3 grupos
- Grafica el embudo simplificado y la visualización del clustering
- Exporta el CSV limpio para Tableau

### 3. Tableau
Dashboard con:
- 3 KPIs: sesiones totales, tasa de conversión global, ingresos totales
- Gráfico de dispersión de performance por canal (sesiones vs. ingresos,
  coloreado por segmento del clustering, tamaño = transacciones)
- Embudo de conversión (sesiones totales vs. sesiones con compra, mismo eje)

**Nota técnica:** el segmento de clustering se replicó en Tableau con un
campo calculado (`CASE [Canal] WHEN...`) en lugar de unir un segundo CSV,
para evitar depender de que el texto de los canales matchee exactamente
entre archivos.

## Estructura sugerida del repo
```
proyecto_marketing/
├── 01_consultas_bigquery_marketing.sql
├── 02_analisis_marketing.R
├── datos_limpios_marketing.csv       (generado por R)
├── dashboard_tableau.twbx
└── README.md
```

## Conclusiones

**1. Existe una tensión clara entre volumen de tráfico y calidad de conversión.**
El clustering separó automáticamente los canales en 3 perfiles bien diferenciados:
- **Alto volumen, bajo valor** (Organic Search, Social): concentran la mayor
  cantidad de sesiones (381K y 226K), pero con conversión mínima (0.9% y 0.05%)
  y alta tasa de rebote — sobre todo Social (65.2% de rebote).
- **Alto valor, bajo volumen** (Referral, Display): mueven mucho menos tráfico,
  pero con la mejor conversión (5.07% y 2.28%) y el mayor ingreso por sesión
  ($6.21 y $12.5) de todos los canales.
- **Rendimiento medio** (Direct, Paid Search, Affiliates, Other): un grupo más
  heterogéneo, sin destacarse fuerte en ninguna dimensión.

**2. El tráfico pago (Paid Search, Display) no está rindiendo lo esperado
para su naturaleza de inversión.**
Con conversión de apenas 1.85% y 2.28% respectivamente, estos canales pagos
convierten peor de lo que se esperaría de tráfico calificado — una señal
para revisar segmentación de campañas, landing pages o presupuesto asignado.

**3. La mayor pérdida del embudo ocurre en dos momentos distintos.**
Del funnel completo (vista de producto → carrito → compra): se pierde ~60%
entre ver un producto y agregarlo al carrito (posible fricción de UX/precio),
y otro ~77% entre agregar al carrito y confirmar la compra (clásico abandono
de checkout). La conversión global del sitio (sesiones → compra) es de solo
~1.3%, reforzando que la mayor oportunidad de mejora está en calificar mejor
el tráfico de bajo compromiso, no solo en atraer más visitas.

**4. Recomendación estratégica:** priorizar inversión en canales tipo
Referral (partnerships, programas de afiliados de calidad, comparadores) por
su alta conversión, mientras se optimiza el funnel de checkout para
capitalizar mejor el enorme volumen que ya trae Organic Search.
