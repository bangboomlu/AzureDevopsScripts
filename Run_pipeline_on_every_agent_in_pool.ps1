<#
Find the latest version of this script and contribute on GitHub: [AzureDevopsScripts](https://github.com/bangboomlu/AzureDevopsScripts)
#>

$organization = "YOUR_ORGANISATION"
$project = "YOUR_PROJECT"
$agentPoolId = "ID" #you can find this under collection settings -> agent pools -> your pool -> in the uri // or query https://dev.azure.com/$organisation/_apis/distributedtask/pools?api-version=$apiVersion
$buildDefinitionID = ""#you can find this under pipelines -> select the pipeline you want to run -> in the uri as definitionID=xxx // or query https://dev.azure.com/$organisation/$project/_apis/pipelines?api-version=$apiVersion
$pat = "YOUR_TOKEN"
$branch = "Your_BRANCH"
$apiVersion = "7.1-preview"


# Create a base64-encoded authorization header using the PAT
$base64AuthHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))


# Base URL for Azure DevOps REST API
$baseUrl = "https://dev.azure.com/$organization/$project/_apis/pipelines?api-version=$apiVersion"
$response = Invoke-RestMethod -Uri $baseUrl -Headers $headers -Method Get -Body $params

# Set API endpoint
$uri = "https://dev.azure.com/$organization/_apis/distributedtask/pools/$agentPoolId/agents?api-version=$apiVersion"

# Make API request
$response = Invoke-RestMethod -Uri $uri -Headers @{Authorization=("Basic {0}" -f $base64AuthHeader)} -Method Get

$uri = "https://dev.azure.com/$organization/$project/_apis/build/builds?api-version=$apiVersion"

# Parse and output agent details
$agents = $response.value
foreach ($agent in $agents) {
    Write-Host "Agent ID: $($agent.id)"
    Write-Host "Agent Name: $($agent.name)"
    Write-Host "Agent Status: $($agent.status)"
    Write-Host "Agent Enabled: $($agent.enabled)"

    $request = @{
        "definition" =
            @{
            "id" = "$buildDefinitionID"
            }
        "sourceBranch" = "refs/heads/$branch"
        "demands" = "AgentId -equals $($agent.id)"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $uri -Headers @{Authorization=("Basic {0}" -f $base64AuthHeader)} -Method Post -ContentType "application/json" -Body $request

    Write-Host "Pipeline run triggered. Build ID: $($response.id)"
    Write-Host "----------------------------------------"

}