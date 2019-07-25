# Suppress script warnings
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

# Ensure configuration file is present
if (!(Test-Path .\config.json)) {
    Write-Error "config.json is not present. Please add it to your directory before proceeding..."
    exit
}

# Extract JSON config data
try {
    $config = Get-Content .\config.json | ConvertFrom-Json
} catch {
    Write-Error "Cannot parse config.json file. Make sure JSON format is correct..."
    exit
}

# Login to Azure account
Write-Output "Pulling Azure account credentials..."
Login-AzAccount

# Check if resource group has already been added
Get-AzResourceGroup `
    -Name $config.resourceGroup `
    -ErrorVariable notPresent `
    -ErrorAction SilentlyContinue

if ($notPresent)
{
    Write-Output ("Creating " + $config.resourceGroup + " resource group...")
    New-AzResourceGroup `
        -Name $config.resourceGroup `
        -Location $config.location
} else {
    Write-Output ("Resource group " + $config.resourceGroup + " already exists...")
}

# Create a subnet configuration
Write-Output "Creating subnet configuration..."
$subnetConfig = New-AzVirtualNetworkSubnetConfig `
                    -Name $config.subnetName`
                    -AddressPrefix 192.168.1.0/24

# Create a virtual network
Write-Output ("Creating " + $config.virtualNetworkName + " virtual network...")
$vnet = New-AzVirtualNetwork `
                -ResourceGroupName $config.resourceGroup `
                -Location $config.location `
                -Name $config.virtualNetworkName `
                -AddressPrefix 192.168.0.0/16 `
                -Subnet $subnetConfig

# Create an inbound network security group rule for port 3389
Write-Output "Creating inbound network security group for port 3389..."
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
                    -Name $config.networkSecurityGroupRuleRDPName `
                    -Protocol Tcp `
                    -Direction Inbound `
                    -Priority 1000 `
                    -SourceAddressPrefix * `
                    -SourcePortRange * `
                    -DestinationAddressPrefix * `
                    -DestinationPortRange 3389 `
                    -Access Allow

# Create a network security group
Write-Output ("Creating " + $config.networkSecurityGroupName + " network security group...")
$nsg = New-AzNetworkSecurityGroup `
            -ResourceGroupName $config.resourceGroup `
            -Location $config.location `
            -Name $config.networkSecurityGroupName `
            -SecurityRules $nsgRuleRDP

# Create virtual machine credentials
Write-Output "Pulling virtual machine credentials..."
$cred = Get-Credential -Message "Enter a username and password for the virtual machiness."

# Create each virtual machine
foreach ($vm in $config.vms) {

    # Create a public IP address and specify a DNS name
    Write-Output "Creating public IP address and specifying DNS name..."
    $pip = New-AzPublicIpAddress `
                -ResourceGroupName $config.resourceGroup `
                -Location $config.location `
                -Name "mypublicdns$(Get-Random)" `
                -AllocationMethod Static `
                -IdleTimeoutInMinutes 4

    # Create a virtual network card and associate with public IP address and NSG
    Write-Output "Creating virtual network card and associating with public IP address and Network Security Group..."
    $nic = New-AzNetworkInterface `
                -Name ($config.virtualNetworkName + $vm.name) `
                -ResourceGroupName $config.resourceGroup `
                -Location $config.location `
                -SubnetId $vnet.Subnets[0].Id `
                -PublicIpAddressId $pip.Id `
                -NetworkSecurityGroupId $nsg.Id

    # Create a virtual machine configuration
    Write-Output ("Creating " + $vm.name + " virtual machine configuration...")
    $vmConfig = New-AzVMConfig -VMName $vm.name -VMSize $vm.size | `
                Set-AzVMOperatingSystem -Windows -ComputerName $vm.name -Credential $cred | `
                Set-AzVMSourceImage -PublisherName $vm.publisherName -Offer $vm.offer -Skus $vm.skus -Version latest | `
                Add-AzVMNetworkInterface -Id $nic.Id

    # Create a virtual machine
    Write-Output ("Creating " + $vm.name + " virtual machine...")
    New-AzVM `
        -ResourceGroupName $config.resourceGroup `
        -Location $config.location `
        -VM $vmConfig `
        -Verbose `
        -AsJob
}
