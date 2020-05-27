<#

#>

$conf = @{
    'Location' = 'westeurope'
    'ResourceGroupName' = 'azadmin-demo-rg'
    'KeyVaultName' = 'azadmin-demo-kv'
    'KeyVaultPermissions' = 'list,get,set,delete'.split(',')
    'UserPrincipalName' = 'ivan.georgiev_gmail.com#EXT#@ivangeorgievgmail.onmicrosoft.com'
    'SecretName' = 'MySecret'
    'SecretValue' = 'Not Your Business'
}

$props = New-Object -TypeName psobject -Property $conf

$kvConf = @{
    'ResourceGroupName' = $props.ResourceGroupName
    'Name' = $props.KeyVaultName
    'Location' = $props.Location
}
$kvProps = New-Object -TypeName psobject -Property $kvConf

# Create Resource Group
New-AzResourceGroup -Name $props.ResourceGroupName -Location $props.Location

# Create Key Vault
New-AzKeyVault @kvConf

Get-AzKeyVault -VaultName $conf.KeyVaultName -ResourceGroupName $conf.ResourceGroupName

Get-AzKeyVaultSecret -VaultName $conf.KeyVaultName  # -> Forbidden

# Add Access Policy
Get-AzADUser -UserPrincipalName $conf.UserPrincipalName
Set-AzKeyVaultAccessPolicy -VaultName $kvProps.Name -EmailAddress $conf.UserPrincipalName -PermissionsToSecrets $conf.KeyVaultPermissions

# Add Secret to Key Vault
$secretValue = ConvertTo-SecureString -String $conf.SecretValue -AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $conf.KeyVaultName -Name $conf.SecretName -SecretValue $secretValue

# List Secrets
$secret = Get-AzKeyVaultSecret -VaultName $conf.KeyVaultName
$secret

# Get Secret from Key Vault
$secret = Get-AzKeyVaultSecret -VaultName $conf.KeyVaultName -Name $conf.SecretName
$secret.SecretValueText

# Remove Secret From Key Vault
Remove-AzKeyVaultSecret -VaultName $conf.KeyVaultName -Name $conf.SecretName -Force

# Remove Key Vault
Remove-AzKeyVault -VaultName $kvProps.Name -ResourceGroupName $kvProps.ResourceGroupName -Force


# Remove the Resource Group
Remove-AzResourceGroup -Name $props.ResourceGroupName -Force
