# Ejercicio SQL Server en Docker

## Comando utilizado

docker run -d \
  --name sqlserver_utn \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=UTN_Bases2026!" \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2022-latest

## Verificación
- Contenedor en estado Up (ver captura docker-ps.png)
- Logs confirmando inicio correcto (ver captura logs-sqlserver.png)

## Conexión externa
- Servidor: localhost,1433
- Usuario: sa
- Resultado de SELECT @@VERSION: (ver captura conexion-exitosa.png)

