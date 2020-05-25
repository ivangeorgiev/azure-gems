<#

1. Create Azure Resource Group
2. Create Azure Resource Group Delete Lock
3. Remove Azure Resource Group Lock
4. Remove Azure Resource Group

#>

$rgConf = @{
    'name' = 'azadmin-demo-rg'
    'location' = 'westeurope'
}

$rgProps = New-Object -TypeName psobject -Property $rgConf

# Create Resource Group
New-AzResourceGroup @rgConf

# Get the Resource Group 
$rg = Get-AzResourceGroup -Name $rgProps.name
$rg

# List locks on Resource Group
$locks = Get-AzResourceLock -ResourceGroupName $rgProps.name
$locks.count

$lockConf = @{
    'LockName' = "$($rgProps.name)-lock"
    'ResourceGroupName' = $rgProps.name
    'lockLevel' = 'CanNotDelete' # Allowed: CanNotDelete or ReadOnly
}
$lockProps = New-Object -TypeName psobject -Property $lockConf
# Create a delete lock
New-AzResourceLock @lockConf -Force

# Get the lock
Get-AzResourceLock -LockName $lockProps.LockName -ResourceGroupName $lockProps.ResourceGroupName


# Remove the lock
Remove-AzResourceLock -LockName $lockProps.LockName -ResourceGroupName $rgProps.name -Force

# Remove the lock by Id
New-AzResourceLock @lockConf -Force
Remove-AzResourceLock -LockId (Get-AzResourceLock -Name $lockProps.LockName -ResourceGroupName $lockProps.ResourceGroupName).LockId -Force

# Remove the lock by Lock (piping)
New-AzResourceLock @lockConf -Force
$lock = Get-AzResourceLock -Name $lockProps.LockName -ResourceGroupName $lockProps.ResourceGroupName
$lock | Remove-AzResourceLock -Force

# Remove Resource Group
Remove-AzResourceGroup -Name $rgProps.name -Force

# Remove Resource Group by Id
New-AzResourceGroup @rgConf
Remove-AzResourceGroup -Id (Get-AzResourceGroup -Name $rgProps.name).ResourceId -Force
