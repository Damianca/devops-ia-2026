# Laboratorio CI/CD: GitHub Actions, Terraform y EC2 (rama develop_Oliva)

Pipeline que valida y despliega una página HTML servida con Nginx en EC2.
GitHub Actions se autentica en AWS mediante OIDC (sin claves guardadas) y la
publicación usa SSM, sin SSH.

Repositorio: `Damianca/devops-ia-2026` · Rama de trabajo: `develop_Oliva`

## Cómo funciona

- **CI** (en push y pull request): `terraform fmt -check`, `terraform validate`,
  chequeo de sintaxis de los scripts y generación de `dist/index.html`. El HTML
  se sube como artefacto de GitHub.
- **CD** (solo en push a `develop_Oliva`): asume el rol de AWS por OIDC, inicializa
  el state remoto en S3, descarga el artefacto, aplica Terraform y publica la web
  con `scripts/deploy.sh`.
- **Artefacto**: el HTML generado en CI es el mismo que se despliega; se copia a
  `s3://<bucket>/artifacts/<sha>/index.html` y la instancia lo descarga por SSM.
- **State**: Terraform guarda su estado en el bucket S3 (prefijo `state/`), nunca
  en Git.
- **OIDC**: GitHub emite un token temporal; AWS lo canjea por credenciales de
  corta duración solo si coincide con la política de confianza del rol.

## Requisitos previos (se crean una vez, fuera del pipeline)

1. Bucket S3 para el state y los artefactos.
2. Proveedor OIDC de GitHub en IAM (`token.actions.githubusercontent.com`,
   audiencia `sts.amazonaws.com`).
3. Rol `GitHubActions-Role` con política de confianza restringida al `sub` de la
   rama `develop_Oliva` y permisos para EC2, SSM y el bucket.
4. Rol `lab-web-ec2` con instance profile `lab-web-ec2-profile`, la política
   `AmazonSSMManagedInstanceCore` y lectura de `artifacts/*` del bucket.
5. Variables del repositorio (Settings > Secrets and variables > Actions >
   Variables): `OLIVA_AWS_REGION`, `OLIVA_AWS_ROLE_ARN`, `OLIVA_STATE_BUCKET`.

## Ejecución

- **Desplegar**: hacer push a `develop_Oliva`. En Actions, el resumen del job `cd`
  muestra la URL de la web.
- **Actualizar la web**: editar `app/index.html` y hacer push.
- **Fallo controlado**: introducir un error de formato en un archivo `.tf`; el job
  `ci` falla y `cd` no se ejecuta.
- **Eliminar recursos**: Actions > CI-CD - Terraform y web > Run workflow, rama
  `develop_Oliva`, operación `destroy`.

## Qué queda tras el destroy

Se elimina lo que define `infra/` (VPC, subred, gateway, tabla de rutas, security
group e instancia EC2). Permanece lo previo: bucket S3, proveedor OIDC, rol
`GitHubActions-Role` y rol/perfil `lab-web-ec2`.

## Seguridad

No se versionan credenciales, `*.tfstate`, `.terraform/` ni `terraform.tfvars`.
La web se publica por HTTP y los permisos de EC2 son amplios: usar solo en una
cuenta de laboratorio.
