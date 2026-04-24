# Architecture and DevOps Workflow

## Runtime Architecture

- API: ASP.NET Core 8 Web API running in Linux App Service container.
- Container image: stored in Azure Container Registry.
- Secrets: stored in Azure Key Vault and referenced by App Service settings.
- Database: Azure Database for PostgreSQL Flexible Server (optional toggle in Terraform).
- Monitoring: Application Insights with Log Analytics workspace.

## Deployment Flow

1. Push to GitHub `main`.
2. CI runs restore, build, test, and Docker build smoke check.
3. CD logs into Azure, builds image, pushes to ACR.
4. CD updates App Service container image to new tag.
5. App Service restarts and serves new version.
6. Health check endpoint verifies runtime status.

## Terraform Strategy

- All resources are provisioned from `infra/terraform`.
- Variables enable student-cost tuning.
- DB creation is controlled by `create_postgres`.

## Monitoring Checklist

- Validate availability in Application Insights.
- Track failed requests and response times.
- Review container logs in App Service log stream.
- Alert manually on repeated health endpoint failures.
