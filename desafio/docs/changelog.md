## - 24/08/2026

### Correcion de errores
* **Fecha de correcion:** 24-08-2026
* **Responsable:** Thiago Tavella
* **Problema detectado:** Problema de configuracion en app.yaml
* **Solucion aplicada:** cambio en el modo de mantenimiento

## - 10/11/2026

### Correccion de errores
* **Fecha de correcion:** 10-11-2026
* **Responsable:** Lucas Galleguillo
* **Problema detectado:** app.yaml con claves en mayusculas y sin espacio despues de los dos puntos, por lo que el formato YAML era invalido y la configuracion de produccion no se interpretaba correctamente
* **Solucion aplicada:** claves en minuscula con formato YAML valido (ambiente: produccion, modo_mantenimiento: false, replicas: 3)

### Correccion de errores
* **Fecha de correcion:** 13-11-2026
* **Responsable:** rosales patricio
* **Problema detectado:** configuracion erronea en app.yaml
* **Solucion aplicada:** claves en minuscula con formato YAML valido (ambiente: produccion, modo_mantenimiento: false, replicas>
