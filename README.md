# Azure Virtual Machine Powershell Script

Automates Azure virtual machine creation with Powershell. Make sure you have a subscription and Azure account set up before following the below steps. 

## Installation

1. Make sure you have Git installed. 
2. Clone repository with `git clone https://github.com/OpticGenius/AzureVMCreate.git`
3. [Install Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-2.4.0)

## Configuration

Create a `config.json` file in the same folder as the `vmcreate.ps1` script, and follow the format below:

```
{
    "resourceGroup": "beijing",
    "location": "East Asia",
    "virtualNetworkName": "myVirtualNetwork",
    "subnetName": "mySubnet",
    "networkSecurityGroupName": "myNetworkSecurityGroup",
    "networkSecurityGroupRuleRDPName": "myNetworkSecurityGroupRuleRDP",
    "vms": [
        {
            "name": "server1",
            "size": "Standard_D1",
            "publisherName": "MicrosoftWindowsServer",
            "offer": "WindowsServer",
            "skus": "2016-Datacenter"
        },
        {
            "name": "server2",
            "size": "Standard_D1",
            "publisherName": "MicrosoftWindowsServer",
            "offer": "WindowsServer",
            "skus": "2019-Datacenter"
        }
    ]
}
```

The above is an example of creating two Windows Servers with resource group *beijing* located in *East Asia*. 

You can have a look at the [Windows Virtual Machines Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/) to customize your virtual machines to your liking. 

## Running Script

Run `vmcreate.ps1` inside your direcory

    PS PATH> .\vmcreate.ps1 

Where **PATH** is your local path to the cloned repo. 

Observe your azure portal and wait for your virtual machines to get created. 