<#

.SYNOPSIS
Execute Databricks test notebook.

.DESCRIPTION
Execute Databricks test notebook.

Databricks ClusterId and/or bearer token can be provided as parameters or
retrieved from Key Vault.

Optionally you can:
- Write test output to host.
- Save test output to a text file.
- Save test XML report to a XML file.
- Export and save notebook output to a HTML file.
- Save the notebook result to a JSON file.

.EXAMPLE

Here is an example running a Databricks test notebook and saving all information
into files.

```powershell
.\Run-DatabricksTestNotebook.ps1 `
            -NotebookPath '/pytest-databricks-examples/Test-AssertEquals-DataFrames' `
            -BearerToken $Env:DATABRICKS_BEARER_TOKEN `
            -ClusterId $Env:DATABRICKS_CLUSTER_ID `
            -WriteTestOutput `
            -WriteRunUri `
            -TestOutputFilePath .dev/test_output.txt `
            -XmlReportFilePath .dev/xml_report.xml `
            -ResultFilePath .dev/test_result.json `
            -NotebookOutputFilePath .dev/test_notebook_output.html `
            -Verbose
```

.EXAMPLE

Here is an example running a Databricks test notebook with bearer token and cluster id
from Key Vault.

```powershell
.\Run-DatabricksTestNotebook.ps1 `
            -NotebookPath '/pytest-databricks-examples/Test-AssertEquals-DataFrames' `
            -BearerTokenSecretName 'databricks-bearer-token' `
            -ClusterIdSecretName 'databricks-cluster-id' `
            -WriteTestOutput `
            -WriteRunUri `
            -TestOutputFilePath .dev/test_output.txt `
            -XmlReportFilePath .dev/xml_report.xml `
            -ResultFilePath .dev/test_result.json `
            -NotebookOutputFilePath .dev/test_notebook_output.html `
            -KeyVaultName 'pydbr-kv' `
            -Verbose
```


#>
[cmdletbinding()]
param (
    # Test notebook to execute
    [Parameter(Mandatory = $true)]
    [string] $NotebookPath,
    # Run name for the execution
    [string] $RunName,
    # How long to wait for the execution to finish
    [Int] $TimeoutSeconds = 300,
    # How often to poll Databricks for the notebook run status
    [Int] $WaitIntervalMilliseconds = 3000,
    # Should write test output to host?
    [Switch] $WriteTestOutput,
    # Should write run URI to host?
    [Switch] $WriteRunUri,
    # Where to store the test output.
    [String] $TestOutputFilePath,
    # Where to store the XML report.
    [String] $XmlReportFilePath,
    # Where to store the notebook result.
    [String] $ResultFilePath,
    # Where to store the notebook output.
    [String] $NotebookOutputFilePath,

    [string] $BearerToken,
    [string] $ClusterId,
    [string] $URI = 'https://westeurope.azuredatabricks.net',
    [string] $BearerTokenSecretName,
    [string] $ClusterIdSecretName,
    [string] $KeyVaultName
)


. $PSScriptRoot/lib/Databricks.ps1

If ($BearerTokenSecretName) {
    Write-Verbose "Get bearer token from Key Vault secret $KeyVaultName::$BearerTokenSecretName"
    $BearerToken = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $BearerTokenSecretName).SecretValueText
}
If (!$BearerToken) {
    Throw "Cannot validate Databricks bearer token."
}

If ($ClusterIdSecretName) {
    Write-Verbose "Get cluster ID token from Key Vault secret $KeyVaultName::$ClusterIdSecretName"
    $ClusterId = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $ClusterIdSecretName).SecretValueText
}
If (!$ClusterId) {
    Throw "Cannot validate Databricks cluster ID."
}

If (!$RunName) { $RunName = "PSExecTest-$NotebookPath" }


Connect-Databricks -BearerToken $BearerToken -ClusterId $ClusterId -URI $URI

$RunId = (Submit-DatabricksNotebook -NotebookPath $NotebookPath -RunName $RunName).run_id
$RunMeta = (Wait-DatabricksRun -RunId $RunId -TimeoutSeconds $TimeoutSeconds -WaitIntervalMilliseconds $WaitIntervalMilliseconds)

$RunResult = (Get-DatabricksRunOutput -RunId $RunId).notebook_output.result

If ($WriteRunUri) {
    Write-Host $RunMeta.run_page_url
}

If ($WriteTestOutput) {
    Write-Host $RunResult.run_output
}


If ($ResultFilePath) {
    ConvertTo-Json $RunResult -Depth 100 | Out-File -FilePath $ResultFilePath -Encoding utf8 -Force
}


If ($TestOutputFilePath) {
    Out-File -FilePath $TestOutputFilePath -Encoding utf8 -InputObject $RunResult.run_output -Force
}

If ($XmlReportFilePath) {
    Out-File -FilePath $XmlReportFilePath -Encoding utf8 -InputObject $RunResult.xml_report -Force
}

If ($NotebookOutputFilePath) {
    Write-Verbose "Export test notebook output to $NotebookOutputFilePath"
    $Export = (Export-DatabricksRun -RunId $RunId )
    foreach ($View in $Export) {
        If ($View.type -ne 'NOTEBOOK') { continue }
        Out-File -FilePath $NotebookOutputFilePath -Encoding utf8 -InputObject $View.content -Force
    }
}



If (!$RunResult.was_successful) {
    Throw "Test unsuccessful"
}




