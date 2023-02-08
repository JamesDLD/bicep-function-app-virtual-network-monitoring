# Introduction

Demonstrate how to track Azure Virtual Network IP addresses consumption.

For more details, you can consult the following article [Track IP addresses consumption with Azure Application Insights - Part 2](https://medium.com/@jamesdld23/track-ip-addresses-consumption-with-azure-application-insights-part-2-71243f1f7ddb).

# Clone the sample repository

Download the sample repository, run the following command in your local terminal window:

```
git clone https://github.com/JamesDLD/bicep-function-app-virtual-network-monitoring.git

```

# Deploy the Bicep file

Deploy the Bicep files using Azure CLI.

```
#variable
location=westeurope
resourceGroupName=exampleRG

#create the resource group
az group create --name $resourceGroupName --location $location

#use the 'what-if' option to see what the code will try to create or update
az deployment group what-if                                 \
                --resource-group $resourceGroupName         \
                --template-file function_app.bicep          \
                --parameters appInsightsLocation=$location 

#create the function app
az deployment group create                                  \
                --name function_app                         \
                --resource-group $resourceGroupName         \
                --template-file function_app.bicep          \
                --parameters appInsightsLocation=$location

#assign the azure built-in role to the function app
principalId=$(az deployment group show                                      \
                            --resource-group $resourceGroupName             \
                            --name function_app                             \
                            --query properties.outputs.principalId.value    \
                            --output tsv                                    )

az deployment sub create                                    \
                --location $location                        \
                --template-file role_assignment.bicep       \
                --parameters principalId=$principalId     

```

When the deployment finishes, you should see a message indicating the deployment succeeded.

# Validate the deployment

Use Azure CLI to validate the deployment.

```
az resource list --resource-group $resourceGroupName

```

# Perform a manual git deployment to the Azure Function App

Deploy the PowerShell code to the Function App using Azure CLI.

```

functionAppName=$(az deployment group show                                      \
                            --resource-group $resourceGroupName                 \
                            --name function_app                                 \
                            --query properties.outputs.functionAppName.value    \
                            --output tsv                                        )

az functionapp deployment source config             \
                --branch main                       \
                --manual-integration                \
                --name $functionAppName             \
                --resource-group $resourceGroupName \
                --repo-url https://github.com/JamesDLD/bicep-function-app-virtual-network-monitoring

```

# Clean up resources

```
az group delete --name $resourceGroupName

```
