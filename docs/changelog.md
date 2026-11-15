# Changelog

## [1.0.1] - 2026-11-15
- **Responsable:** Fernando Mateo Vago Grecco
- **Problema detectado:** `MODO_MANTENIMIENTO=true` activo y parámetros incorrectos en `config/app.yaml`.
- **Solución aplicada:** Se configuró `ambiente: produccion`, `modo_mantenimiento: false` y `replicas: 3`.
