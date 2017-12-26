function Get-HPSM9DeviceInformation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Uri,
    
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]
        $ConfigurationItem,
    
        [Parameter()]
        [System.Management.Automation.CredentialAttribute()]
        [pscredential]
        $Credential
    )
        
    begin {
    }
        
    process {
        try {
            $WebService = New-WebServiceProxy -uri $Uri -ErrorAction Stop
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $WebService.Credentials = [System.Net.NetworkCredential]::new($Credential.UserName, $Credential.Password)
            }
            else {
                $WebService.UseDefaultCredentials = $true
            }
            $NameSpace = $WebService.GetType().NameSpace
            $DeviceKeysType = New-Object ($NameSpace + ".DeviceKeysType")
            $DeviceInstanceType = New-Object ($NameSpace + ".DeviceInstanceType")
            $DeviceModelType = New-Object ($NameSpace + ".DeviceModelType")
            $DeviceModelType.instance = $DeviceInstanceType
            $DeviceModelType.keys = $DeviceKeysType

            $CIs = New-Object ($NameSpace + ".StringType")
            foreach ($CI in $ConfigurationItem) {
                $CIs.Value = $CI
                $DeviceInstanceType.ConfigurationItem = $CIs
                $RetrieveDeviceRequest = New-Object ($namespace + ".RetrieveDeviceRequest")
                $RetrieveDeviceRequest.model = $DeviceModelType

                $Result = $WebService.RetrieveDevice($RetrieveDeviceRequest)
                if ($Result.status -eq "SUCCESS") {
                    [pscustomobject]@{
                        ConfigurationItem = $Result.model.instance.recordid
                        AssignmentGroup   = $Result.model.instance.AssignmentGroup.value 
                        Environment       = $Result.model.instance.Environment.Value
                        Location          = $Result.model.instance.Location.Value
                    }
                }
                else {
                    $Message = "{0} with the message {1} for {2}" -f ($Result.Status, $Result.message , $CI)
                    Write-Warning -Message $Message
                }
                $WebService.Dispose()
            }
        }
        catch {
            $_.Exception.ErrorRecord 
        }
    }
        
    end {
    }
}