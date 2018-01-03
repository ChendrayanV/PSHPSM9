function Get-HPSM9ProblemRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Uri,

        [Parameter(Mandatory)]
        $Id,

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
            $ProblemKeysType = New-Object ($NameSpace + ".ProblemKeysType")
            $ProblemInstanceType = New-Object ($NameSpace + ".ProblemInstanceType")
            $ProblemModelType = New-Object ($NameSpace + ".ProblemModelType")
            $ProblemModelType.instance = $ProblemInstanceType
            $ProblemModelType.keys = $ProblemKeysType
            $Problem = New-Object ($NameSpace + ".StringType")
            foreach ($Problems in $ProblemId) {
                $Problem.Value = $Problems
                $ProblemKeysType.ProblemID = $Problem
                $RetrieveProblemRequest = New-Object ($NameSpace + ".RetrieveProblemRequest")
                $RetrieveProblemRequest.model = $ProblemModelType
                $Result = $WebService.RetrieveProblem($RetrieveProblemRequest)
                if ($Result.Status -eq "Success") {
                    [pscustomobject]@{
                        Impact            = $Result.model.instance.Impact.Value
                        ResordId          = $Result.model.instance.recordid
                        Service           = $Result.model.instance.Service.Value
                        Category          = $Result.model.instance.header.Category.Value
                        AssignmentGroup   = $Result.model.instance.header.AssignmentGroup.Value
                        ConfigurationItem = $Result.model.instance.middle.ConfigurationItem.Value
                        Status            = $Result.model.instance.header.Status.Value
                        InitiatedBy       = $Result.model.instance.header.InitiatedBy.Value
                    }
                }
                else {
                    $Message = "{0} with the message {1}" -f ($Result.Status, $Result.message)
                    Write-Warning -Message $Message
                }
                $WebService.Dispose()
        }
        catch {
            $_.Exception.ErrorRecord
        }
    }
    
    end {
    }
}