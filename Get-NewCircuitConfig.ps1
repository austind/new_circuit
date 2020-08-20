$BasePath = "C:\Users\adecoup\code\panos_config"
. "$BasePath\config.ps1"
$Networks = Import-Csv $BasePath\networks.csv
$PANOSCmdPrefix = "set vsys vsys1"


Function Get-PANOSAddressObjectConfig {

    $PANOSConfig = @()
    ForEach ($Net in $Networks) {
        If ($Net.network_object) {
            $Name = "$($Net.network_id)-$($Net.prefix_length)"
            $CIDR = "$($Net.network_id)/$($Net.prefix_length)"
            $Description = "$SiteName $($Net.Name)"
            $PANOSConfig += "$PANOSCmdPrefix address $Name ip-netmask $CIDR "
            $PANOSConfig += "$PANOSCmdPrefix address $Name description $Description"
        }
    }
    Return $PANOSConfig
}

