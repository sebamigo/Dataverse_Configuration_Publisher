# Microsoft Dynamics 365 CRM Configuration Publisher

This repository demonstrates how to automate deploying Dynamics 365 CRM configurations (e.g., Business Units, Teams, and security role assignments) across multiple environments.

### Why Configuration Publisher for Microsoft Dynamics 365?

- **Consistent configurations across environments:**  
    Automated deployment ensures that settings are identical in multiple environments.

- **Version control with Git:**   
    Every change is documented and easy to review.

- **Automation and repeatability:**  
    Configurations can be deployed reliably and automatically at any time, minimizing manual errors.

- **Fast rollbacks and easy migration:**  
    Quickly revert to previous versions or migrate configurations between environments if needed.

- **Improved collaboration:**  
    Teams can work on configurations in parallel and leverage pull requests for review.

**Important!**
The Microsoft Dyanmics data types still need to be aligned in the code. 

Configurations are stored as yaml files, processed by the script, and applied to a Microsoft Dynamics 365 (Dataverse) environment.

**At a glance**
- Purpose: Automatically create/update records and create relationships (associations) in Microsoft Dynamics 365 based on yaml configurations.
- Input: yaml configuration files in [data/configurations](data/configurations) / [tests/TestConfigurations](tests/TestConfigurations).
- Core scripts:
  - Deployment entry point: [DeployConfiguration](scripts/DeployConfiguration.ps1)
  - Publisher logic: [Publish-Configuration](scripts/ConfigPublisher.psm1)
  - Helper functions: [CommonTools](lib/CommonTools.psm1) (`Write-Log`, `Out-Banner`) and [DynamicsTools](lib/DynamicsTools.psm1) (utilities for Microsoft Dynamics 365 CRM)

Key functions/modules
- [`Publish-Configuration`](scripts/ConfigPublisher.psm1) — processes yaml files, creates/updates records via `Set-CrmRecord`, and manages relationships (Associate/Disassociate).
- [`FlatFieldsDatatypes`](scripts/ConfigPublisher.psm1) — converts extended data types found in yaml fields (e.g., `$refByField`, `$refBySecRole`, `$file`).

## Dependencies
Install the following tools/modules:

- **Pester (for tests)**  
  Install the Pester PowerShell module:  
  ```powershell
  Install-Module -Name Pester
  ```

- **Pester (for tests)**  
  Install the Pester PowerShell module:  
  ```powershell
  Install-Module -Name powershell-yaml
  ```

- **Microsoft.Xrm.Tooling.CrmConnector.PowerShell**  
  PowerShell module for connecting to Microsoft Dynamics CRM.
  ```powershell
  Install-Module -Name Microsoft.Xrm.Tooling.CrmConnector.PowerShell
  ```

- **Microsoft.Xrm.Data.PowerShell**  
  PowerShell module for working with Microsoft Dynamics CRM data.
  ```powershell
  Install-Module -Name Microsoft.Xrm.Data.PowerShell
  ```
Make sure all modules above are installed to run the project scripts.

## How to deploy (locally)
1. Ensure the required PowerShell modules are installed (see above).
2. Configure the yaml files under [data/configurations](data/configurations).
3. Run the deploy script (interactive CRM connection):
   ```powershell
   .\scripts\DeployConfiguration.ps1 -ConfigPath ".\data\configurations"
   ```
4. Sign in to Microsoft Dynamics 365.
5. The script applies the configurations to Dataverse.

It's best to thoroughly test your configurations first! :)

**How to run tests**
- In VS Code: Use the "Run Pester tests" task (see [.vscode/tasks.json](.vscode/tasks.json)).
- Manually:
  ```powershell
  Import-Module Pester;
  Invoke-Pester;
  ```
- **Important!** The tests use an in-memory mock repository ([tests/CrmMock/CrmConnector.Mock.psm1](tests/CrmMock/CrmConnector.Mock.psm1)), allowing you to validate the publisher logic without a live Dynamics instance. This helps verify that the yaml configurations are set up correctly.

## More
**Extended data types in yaml**

- Some yaml fields support extended types that the publisher resolves on load and converts into appropriate CRM/PowerShell objects. These extended types let you describe complex references, files, or special data types cleanly in the yaml configurations. Resolution is implemented in [`DynamicsTools`](lib/DynamicsTools.psm1).


Examples — common scenarios
- Lookup by field (user by name):

```yaml
{
  "ownerid": { "$refByField": { "entity": "systemuser", "Field": "name", "Operator": "eq", "Value": "Max Mustermann" } }
}
```

- Security role reference for team assignment:

```yaml
{
    "logicalName": "teamroles_association",
    "func": "Associate",
    "recordRef1": { "$refByField": { "entity": "team", "field": "name", "operator": "eq", "value": "Reading Marketing Team" } },
    "recordRef2": { "$refBySecRole": { "SecRoleName": "Accounts Read Only", "BusinessUnitName": "Marketing" } }
}
```

See [data/configurations](data/configurations) for examples of the expected yaml structure.