
    function WaitForVMToComeUp {
    Param (
    $VMName   
    )

        $VMStartTime = Get-Date

        do {

            $TimeElapsed = $(Get-Date) - $VMStartTime

            If ($($TimeElapsed.TotalMinutes) -ge 3) {
            
                Write-Log -LogName $LogName -Message "VM is not up after 3 minutes" -ScriptPath $ScriptPath 

                return $false        
            }

            Start-Sleep -Seconds 2
    
        }

        until ((Get-VMIntegrationService $VMName | ?{$_.name -eq "Heartbeat"}).PrimaryStatusDescription -eq "OK")

        Start-Sleep -Seconds 60 
         
        return $true
    
    }

    function Reboot-VM {
        Param (
            $VMName        
        )
    
        Write-Output "Restarting the VM"
        Write-Log -LogName $LogName -Message "Restarting the VM" -ScriptPath $ScriptPath

        $VM = Get-VM -Name $VMName

        Stop-VM -VM $VM -Force
        Start-Sleep -Seconds 3
        Start-VM -VM $VM
        Start-Sleep -Seconds 3

        Write-Output "Waiting for the VM to come online"
        $VMIsUp = WaitForVMToComeUp -VMName $VMName    
    }

Function StartVMAndWait{
Param (
$VMToStart,
$LogName,
$ScriptPath
)
    Try {
        
        Write-Log -LogName $LogName -Message "[Status]Step8:Started" -ScriptPath $ScriptPath -NoTimeStamp

        Write-Output "Step8:Started"

        Write-Log -LogName $LogName -Message "Starting the VM" -ScriptPath $ScriptPath

        Write-Output "Starting the VM"
        
        Start-VM $VMToStart -ErrorAction Stop
   
        Write-Output "Waiting for the VM to come online"
        Write-Log -LogName $LogName -Message "Waiting for the VM to come online" -ScriptPath $ScriptPath

        $VMIsUp = WaitForVMToComeUp -VMName $VMToStart

        if (!$VMIsUp) {
                    
            Reboot-VM -VMName $VMToStart
        }

        $OS = (Get-VMData -VMname $VMToStart -LogName $LogName -ScriptPath $ScriptPath).OSName
        
        If ($OS) {

            Write-Log -LogName $LogName -Message "OS version is $OS" -ScriptPath $ScriptPath
            Write-Output "OS version is $OS"            
        }

        Else {
        
            Write-Log -LogName $LogName -Message "Couldn't retrieve the OS version" -ScriptPath $ScriptPath
            Write-Output "Couldn't retrieve the OS version"
        }

        if (!$VMIsUp) {
                
            Throw "VM is not up after 3 minutes. Pausing the script"
        }
    
        Write-Output "VM is online"
        Write-Log -LogName $LogName -Message "VM is online" -ScriptPath $ScriptPath

        Write-Log -LogName $LogName -Message "[Status]Step8:Succeeded" -ScriptPath $ScriptPath -NoTimeStamp

        Write-Output "Step8:Succeeded"

    }

    Catch {

        $Err = $_.Exception.Message

        Write-Log -LogName $LogName -Message "Starting the VM after conversion has been failed with the error: $Err" -ScriptPath $ScriptPath

        Write-Log -LogName $LogName -Message "[Status]Step8:Failed" -ScriptPath $ScriptPath -NoTimeStamp

        Throw "Starting the VM after conversion has been failed with the error: $Err"
        
    }
}
