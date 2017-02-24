$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"



Describe "StartVMAndWait" {
    Function Get-VMData {}
    Function Write-Log {}
    Function Reboot-VM {}
    Function WaitForVMToComeUp {}
    Context "Starting the VM" {
        
        Mock Start-VM
        Mock Write-Log
        Mock Get-VMData {[psobject]@{"OSName" = "2008"}}
        Mock Reboot-VM
        
        It "Should run Start-VM once and Reboot-VM shouldn't run when VM is up within 3 minutes" {            
            Mock WaitForVMToComeUp {$true}
            $null = StartVMAndWait -VMToStart "test" -LogName "something" -ScriptPath "somepath"
            
            Assert-MockCalled Start-VM -Exactly 1 -Scope It
            Assert-MockCalled Reboot-VM -Exactly 0 -Scope It
        }
        It "Should throw error if VM is not online" {
            Mock WaitForVMToComeUp {$false}
            {StartVMAndWait -VMToStart "test" -LogName "something" -ScriptPath "somepath" }| should throw "VM is not up after 3 minutes. Pausing the script"

        }
        It "Should run Start-VM and Reboot-VM once when VM is not up within 3 minutes" {

            {StartVMAndWait -VMToStart "test" -LogName "something" -ScriptPath "somepath" }| should throw "VM is not up after 3 minutes. Pausing the script"
            Assert-MockCalled Start-VM -Exactly 1 -Scope It
            Assert-MockCalled Reboot-VM -Exactly 1 -Scope It
        }

    }

}
