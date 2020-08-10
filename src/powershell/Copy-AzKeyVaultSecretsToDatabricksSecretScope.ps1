<#

.SYNOPSIS
Copy all secrets from Azure Key Vault to Databricks secret scope.

.DESCRIPTION
This script copies all secrets from Azure Key Vault to Databricks secret scope.
If target secret scope doesn't exist, it will be created.

.EXAMPLE

Following example will copy all the secrets from Key Vault `my-key-vault` to 
Databricks secret scope named `all-secrets`

```powershell
.\Copy-AzKeyVaultSecretsToDatabricksSecretScope.ps1 `
      -KeyVaultName my-key-vault `
      -DatabricksAccessToken 'dapi123456abc' `
      -DatabricksScopeName 'all-secrets' `
      -Verbose
```

#>
[cmdletbinding()]
param (
    # Azure Key Vault name to copy secrets from.
    [Parameter(Mandatory = $true)]
    [string] $KeyVaultName,

    # Target Databricks scope.
    [Parameter(Mandatory = $true)]
    [string] $DatabricksScopeName,

    # Key Vault secret name. Optional.
    # If -DatabricksAccessToken is not specified, the token will be retrieved from the Key Vault secret.
    [string] $DatabricksAccessTokenSecret,

    # Databricks bearer token. Optional.
    # If not specified, bearer token will be retrieved by Key Vault. See -DatabricksAccessTokenSecret
	[string] $DatabricksAccessToken
)

Import-Module Az.KeyVault

. $PSScriptRoot/lib/Databricks.ps1

if ($DatabricksAccessToken) {
	Write-Verbose "... Using provided Databricks access token" 
} elseif ($DatabricksAccessTokenSecret) {
	Write-Verbose "... Token not provided. Using Key Vault secret $KeyVaultName/$DatabricksAccessTokenSecret"
	$DatabricksAccessToken = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $DatabricksAccessTokenSecret).SecretValueText
}

If (!$DatabricksAccessToken) {
    Throw "Cannot validate Databricks bearer token. Please provide a bearer token using -DatabricksAccessToken or a secret name using -DatabricksAccessTokenSecret and -KeyVaultName"  
}

Connect-Databricks -AccessToken $DatabricksAccessToken

Write-Verbose "... Copy key secrets from $KeyVaultName to Databricks scope $DatabricksScopeName" 

Write-Verbose "... Create Databricks secret scope $DatabricksScopeName"
Create-DatabricksSecretScope -ScopeName $DatabricksScopeName -Force

Get-AzKeyVaultSecret -VaultName $KeyVaultName | foreach {
    $Secret = $_
    $SecretName = $Secret.Name
    Write-Verbose "... Copy secret: $SecretName"
    $SecretValue = (Get-AzKeyVaultSecret -VaultName "$KeyVaultName" -Name "$SecretName").SecretValueText
    Set-DatabricksSecret -ScopeName $DatabricksScopeName -SecretName $SecretName -SecretValue $SecretValue
}

