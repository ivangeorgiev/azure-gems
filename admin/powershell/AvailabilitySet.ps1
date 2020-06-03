
$conf = @{
    'Location' = 'westeurope'
    'ResourceGroupName' = 'azadmin-demo1-rg'
}
$props = New-Object -TypeName psobject -Property $conf

New-AzResourceGroup -Name $conf.ResourceGroupName -Location $conf.Location

# https://azure.microsoft.com/en-in/resources/templates/101-availability-set-create-3fds-20uds/
$asConf = @{
    'ResourceGroupName' = $props.ResourceGroupName
    'TemplateFile' = 'C:\Sandbox\repos\azure-gems\admin\powershell\AvailabilitySetTemplate.json'
    'TemplateParameterObject' = @{
        'name' = 'availabilitySet101'
        'updateDomainCount' = '20'
        'faultDomainCount' = '5'
    }
}
New-AzResourceGroupDeployment @asConf
Get-AzComputeResourceSku | where{$_.ResourceType -eq 'availabilitySets' -and $_.Name -eq 'Aligned'}

Remove-AzResourceGroup -Name $conf.ResourceGroupName -Force
