#------------------------------------------------------------------------------ 
# 
# Copyright © 2015 Microsoft Corporation.  All rights reserved. 
# 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT 
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS 
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 
# 
#------------------------------------------------------------------------------ 
# 
# PowerShell Source Code 
# 
# NAME: 
#    2012_R2_Cluster_StoragePool.ps1 
# 
# VERSION: 
#    1.0
# 
#------------------------------------------------------------------------------ 

"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" Copyright © 2015 Microsoft Corporation.  All rights reserved. " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED `“AS IS`” WITHOUT " | Write-Host -ForegroundColor Yellow
" WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT " | Write-Host -ForegroundColor Yellow
" LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS " | Write-Host -ForegroundColor Yellow
" FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  " | Write-Host -ForegroundColor Yellow
" RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. " | Write-Host -ForegroundColor Yellow
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" PowerShell Source Code " | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
" NAME: " | Write-Host -ForegroundColor Yellow
"    2012_R2_Cluster_StoragePool.ps1 " | Write-Host -ForegroundColor Yellow
"" | Write-Host -ForegroundColor Yellow
" VERSION: " | Write-Host -ForegroundColor Yellow
"    1.0" | Write-Host -ForegroundColor Yellow
""  | Write-Host -ForegroundColor Yellow
"------------------------------------------------------------------------------ " | Write-Host -ForegroundColor Yellow
"" | Write-Host -ForegroundColor Yellow
"`n This script SAMPLE is provided and intended only to act as a SAMPLE ONLY," | Write-Host -ForegroundColor Yellow
" and is NOT intended to serve as a solution to any known technical issue."  | Write-Host -ForegroundColor Yellow
"`n By executing this SAMPLE AS-IS, you agree to assume all risks and responsibility associated."  | Write-Host -ForegroundColor Yellow

$ContinueAnswer = Read-Host "`n`tDo you wish to proceed at your own risk? (Y/N)"
If ($ContinueAnswer -ne "Y") { Write-Host "`n Exiting." -ForegroundColor Red;Exit }

$os = (Get-WmiObject -Class Win32_OperatingSystem).Version
if ( $os -like "6.3.*")
{
	$compname = [System.Net.Dns]::GetHostByName(($env:computerName))
	$fqdn = $compname.HostName
	$StorSub = Get-StorageSubSystem 
	foreach ($SubSystem in $StorSub)
	{
	    if (($SubSystem.Model -eq "Clustered Storage Spaces") -and ($SubSystem.AutomaticClusteringEnabled -eq $true)) {Set-StorageSubSystem -FriendlyName "$($SubSystem.FriendlyName)" -AutomaticClusteringEnabled $false}
		if ($SubSystem.Model -eq "Clustered Storage Spaces") {$StorageCluster = "$($SubSystem.FriendlyName)"}
	}
	$Interleave1 = new-object psobject
	Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Interleave -Value 65536 -Force
	Add-Member -InputObject $Interleave1 -MemberType NoteProperty -Name Workload -Value "Normal" -Force
	$Interleave2 = new-object psobject
	Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Interleave -Value 262144 -Force
	Add-Member -InputObject $Interleave2 -MemberType NoteProperty -Name Workload -Value "Data Warehousing" -Force
	[array] $Interleave += $Interleave1
	[array] $Interleave +=  $Interleave2
	
	$SelStripe = $Interleave | Out-GridView  -Title "Select Storage Spaces Stripe Value" -PassThru
	$StripeSize = $SelStripe.Interleave
	$Workload = $SelStripe.Workload
		If ($StripeSize)
		{
		Write-Host "`n[INFO] - Script will create spaces disk with $($Workload.tolower()) stripe value." -ForegroundColor Yellow
		Write-Host "`tSuccess"
		}
		Else
		{
		Write-Host "`tFailed to set stripe setting" -ForegroundColor Red
		Exit
		}
	try
	{
	$pool = Get-StorageSubSystem $StorageCluster | get-storagenode | ?{$_.Name -eq $fqdn} | Get-PhysicalDisk -canpool $true
	$DiskCount = $pool.count
	If ($DiskCount -lt 2) { Write-Host "`n Exiting. More than $DiskCount disk is required to build a storage pool" -ForegroundColor Red;Exit }
	Get-StorageSubSystem $StorageCluster | New-StoragePool -FriendlyName "$($env:computerName)Pool" -PhysicalDisks $pool | New-VirtualDisk -FriendlyName "$($env:computerName)Disk" -Interleave $StripeSize -NumberOfColumns $DiskCount -ResiliencySettingName simple –UseMaximumSize | Initialize-Disk -PartitionStyle GPT -PassThru |New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($env:computerName)Volume" -AllocationUnitSize 65536 -Confirm:$false
	}
	catch [System.Exception]
	{
	Write-host "$_ No disks found to add to pool." -ForegroundColor Red
	}
}
Else
{
	$os = "Unsupported"
	Write-host "Operating System: $os" -ForegroundColor Red
}