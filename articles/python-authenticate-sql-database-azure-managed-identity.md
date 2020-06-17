# Authenticate with Azure SQL Database using Managed Identity in Python

## Introduction

To illustrate how to authenticate with Azure SQL Database using Azure Managed Identity in Python, we are going to use a simple Web App scenario:

* Web App is running inside App Service, using Python 3.7 runtime
* Application is implemented using Python's Flask
* Web App is using Azure SQL Database to persist data 

We are going to use:

* Azure Identity SDK for Python
* pyodbc Python library

## Application Source Code

In our example, we are using following application from github: 

* https://github.com/ivangeorgiev/azure-python-webapp-sqldb-managed-identity 

## Configure the Managed Identity

This activity involves two steps:

* [Enable managed identity for App Service](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity?tabs=python#using-the-azure-portal)

* [Enable managed identity for Azure SQL Database](https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-configure?tabs=azure-powershell#create-contained-database-users-in-your-database-mapped-to-azure-ad-identities)

  You could achieve this using SSMS:

  ```sql
  CREATE USER <your app service name> FROM EXTERNAL PROVIDER;
  ALTER ROLE db_datareader ADD MEMBER <your app service name>
  ALTER ROLE db_datawriter ADD MEMBER <your app service name>
  ALTER ROLE db_ddladmin ADD MEMBER <your app service name>
  ```

## Connect to SQL Database Using Managed Identity

To authenticate:

* Get Azure AD access token for accessing Azure SQL DB, using Azure Identity SDK for Python
* Create connection string with a token.
* Create pyodbc connection, using the connection string.

```python
def connect_db(server=None, database=None, driver=None):
    DB_SERVER = 'tcp:' + (server or os.environ['DB_SERVER']) + '.database.windows.net'
    DB_NAME = database or os.environ['DB_NAME']
    DB_DRIVER = driver or '{ODBC Driver 17 for SQL Server}'
    DB_RESOURCE_URI = 'https://database.windows.net/'

    az_credential = DefaultAzureCredential()
    access_token = az_credential.get_token(DB_RESOURCE_URI)
    
    token = bytes(access_token.token, 'utf-8')
    exptoken = b"";
    for i in token:
        exptoken += bytes({i});
        exptoken += bytes(1);
    tokenstruct = struct.pack("=i", len(exptoken)) + exptoken;
    
    connection_string = 'driver='+DB_DRIVER+';server='+DB_SERVER+';database='+DB_NAME
    conn = pyodbc.connect(connection_string, attrs_before = { 1256:bytearray(tokenstruct) });
    
    return conn
```



## Deploy the application

* Create Azure Web App
  * Select Python 3.7 as runtime
* In the Web App blade, section Deployment Center,
  * Select GitHub and configure using Kudu services

## Testing the application

Open the application root: [https://\<web-app-name\>.azurewebsites.net/](https://<web-app-name>.azurewebsites.net/) 

You should see the Azure SQL Database version:

```json
{
   "rows":[
      {
         "":"Microsoft SQL Azure (RTM) - 12.0.2000.8 \n\tMay 15 2020 00:47:08 \n\tCopyright (C) 2019 Microsoft Corporation\n"
      }
   ]
}
```



For more exciting output, try opening the `/tables` endpoint.



### Reference

* https://docs.microsoft.com/en-us/azure/app-service/containers/how-to-configure-python
* https://docs.microsoft.com/en-us/sql/connect/python/pyodbc/step-3-proof-of-concept-connecting-to-sql-using-pyodbc?view=sql-server-ver15
* https://docs.microsoft.com/en-us/sql/connect/odbc/using-azure-active-directory?view=sql-server-ver15

