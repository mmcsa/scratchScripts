# Stop an existing firewall
Function stop-firewall
{
    $fwName = "mmfta-wvdfw-fw"
    $rgName = "mmfta-VNet-rg"
    $fwVnetName = "mmfta-dev-vNET"
    $fwPipName = "mmfta-wvdfw-pip"

    $azfw = Get-AzFirewall -Name $fwName -ResourceGroupName $rgName
    $azfw.Deallocate()
    Set-AzFirewall -AzureFirewall $azfw
}
# Start a firewall
Function start-Firewall
{
    $fwName = "mmfta-wvdfw-fw"
    $rgName = "mmfta-VNet-rg"
    $fwVnetName = "mmfta-dev-vNET"
    $fwPipName = "mmfta-wvdfw-pip"
    $azfw = Get-AzFirewall -Name $fwName -ResourceGroupName $rgName
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName -Name $fwVnetName
    $publicip = Get-AzPublicIpAddress -Name $fwPipName -ResourceGroupName $rgName
    $azfw.Allocate($vnet,$publicip)
    Set-AzFirewall -AzureFirewall $azfw
}