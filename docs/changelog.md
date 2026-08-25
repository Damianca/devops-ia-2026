## Hotfix de Producción - 25/08/2026
- **Responsable:** Luciano Bonafede
- **Problema detectado:** El sistema se encontraba en modo mantenimiento y con parámetros de réplicas incorrectos en producción.
- **Solución aplicada:** Se desactivó el modo mantenimiento, se estableció el ambiente en producción y se ajustaron las réplicas a 3 en el archivo app.yaml.
