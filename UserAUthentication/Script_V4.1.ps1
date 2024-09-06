#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

function Login()  
{  
    $context = Get-AzContext  
  
    if (!$context)   
    {  
        Connect-AzAccount  
    }   
    else   
    {  
        Write-Host "Already connected"  
    }  
}  
function Get-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [int] $length
    )
    #$charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{]+-[*=@:)}$^%;(_!&amp;#?>/|.'.ToCharArray()
    $charSet = 'abcdefghijklmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ123456789'.ToCharArray()
    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[]($length)
 
    $rng.GetBytes($bytes)
 
    $result = New-Object char[]($length)
 
    for ($i = 0 ; $i -lt $length ; $i++) {
        $result[$i] = $charSet[$bytes[$i]%$charSet.Length]
    }
 
    return (-join $result)
}

 
$Scriptpath = split-path -parent $MyInvocation.MyCommand.Definition
$Logfile = "$Scriptpath\Password.log"
$CreateUsers=Import-CSV -path $Scriptpath\Input_File.csv

$WinFile="$Scriptpath\9WinPw_Commands.ps1"
$LinFile="$Scriptpath\9LinPw_Commands.sh"

if(!(Test-Path -Path $Logfile)){
    New-Item -ItemType File -Path $Logfile
    Write-Output "Creation_Time | User_Email | User_Name | Password | Expiry_Time | Client_Name | Asset_Detail" > $Logfile
}

if((Test-Path -Path $WinFile)){
    Remove-Item $WinFile
}

if((Test-Path -Path $LinFile)){
    Remove-Item $LinFile
}

Write-Host ""
#Write-Host '########## Check if User(s) exist ##########' -ForegroundColor Blue -BackgroundColor White
Write-Host "Check if User(s) exist - Windows" -ForegroundColor Yellow
ForEach ($item in $CreateUsers){
	$User_Name=$item.User_Name
	if ($User_Name -eq "") {
		$User_Name=($item.Email.split("@")[0] -replace "\W").ToLower()
	}
	$User_Name=$User_Name.ToLower()
	Write-Host "Get-LocalUser | Where-Object {`$_.Name -eq `"$User_Name`"} | Select-Object Name, passwordlastset, passwordexpires, accountexpires"
}
Write-Host ""

Write-Host "Check if User(s) exist - Linux" -ForegroundColor Yellow
ForEach ($item in $CreateUsers){
    $User_Name=$item.User_Name
	if ($User_Name -eq "") {
		$User_Name=($item.Email.split("@")[0] -replace "\W").ToLower()
	}
	$User_Name=$User_Name.ToLower()
    Write-Host "grep `'$User_Name`' /etc/passwd"
}

Write-Host ""
Write-Host "Output for sending to Users" -ForegroundColor Blue -BackgroundColor White

if( $Host -and $Host.UI -and $Host.UI.RawUI ) {
  $rawUI = $Host.UI.RawUI
  $oldSize = $rawUI.BufferSize
  $typeName = $oldSize.GetType( ).FullName
  $newSize = New-Object $typeName (1000, $oldSize.Height)
  $rawUI.BufferSize = $newSize
}

Write-Host "#!/bin/bash" 6> $LinFile

ForEach ($item in $CreateUsers){
	$User_Name=$item.User_Name
	if ($User_Name -eq "") {
		$User_Name=($item.Email.split("@")[0] -replace "\W").ToLower()
	}
	if ($User_Name.Length -ge 20){
		$User_Name = $User_Name.SubString(0,19)
	}
	$User_Email=$item.Email
	$User_Password=$item.Password.TrimStart("LO_")
	$Client=$item.Client
	$Asset=($item.Asset).Replace(',',';').Replace('|',';').Replace('`"','')
	if ($item.Account_Type -match "Database") {
		$Pwprefix='DB'
	} else {
		$Pwprefix='LO'
	}
    
	IF ([string]::IsNullOrWhitespace($User_Password))
	{
		$generatedpass=Get-RandomPassword 12
	} else {
		$generatedpass=$User_Password
	}
	
	#Write-Host "" 6>> $WinFile
	#Write-Host "########## $User_Email ##########" -ForegroundColor Blue -BackgroundColor White
	#Write-Host "Windows - $User_Email" -ForegroundColor Yellow
	write-Host "if ((Get-LocalUser | where-Object Name -eq `"$User_Name`").count -eq 0) {" 6>> $WinFile
	Write-Host '$Exp_date = $(Get-Date).AddDays(90); $Password = ConvertTo-SecureString '`"${Pwprefix}_${generatedpass}`"' -AsPlainText -Force; New-LocalUser '`"$User_Name`"' -Password $Password -FullName '`"$User_Name`"' -Description '`"$User_Email`"' -AccountExpires $Exp_date -PasswordNeverExpires:$true; Add-LocalGroupMember -Group "Administrators" -Member '`"$User_Name`"'; Add-LocalGroupMember -Group "Users" -Member '`"$User_Name`"'' 6>> $WinFile
	write-Host '} else {' 6>> $WinFile
	Write-Host '$Exp_date = $(Get-Date).AddDays(90); $Password = ConvertTo-SecureString '`"${Pwprefix}_${generatedpass}`"' -AsPlainText -Force; Set-LocalUser '`"$User_Name`"' -Password $Password -AccountExpires $Exp_date -PasswordNeverExpires $true -Description '`"$User_Email`"'' 6>> $WinFile
	write-Host '}' 6>> $WinFile
	Write-Host "" 6>> $WinFile
    #Write-Host "Linux - $User_Email" -ForegroundColor Yellow 
    Write-Host "" 6>> $LinFile
	Write-Host 'UsrExist=`getent passwd '$User_Name' | cut -d":" -f1`' 6>> $LinFile
	Write-Host 'if [ "$UsrExist" ='`"$User_Name`"' ]; then' 6>> $LinFile
	Write-Host "usermod -c `"$User_Email`" $User_Name" 6>> $LinFile
	Write-Host 'echo '`"$User_Name`:${Pwprefix}_${generatedpass}`"' | chpasswd' 6>> $LinFile
	Write-Host 'else' 6>> $LinFile
	Write-Host 'useradd -m '$User_Name -c `"$User_Email`"`;'echo '`"$User_Name`:${Pwprefix}_${generatedpass}`"' | chpasswd' 6>> $LinFile
	Write-Host 'fi' 6>> $LinFile
	Write-Host "if ! grep -Fxq `"$User_Name ALL = (ALL) ALL`" /etc/sudoers.d/waagent; then" 6>> $LinFile
	Write-Host "echo `"$User_Name ALL = (ALL) ALL`" >> /etc/sudoers.d/waagent" 6>> $LinFile
	Write-Host 'fi' 6>> $LinFile
	
	#$LogCon = Read-Host "Do you want to update the log file? - Y/[N]"
	#if (-not ([string]::IsNullOrEmpty($LogCon)) -and $LogCon -eq 'Y') { 
    $Exp_date= (Get-date).AddDays(90).ToString('dd/MMM/yyyy HH:mm:ss')
	$LogString = "$(Get-Date -Format "dd/MMM/yyyy HH:mm:ss") | $User_Email | $User_Name | ${Pwprefix}_${generatedpass} | $Exp_date | $Client | $Asset"
	Add-content $Logfile -value $LogString
	#write-Host ""
	write-Host "Email: $User_Email, Username : $User_Name, Password : ${Pwprefix}_${generatedpass}, Exp_Date: $Exp_date" -ForegroundColor Green
	#}
}
write-Host ""

Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

Login

# Start of Execution
$Scope = '/'
$roleassignmentdetails = Get-AzRoleEligibilitySchedule -Scope $scope -Filter "asTarget()"

$principalid = (Get-AzContext).Account.ExtendedProperties.HomeAccountId.split('.')[0]

$OutData = @()
$i = 0
foreach ($roleassingment in $roleassignmentdetails) {
    $Report = New-Object PSObject
	$start_time = Get-Date -Format o
    $guid = New-Guid
    $Report | Add-Member -Name "Id" -MemberType NoteProperty -Value $i
    $Report | Add-Member -Name "Subscription_ID" -MemberType NoteProperty -Value $roleassingment.RoleDefinitionId.split('/')[2]
    $Report | Add-Member -Name "ScopeDisplayName" -MemberType NoteProperty -Value $roleassingment.ScopeDisplayName
    $Report | Add-Member -Name "ScopeType" -MemberType NoteProperty -Value $roleassingment.ScopeType
    $Report | Add-Member -Name "RoleDefinitionDisplayName" -MemberType NoteProperty -Value $roleassingment.RoleDefinitionDisplayName
	$Report | Add-Member -Name "startTime" -MemberType NoteProperty -Value $start_time
	$Report | Add-Member -Name "roledefinitionid" -MemberType NoteProperty -Value $roleassingment.RoleDefinitionId
	$Report | Add-Member -Name "justification" -MemberType NoteProperty -Value 'Activities'
	$Report | Add-Member -Name "rolescope" -MemberType NoteProperty -Value $roleassingment.ScopeId
	$Report | Add-Member -Name "guidname" -MemberType NoteProperty -Value $guid.Guid
    $OutData += $Report
    $i++
}

Write-Host ($OutData | Select-Object Id, ScopeType, Subscription_ID, ScopeDisplayName | Format-Table | Out-String)

[int]$ActivateID = Read-Host "Key in the Id of the subscription you want to activate "

[int]$Min_Range = $outdata.Id |Select-Object -First 1
[int]$Max_Range = $outdata.Id |Select-Object -Last 1

If ($ActivateID -ge $Min_Range -and $ActivateID -le $Max_Range) {
	[int]$SubChk = (Get-AzSubscription | Where-Object {$_.ID -eq $OutData[$ActivateID].Subscription_ID}).Count
	if ($SubChk -eq 1) {
		Write-Host Subscription $OutData[$ActivateID].ScopeDisplayName is active..!!
		Set-AzContext -Subscription $OutData[$ActivateID].Subscription_ID
	} else {
		try {
			Write-Host Subscription $OutData[$ActivateID].ScopeDisplayName need to be Activated..!!
			New-AzRoleAssignmentScheduleRequest -Name $OutData[$ActivateID].guidname -Scope $OutData[$ActivateID].rolescope -ExpirationDuration PT8H -ExpirationType AfterDuration -PrincipalId $principalid -RequestType SelfActivate -RoleDefinitionId $OutData[$ActivateID].roledefinitionid -ScheduleInfoStartDateTime $OutData[$ActivateID].startTime -Justification $OutData[$ActivateID].justification -ErrorAction Stop  | out-null
        	Write-Host "Role Activated for" $OutData[$ActivateID].ScopeType - $OutData[$ActivateID].ScopeDisplayName as $OutData[$ActivateID].RoleDefinitionDisplayName -ForegroundColor Green
			Write-Host "Waiting - 180 Sec for permissions to take effect..!!"
			Start-Sleep -Seconds 180
			Set-AzContext -Subscription $OutData[$ActivateID].Subscription_ID
		} catch {
			if( $_.Exception.Message -like '*The Role assignment already exists*')
			{
				Write-Host "Permission already exists for" $OutData[$ActivateID].ScopeType - $OutData[$ActivateID].ScopeDisplayName as $OutData[$ActivateID].RoleDefinitionDisplayName -ForegroundColor Yellow
			} else
			{
				Write-Error $_.Exception.Message
				Write-Host -Message "Error Occured - Can not continue further..!!" -ForegroundColor Red -BackgroundColor White
				Exit
			}
		}
	}
}

$OutData = @()

[int]$Mode = Read-Host "Choose the trigger type 1.ENV, 2.VM [Enter ID]"

if ( $Mode -eq 1 ) {
	$SearchKey = Read-Host "Key in the Search String [ ENV1,ENV2,ENV3 ] "
	$intvar9 = $SearchKey.split(",")
	#$SearchKey1 = $SearchKey -replace '[^a-zA-Z]',''
	$VMList = foreach ($p in $intvar9) {Get-AzVM | Where-Object {($_.ResourceGroupName -like '*JUMP*' -Or $_.ResourceGroupName -like "*build*") -and $_.ResourceGroupName -like "*$p*" }}
} elseif ($Mode -eq 2 ) {
	$VMNames = Read-Host "Key in the VM Names [ VM1,VM2,VM3 ] "
	$tmpvmvar1 = $VMNames.split(",")
	$VMList = foreach ($j in $tmpvmvar1) {Get-AzVM | Where-Object { $_.Name -eq "$j" }}
} else {
		Write-Host "Invalid Input" -ForegroundColor DarkRed
	Exit
}

$i = 0
[int]$moveforward = 1
foreach ($vm in $VMList) {
$vmpwrstatus = (get-azvm -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status).Statuses[1].DisplayStatus
if ($vmpwrstatus -eq "VM running"){
	Write-Host VM "$($vm.ResourceGroupName)\$($vm.Name)" is in Running State -ForegroundColor Green
} elseif ($vmpwrstatus -eq "VM Stopped" -Or  $vmpwrstatus -eq "VM Deallocated") {
	[int]$moveforward = 0
	Write-Host Please start VM "$($vm.ResourceGroupName)\$($vm.Name)" before proceeding further..!! -ForegroundColor Yellow
	#Write-Host Starting VM $vm.ResourceGroupName - $vm.Name
	#Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
} else {
	Write-Host "$($vm.ResourceGroupName)\$($vm.Name)" is in $vmpwrstatus state - Requires manual interventsion..!! -ForegroundColor red -BackgroundColor white
	[int]$moveforward = 0
}
$Report = New-Object PSObject
$Report | Add-Member -Name "id" -MemberType NoteProperty -Value $i
$Report | Add-Member -Name "ResourceGroupName" -MemberType NoteProperty -Value $vm.ResourceGroupName
$Report | Add-Member -Name "Name" -MemberType NoteProperty -Value $vm.Name
$Report | Add-Member -Name "OS_Type" -MemberType NoteProperty -Value $vm.StorageProfile.OsDisk.OsType
$Report | Add-Member -Name "Status" -MemberType NoteProperty -Value $vmpwrstatus
$OutData += $Report
$i++
}
#$OutData | Out-GridView -Title "VMs"
#Exit

if ($moveforward -eq 0) {
	Write-Host ""
	Write-Host Can not proceed further - Exiting..!! -ForegroundColor red -BackgroundColor white
	$OutData | Format-Table
	Exit
}

$choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Y","&N")
While ($true) {
	  Write-Host "Final set of VM List below, Press N to remove items" -ForegroundColor Blue -BackgroundColor White
	  $OutData | Format-Table
	  $choice = $Host.UI.PromptForChoice("Do you want to Continue?","",$choices,0)
  		if ( $choice -ne 1 ) {
    	break
  	}
	  $RemoveVMID = Read-Host "Eneter VM ID's if you would like to remove [eg: 1,2,3]"
	  $intvar1 = $RemoveVMID.split(",")
	  foreach ($k in $intvar1) {
		  $OutData = $OutData | Where-Object { $_.ID -ne $k}
  }
}

if ( ($OutData | Measure-Object).Count -gt 0 ) {
	foreach ($pwrvm in $OutData) {
		If ($pwrvm.OS_Type -eq "Windows") {
			#Write-Host Resetting on $pwrvm.ResourceGroupName - $pwrvm.Name - $pwrvm.OS_Type -ForegroundColor Blue -BackgroundColor White
			Invoke-AzVMRunCommand -ResourceGroupName $pwrvm.ResourceGroupName -Name $pwrvm.Name -CommandId 'RunPowerShellScript' -ScriptPath "$WinFile"
		}
		If ($pwrvm.OS_Type -eq "Linux") {
			#Write-Host Resetting on $pwrvm.ResourceGroupName - $pwrvm.Name - $pwrvm.OS_Type -ForegroundColor Blue -BackgroundColor White
			Invoke-AzVMRunCommand -ResourceGroupName $pwrvm.ResourceGroupName -Name $pwrvm.Name -CommandId 'RunShellScript' -ScriptPath "$LinFile"
		}
	}
} else {
	Write-Host "Nothing to process" -ForegroundColor DarkRed
}
