# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# Script settings, no reason to change those
$dirRoot = Get-Location
$templatesDir = "$dirRoot/ARM-templates"
$parametersModelDir = "$dirRoot/ARM-parameters"
$generatedDir = "$dirRoot/ARM-generated-templates"

#Load conf file
. $dirRoot/config.ps1

<#
.Description
Replace variables in ARM template (identified by [[var_name]]) by the values provided in this script
#>
function compileTemplates(){
    #Add username and password to windows machine ARM template
    (cat "$parametersModelDir/HE-HOL-WDEV-01.json")`
     -replace '\[\[windowsUser\]\]', $windowsUser`
     -replace '\[\[windowsPassword\]\]', $windowsPassword`
    | Out-File -encoding utf8 "$generatedDir/HE-HOL-WDEV-01.json"

    $sshKey = cat $sshPubKeyFilePath
    #Add username and ssh key to linux machine 1
    (cat "$parametersModelDir/HE-HOL-LDEV-01.json")`
     -replace '\[\[linuxUser\]\]', $linuxUser`
     -replace '\[\[sshKey\]\]', $sshKey`
    | Out-File -encoding utf8 "$generatedDir/HE-HOL-LDEV-01.json"

}

<#
.Description
Deploy a VM on the (global) resource group given it's template and parameters
#>
function deploy($templateFilename, $parametersFilename){
    az deployment group create `
        --resource-group $resGroupName `
        --template-file "$templatesDir/$templateFilename" `
        --parameters "$generatedDir/$parametersFilename"
}

function getMachinePublicIp($parameterModelFile){
    $machineName = (cat $parameterModelFile | ConvertFrom-Json).parameters.virtualMachineName.value
    return az vm list-ip-addresses -n $machineName `
        --query [0].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv
}

if(!(Test-Path $sshPubKeyFilePath) ){
    echo "No ssh key found at $sshPubKeyFilePath. Please refer to the guide to create a valid ssh key"
    exit -1
}

# Get target Azure subscription as default
$subscription = `
    az account list --query "[?name=='$subName']" | ConvertFrom-Json
az account set --subscription="$($subscription.id)"

# Creates the Lab's resource group 
az group create --name "$resGroupName" --location "$resGroupLocation";

# Prepare the machines ARM templates
compileTemplates

#Deploy the Windows dev virtual machine
deploy "HE-HOL-WDEV.json" "HE-HOL-WDEV-01.json"
#Deploy the first linux dev machine
deploy "HE-HOL-LDEV.json" "HE-HOL-LDEV-01.json"

#Get all the machines public Ip addresses
$windowsMachinePublicIp = getMachinePublicIp "$parametersModelDir/HE-HOL-WDEV-01.json"
$linuxMachine1PublicIp = getMachinePublicIp "$parametersModelDir/HE-HOL-LDEV-01.json"


echo "All Done ! You can now connect to the Windows development Machine with RDP: "
echo "(ip : $windowsMachinePublicIp, user: $windowsUser, password: $windowsPassword)"
echo "--"
echo "Linux machine 1 is available via ssh $linuxUser@$linuxMachine1PublicIp"
echo "Every resources are contained in the $resGroupName resource group on your Azure portal"