# ML — Recomendador

Motor de recomendación (Incremento 2) y experimentos.

## Estructura

```
recommender/    paquete Python del recomendador
experiments/    scripts y notebooks de experimentación
data/           datasets (no versionados; ver plan de datos IA)
```

## Principios

- `pgvector` es recuperación de candidatos; el ranking y la evaluación viven aquí (Python).
- La unidad principal de recomendación es el **restaurante**; los platos son atributos.
- Datos sintéticos para pipeline y pruebas técnicas; datos reales para validación experimental.

## Estado

Esqueleto. La primera versión funcional del recomendador (baseline por reglas) se implementa en FastAPI durante el MVP; el paquete Python se desarrolla en el Incremento 2.
