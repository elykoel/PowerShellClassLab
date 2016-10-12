﻿param (
  [string]$adAdminPassword,
  [string]$studentAdminPassword
)

# Import Azure Service Management module
Import-Module Azure
Import-Module AzureRM

function Get-RandomString ($length) {
  $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
  $result = ""
  for ($x = 0; $x -lt $Length; $x++) {
    $result += $set | Get-Random
  }
  return $result
}

# Common Variables
$location                   = 'eastus2'
$locationName               = "East US"
$masterResourceGroup        = "evil.training-master"
$dnsZone                    = "evil.training"
$studentCode                = "a" + (Get-RandomString 6)
$resourceGroupName          = $studentCode + '.' + $dnsZone
$studentSubnetName          = $studentCode + "subnet"
$studentSubnetAddressPrefix = "10.0.0.0/24"
$virtualNetworkName         = $studentCode + "vnet"
$virtualNetworkAddressRange = "10.0.0.0/16"
$studentAdminUsername       = "localadmin"
$storageAccountName         = $studentCode + "storage"    # Lowercase required
$URI                        = 'https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/azuredeploy.json'
$artifactsLocation          = "https://raw.githubusercontent.com/jaredhaight/AzureADLab/master/AzureADLab/"
$networkSecurityGroup       = "evil-training-nsg"

# DC Variables
$adAdminUserName            = "EvilAdmin"
$domainName                 = "ad." + $dnsZone
$adVMName                   = $studentCode + "-dc01"
$adNicName                  = $adVMName + "-nic"
$adNicIPAddress             = "10.0.0.4"
$adPublicIpName             = $adVMName + "-pip"
$adVmSize                   = "Basic_A1"
$adImagePublisher           = "MicrosoftWindowsServer"
$adImageOffer               = "WindowsServer"
$adImageSku                 = "2012-R2-Datacenter"

# Client Vars
$clientVMName               = $studentCode + "-home"
$clientNicName              = $clientVMName + "-nic"
$clientNicIpAddress         = "10.0.0.10"
$clientPublicIpName         = $clientVMName + "-pip"
$clientVMSize               = "Basic_A2"
$clientImagePublisher       = "MicrosoftWindowsServer"
$clientImageOffer           = "WindowsServer"
$clientImageSku             = "2012-R2-Datacenter"

# Server Vars
$serverVMName               = $studentCode+"-srv"
$serverNicName              = $serverVMName + "-nic"
$serverNicIpAddress         = "10.0.0.11"
$serverPublicIpName         = $serverVMName + "-pip"
$serverVMSize               = "Basic_A1"
$serverImagePublisher       = "MicrosoftWindowsServer"
$serverImageOffer           = "WindowsServer"
$serverImageSku             = "2012-R2-Datacenter"


# Linux Vars
$linuxVMName                = $studentCode+"-lnx"
$linuxNicName               = $linuxVMName + "-nic"
$linuxNicIpAddress          = "10.0.0.12"
$linuxPublicIpName          = $linuxVMName + "-pip"
$linuxVMSize                = "Basic_A2"
$linuxImagePublisher        = "Canonical"
$linuxImageOffer            = "UbuntuServer"
$linuxImageSku              = "16.04.0-LTS"

# Check if logged in to Azure
Try {
  Get-AzureRMContext -ErrorAction Stop
}
Catch {
  Login-AzureRmAccount
}

# Create the new resource group. Runs quickly.
try {
  Get-AzureRmResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
}
catch {
  New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
}

# Parameters for the template and configuration
$MyParams = @{
  artifactsLocation           = $artifactsLocation
  studentSubnetName           = $studentSubnetName
  studentSubnetAddressPrefix  = $studentSubnetAddressPrefix
  virtualNetworkName          = $virtualNetworkName
  virtualNetworkAddressRange  = $virtualNetworkAddressRange
  studentAdminUsername        = $studentAdminUsername
  studentAdminPassword        = $studentAdminPassword
  storageAccountName          = $storageAccountName
  networkSecurityGroup        = $networkSecurityGroup
  masterResourceGroup         = $masterResourceGroup
  adAdminUsername             = $adAdminUserName
  adAdminPassword             = $adAdminPassword
  domainName                  = $domainName
  adVMName                    = $adVMName
  adNicName                   = $adNicName
  adNicIpAddress              = $adNicIPaddress
  adPublicIpName              = $adPublicIpName
  adVMSize                    = $adVMSize
  adImagePublisher            = $adImagePublisher
  adImageOffer                = $adImageOffer
  adImageSku                  = $adImageSku
  clientVMName                = $clientVMName
  clientNicName               = $clientNicName
  clientNicIpAddress          = $clientNicIPaddress
  clientPublicIpName          = $clientPublicIpName
  clientVMSize                = $clientVMSize
  clientImagePublisher        = $clientImagePublisher
  clientImageOffer            = $clientImageOffer
  clientImageSku              = $clientImageSku
  serverVMName                = $serverVMName
  serverNicName               = $serverNicName
  serverNicIpAddress          = $serverNicIPaddress
  serverPublicIpName          = $serverPublicIpName
  serverVMSize                = $serverVMSize
  serverImagePublisher        = $serverImagePublisher
  serverImageOffer            = $serverImageOffer
  serverImageSku              = $serverImageSku
  linuxVMName                 = $linuxVMName
  linuxNicName                = $linuxNicName
  linuxNicIpAddress           = $linuxNicIPaddress
  linuxPublicIpName           = $linuxPublicIpName
  linuxVMSize                 = $linuxVMSize
  linuxImagePublisher         = $linuxImagePublisher
  linuxImageOffer             = $linuxImageOffer
  linuxImageSku               = $linuxImageSku
}

# Splat the parameters on New-AzureRmResourceGroupDeployment  
$SplatParams = @{
  TemplateUri                 = $URI 
  ResourceGroupName           = $resourceGroupName 
  TemplateParameterObject     = $MyParams
  Name                        = $studentCode + "-template"
}

New-AzureRmResourceGroupDeployment @SplatParams -Verbose

$ipInfo = (@{
  "publicIpName" = $adPublicIpName
  "vmName" = $adVMName  
}, 
@{
  "publicIpName" = $clientPublicIpName
  "vmName" = $clientVmName
},
@{
  "publicIpName" = $linuxPublicIpName
  "vmName"  = $linuxVMName
},
@{
  "publicIpName" = $serverPublicIpName
  "vmName"  = $serverVMName
}
)

forEach ($item in $ipInfo) {
  $pip = Get-AzureRmPublicIpAddress -Name $item.publicIpName -ResourceGroupName $resourceGroupName
  $record = (New-AzureRmDnsRecordConfig -IPv4Address $pip.IpAddress)
  $rs = New-AzureRmDnsRecordSet -Name $item.vmName -RecordType "A" -ZoneName $dnsZone -ResourceGroupName $masterResourceGroup -Ttl 10 -DnsRecords $record
}
