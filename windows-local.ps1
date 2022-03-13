

Get-WinSystemLocale | Format-List *
Write-Output "x-----------------x"

(Get-WinSystemLocale).TextInfo
Write-Output "x-----------------x"

chcp.com
Write-Output "x-----------------x"

get-itemproperty HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage | Select-Object OEMCP, ACP
Write-Output "x-----------------x"
# https://serverfault.com/questions/80635/how-can-i-manually-determine-the-codepage-and-locale-of-the-current-os/836221#836221
