# Execute Test Notebook in Databricks with PowerShell

[[_TOC_]]

## Problem
You need to use PowerShell to run Databricks test notebook, wait for the execution to finish and get the results.

## Solution
Use the [_Execute-DatabricksTestNotebook.ps1_](https://dev.azure.com/cbsp-abnamro/GRD0001030/_git/devops_circle?path=%2Fsrc%2Fpowershell%2FExecute-DatabricksTestNotebook.ps1) PowerShell script.

The script can be used from the command line or can be embedded into automated pipeline.

Here is an example of the script execution.

```powershell
.\Execute-DatabricksTestNotebook.ps1 `
            -NotebookPath $Env:DATABRICKS_TEST_NOTEBOOK_PATH `
            -BearerToken $Env:DATABRICKS_BEARER_TOKEN `
            -ClusterId $Env:DATABRICKS_CLUSTER_ID `
            -WriteRunUri `
            -WriteTestOutput
```

In this example, we provided Databricks Bearer Token, Databricks Cluster ID and Notebook Path parameters from environment variables. 

The `-WriteRunUri` switch causes the notebook run URI to be written to the host once the notebook is submitted.

The `-WriteTestOutput` switch instructs the script to print the test output once the execution is complete.

And the output:

```
https://westeurope.azuredatabricks.net/?o=8813556867527678#job/356/run/1

Running tests...
----------------------------------------------------------------------
  test_execute_multiple_times_not_duplicate (__main__.Test_loadtriggerfiledetails) ... FAIL (29.148s)
  test_execute_on_empty_table_loads_list (__main__.Test_loadtriggerfiledetails) ... ok (14.511s)

======================================================================
FAIL [29.148s]: test_execute_multiple_times_not_duplicate (__main__.Test_loadtriggerfiledetails)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "<command-22373905743853>", line 57, in test_execute_multiple_times_not_duplicate
    self.assertEqual(count_1, count_2)
AssertionError: 4 != 8

----------------------------------------------------------------------
Ran 2 tests in 43.776s

FAILED (failures=1)

Generating XML reports...

Test unsuccessful
At C:\Sandbox\repos\devops_circle\src\powershell\Execute-DatabricksTestNotebook.ps1:160 char:5
+     Throw "Test unsuccessful"
+     ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Test unsuccessful:String) [], RuntimeException
    + FullyQualifiedErrorId : Test unsuccessful
```

As you can see the test has failed due to assertion failure.

## Discussion

The _Execute-DatabricksTestNotebook.ps1_ script supports number of useful features:

* Retrieve bearer token from Azure Key Vault
* Retrieve Databricks cluster ID from Azure Key Vault
* Write (dump) test output to host
* Write (dump) notebook run URI to host
* Save test output to a file
* Save text XML report to a file
* Export and save notebook output to HTML file
* Save the notebook result to a JSON file

### Retrieve bearer token from Azure Key Vault

You can specify the bearer token as a command line argument, but can optionally specify an Azure Key Vault secret where the bearer token is stored.

To retrieve the bearer token from Key Vault, you need to provide two parameters: `-KeyVaultName` and `-BearerTokenSecretName`. When `-BearerTokenSecretName` is provided, the `-BearerToken` parameter is ignored. Here is an example:

```powershell
.\Execute-DatabricksTestNotebook.ps1 `
            -NotebookPath $Env:DATABRICKS_TEST_NOTEBOOK_PATH `
            -KeyVaultName $Env:KEY_VAULT_NAME `
            -BearerTokenSecretName $Env:DATABRICKS_BEARER_TOKEN_SECRET `
            -ClusterId $Env:DATABRICKS_CLUSTER_ID `
            -URI $Env:DATABRICKS_URI `
            -WriteRunUri `
            -WriteTestOutput
```

### Retrieve cluster ID from Azure Key Vault

You can specify the Databricks cluster ID as a command line argument, but can optionally specify an Azure Key Vault secret where the cluster ID is stored.

To retrieve the Databricks cluster ID from Key Vault, you need to provide two parameters: `-KeyVaultName` and `-ClusterIdSecretName`. When `-ClusterIdSecretNameis provided, the `-ClusterId` parameter is ignored. Here is an example:

```powershell
.\Execute-DatabricksTestNotebook.ps1 `
            -NotebookPath $Env:DATABRICKS_TEST_NOTEBOOK_PATH `
            -KeyVaultName $Env:KEY_VAULT_NAME `
            -BearerToken $Env:DATABRICKS_BEARER_TOKEN `
            -ClusterIdSecretName $Env:DATABRICKS_CLUSTER_ID_SECRET `
            -URI $Env:DATABRICKS_URI `
            -WriteRunUri `
            -WriteTestOutput
```

### Write (dump) test output to host

To write the test output to the host, specify the `-WriteTestOutput` parameter. This will instruct the script to print the test output to the host after the notebook execution has finished.

### Write (dump) notebook run URI to host

To write the test notebook run URI to host, specify the `-WriteRunUri` parameter. This will instruct the script to print the notebook run URI to the host once the notebook is submitted to the cluster.

### Save test output to a file

If you provide `-TestOutputFilePath` parameter, the script will save the test output to a text file with the specified name.

### Save text XML report to a file

If you provide `-XmlReportFilePath` parameter, the script will save the test XML report to a file with the specified name.

### Export and save notebook output to HTML file

If you provide `-NotebookOutputFilePath` parameter, the script will export the notebook output and save it in HTML file.

### Save the notebook result to a JSON file

If you provide `-ResultFilePath` parameter, the script will save the full notebook result to a JSON file.



### On Databricks Test Notebooks

Databricks test notebooks should return JSON formatted exit result. For example:

```python
import json
test_result = run_unittest(Test_loadtriggerfiledetails)
print(test_result['run_output'])
dbutils.notebook.exit(json.dumps(test_result))
```



You could use `run_unittest` helper function from the the following extract:

```python
import subprocess
import sys
import io
import datetime
import unittest
import inspect

def install_package(package):
    """Install Python package with pip executed in subprocess."""
    subprocess.check_call([sys.executable, "-m", "pip", "install", package])

def run_unittest_suite(suite):
    """Execute unittest suite and return run output."""
    try:
        import xmlrunner
    except ModuleNotFoundError:
        install_package('unittest-xml-reporting')
        import xmlrunner
    with io.StringIO() as stream_fh:
        with io.BytesIO() as report_fh:
            runner = xmlrunner.XMLTestRunner(output=report_fh, stream=stream_fh, verbosity=2)
            start_time = datetime.datetime.utcnow()
            run_result = runner.run(suite)
            end_time = datetime.datetime.utcnow()
            output_content = stream_fh.getvalue()
            report_content = report_fh.getvalue().decode()
    
    result = {
        'was_successful': run_result.wasSuccessful(),
        'num_errors': len(run_result.errors),
        'num_failures': len(run_result.failures),
        'num_skipped': len(run_result.skipped),
        'num_successes': len(run_result.successes),
        'start_time': start_time.isoformat(),
        'end_time': end_time.isoformat(),
        'execution_time': end_time.timestamp() - start_time.timestamp(),
        'run_output': output_content,
        'xml_report': report_content,
    }
    return result


def run_unittest_testcase(test_case:unittest.TestCase):
    """Execute unittest TestCase and return run output."""
    assert inspect.isclass(test_case), "test_case must be a class"
    assert issubclass(test_case, unittest.TestCase), "test_case must be unittest.TestCase"
    suite = unittest.TestLoader().loadTestsFromTestCase(test_case)
    return run_unittest_suite(suite)

def run_unittest(test):
    """Execute unittest TestCase or TestSuite and return run output"""
    if isinstance(test, unittest.TestSuite):
        return run_unittest_suite(test)
    elif inspect.isclass(test) and issubclass(test, unittest.TestCase):
        return run_unittest_testcase(test)
    else:
        raise TypeError("test must be unittest TestCase or TestSuite")

```



