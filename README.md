# Salesforce DX Project: Next Steps

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## CI/CD Pipeline

This project includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) that automates Salesforce deployments with three stages:

1. **Code Quality** - Runs Salesforce Code Analyzer (fails on severity 1 issues)
2. **Validate** - Validates deployment with RunLocalTests
3. **Deploy** - Deploys to Salesforce org (only on push to main/develop branches)

### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

- `SF_AUTH_URL` - Salesforce authentication URL (generate with `sf org generate url`)

### Workflow Triggers

- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual workflow dispatch

### Artifacts

All job results are uploaded as artifacts:
- `scanner-results` - Code quality analysis reports (CSV and JSON)
- `validate-results` - Deployment validation results (JSON)
- `deploy-results` - Deployment results (JSON and deployment ID)

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
