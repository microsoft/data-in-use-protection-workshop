# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.


#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/Az.Storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "3600"
$dirRoot = Get-Location
. $dirRoot/config.ps1

function getDiskName($machineName){
    return az disk list `
         --resource-group $resGroupName `
         -o tsv `
         --query " [?contains(name,'$machineName')].{Name:name} "
}

function copyDiskImage($machineName){

    $diskName = getDiskName $machineName
    # Set the context to the subscription Id where managed disk is created
    Select-AzSubscription -SubscriptionId $SubscriptionId

    #Generate the SAS for the managed disk 
    $sas = Grant-AzDiskAccess -ResourceGroupName $resGroupName -DiskName $diskName -DurationInSecond $sasExpiryDuration -Access Read 

    $storageCredentials = az storage account keys list -n $storageAccountName --resource-group "$storageAccountResourceGroupName" | ConvertFrom-Json
    #Create the context of the storage account where the underlying VHD of the managed disk will be copied
    $destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageCredentials[0].value

    $containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($sasExpiryDuration) -FullUri -Name $storageContainerName -Permission rw
    $containername, $sastokenkey = $containerSASURI -split "\?"
    $containerSASURI = "$containername/$machineName`?$sastokenkey"
    azcopy copy $sas.AccessSAS $containerSASURI --s2s-preserve-access-tier=false
}

# Get target Azure subscription as default
$subscription = `
    az account list --query "[?name=='$subName']" | ConvertFrom-Json

az account set --subscription="$($subscription.id)"

$subscriptionId = $subscription.id

# If $machineNames is set, export only these machines.
if (Get-Variable -Name machineNames -ErrorAction SilentlyContinue) {
  foreach ($machineName in $machineNames) {
    copyDiskImage $machineName
  }
}
# If not, export all VMs from the resource group
else{
  $machines = az vm list --resource-group $resGroupName -o json --query " [].{Name:name} " | ConvertFrom-Json
  foreach ($machineDesc in $machines) {
    copyDiskImage $machineDesc.name
  }
}

