# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

$dirRoot = Get-Location
. $dirRoot/config.ps1

az group create --name "$storageAccountResourceGroupName" --location "$storageAccountResourceGroupLocation";
az storage account create --name "$storageAccountName" -g "$storageAccountResourceGroupName"
$storageCredentials = az storage account keys list -n "$storageAccountName" -g "$storageAccountResourceGroupName" | ConvertFrom-Json
az storage container create --account-name "$storageAccountName" --account-key $storageCredentials[0].value --name "$storageContainerName"