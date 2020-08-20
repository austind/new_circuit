
$BasePath = "C:\Users\adecoup\code\panos_config"
. "$BasePath\config.ps1"
$Networks = Import-Csv $BasePath\networks.csv
$CmdPrefix = "set vsys vsys1"


Function Get-NetworkObject {
    Param (
        $Name,
        $NetworkID
    )
    If ($Name) {
        Return $Networks | ? { $_.name -eq $Name }
    }
    If ($NetworkID) {
        Return $Networks | ? { $_.network_id -eq $NetworkID}
    }
}

Function Get-PANOSAddressObjectName {
    Param(
        $Net
    )
    Return "$($Net.network_id)-$($Net.prefix_length)"
}

Function Get-PANOSAddressObjectConfig {
    $Cfg = @()
    ForEach ($Net in $Networks) {
        If ($Net.network_object) {
            $AddressObjectName = Get-PANOSAddressObjectName -Net $Net
            $CIDR = "$($Net.network_id)/$($Net.prefix_length)"
            $Description = "$SiteName $($Net.Name)"
            $CfgPrefix = "$CmdPrefix address $AddresObjectName"
            $Cfg += "$CfgPrefix ip-netmask $CIDR "
            $Cfg += "$CfgPrefix description `"$Description`""
            $Cfg += "$CfgPrefix tag `"$PANOSTag`""
        }
    }
    Return $Cfg
}

Function Get-PANOSAddressGroupConfig {
    $Cfg = @()
    $CfgPrefix = "$CmdPrefix address-group"
    $GroupPrefix = $($SiteName -replace '\s+', '').toUpper()
    $AllNetworksGroupName = "$GroupPrefix-NETWORKS"
    ForEach ($Group in $PANOSNetworkGroupMap.GetEnumerator()) {
        $GroupName = "$GroupPrefix-$($Group.Key)"
        ForEach ($NetName in $Group.Value) {
            $Net = Get-NetworkObject -Name $NetName
            $AddressObjectName = Get-PANOSAddressObjectName -Net $Net
            $Cfg += "$CfgPrefix $GroupName static $AddressObjectName"
            $Cfg += "$CfgPrefix $AllNetworksGroupName static $AddressObjectName"
        }
        $Cfg += "$CfgPrefix $GroupName tag `"$PANOSTag`""
    }
    $Cfg += "$CfgPrefix $AllNetworksGroupName tag `"$PANOSTag`""
    Return $Cfg
}

Function Create-IPAMSubnets {
    # 2020-08-20:
    #   Solarwinds API does not appear to allow creation of IPAM folders ('hierarchy groups')
    #   The API is further limited in that it can only create subnet objects in "hierarchy groups",
    #   not "groups" (subgroups within hierarchy groups). This means we cannot use the API to create subnets
    #   using our existing group/subgroup schema.
    # https://documentation.solarwinds.com/en/success_center/IPAM/Content/IPAM-SWIS-API-to-perform-IPAM-operations.htm
    Import-Module SwisPowerShell
    If (!$Swis -and !$OrionServer) {
        $OrionServer = $Global:OrionServer = Read-Host 'Orion IP or FQDN'
    }
    If (!$Swis) {
        $Swis = $Global:Swis = Connect-Swis -Hostname $OrionServer
    }
    ForEach ($Net in $Networks) {
        Invoke-SwisVerb $swis IPAM.SubnetManagement CreateSubnetForGroup @($Net.network_id, $Net.prefix_length, "IP Networks")
    }
}