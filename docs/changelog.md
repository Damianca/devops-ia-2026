## Hotfix de Producción - 25/08/2026
- **Responsable:** Luciano Bonafede
- **Problema detectado:** El sistema se encontraba en modo mantenimiento y con parámetros de réplicas incorrectos en producción.
- **Solución aplicada:** Se desactivó el modo mantenimiento, se estableció el ambiente en producción y se ajustaron las réplicas a 3 en el archivo app.yaml.

## Hotfix de producción — 13/10/2026

- Responsable: Maximiliano Perlo.
- Problema detectado: configuración defectuosa con modo de mantenimiento activado, ambiente incorrecto y una sola réplica.
- Solución aplicada: se estableció ambiente de producción, se desactivó el mantenimiento y se configuraron 3 réplicas.
- Contexto: reproducción controlada del incidente sobre una rama propia, dado que main ya contenía la corrección.
