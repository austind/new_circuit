$BasePath = "C:\Users\adecoup\code\panos_config"
. "$BasePath\config.ps1"
$Networks = Import-Csv $BasePath\networks.csv
$PANOSCmdPrefix = "set vsys vsys1"


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

    $PANOSConfig = @()
    ForEach ($Net in $Networks) {
        If ($Net.network_object) {
            $AddressObjectName = Get-PANOSAddressObjectName -Net $Net
            $CIDR = "$($Net.network_id)/$($Net.prefix_length)"
            $Description = "$SiteName $($Net.Name)"
            $CfgPrefix = "$PANOSCmdPrefix address $AddresObjectName"
            $PANOSConfig += "$CfgPrefix ip-netmask $CIDR "
            $PANOSConfig += "$CfgPrefix description `"$Description`""
            $PANOSConfig += "$CfgPrefix tag `"$PANOSTag`""
        }
    }
    Return $PANOSConfig
}

Function Get-PANOSAddressGroupConfig {
    $PANOSConfig = @()
    $CfgPrefix = "$PANOSCmdPrefix address-group"
    $GroupPrefix = $($SiteName -replace '\s+', '').toUpper()
    $AllNetworksGroupName = "$GroupPrefix-NETWORKS"
    ForEach ($Group in $PANOSNetworkGroupMap.GetEnumerator()) {
        $GroupName = "$GroupPrefix-$($Group.Key)"
        ForEach ($NetName in $Group.Value) {
            $Net = Get-NetworkObject -Name $NetName
            $AddressObjectName = Get-PANOSAddressObjectName -Net $Net
            $PANOSConfig += "$CfgPrefix $GroupName static $AddressObjectName"
            $PANOSConfig += "$CfgPrefix $AllNetworksGroupName static $AddressObjectName"
        }
        $PANOSConfig += "$CfgPrefix $GroupName tag `"$PANOSTag`""
    }
    $PANOSConfig += "$CfgPrefix $AllNetworksGroupName tag `"$PANOSTag`""
    Return $PANOSConfig
}