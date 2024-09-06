if ((Get-LocalUser | where-Object Name -eq "rsivakumar").count -eq 0) {
$Exp_date = $(Get-Date).AddDays(90); $Password = ConvertTo-SecureString  "LO_hYARECB1XLir" -AsPlainText -Force; New-LocalUser "rsivakumar" -Password $Password -FullName "rsivakumar" -Description "rsivakumar@temenos.com" -AccountExpires $Exp_date -PasswordNeverExpires:$true; Add-LocalGroupMember -Group "Administrators" -Member "rsivakumar"; Add-LocalGroupMember -Group "Users" -Member "rsivakumar"
} else {
$Exp_date = $(Get-Date).AddDays(90); $Password = ConvertTo-SecureString  "LO_hYARECB1XLir" -AsPlainText -Force; Set-LocalUser "rsivakumar" -Password $Password -AccountExpires $Exp_date -PasswordNeverExpires $true -Description "rsivakumar@temenos.com"
}
