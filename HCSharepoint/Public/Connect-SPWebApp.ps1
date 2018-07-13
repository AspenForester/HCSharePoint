<#
.SYNOPSIS
    Establishes connection with the SharePoint WebApp
.DESCRIPTION
    Leverages Connect-PNPOnline to establish a connection with a Sharepoint WebApp prior to accessing any data
    from that webapp
.EXAMPLE
    Connect-SPWebApp -URL "https://site.domain.local/webapp" -UseCurrentCredentials

    Connects using WinAuth to the WebApp using the current credentials
.EXAMPLE
    Connect-SPWebApp -URL "https://site.domain.local/webapp" -credential domain\username

    Connects using WinAuth to the WebApp using the provided credentials
.EXAMPLE
    Connect-SPWebApp -URL "https://site.domain.local/webapp" -credential domain\username -UseADFS
    
    Connects using ADFS to the WebApp using the provided credentials
.INPUTS
    String - URL
    Credentials
.OUTPUTS
    SharePointPnP.PowerShell.Commands.Base.SPOnlineConnection
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
.ROLE
    The role this cmdlet belongs to
.FUNCTIONALITY
    Connect to SharePoint
#>
function Connect-SPWebApp
{
    [CmdletBinding(DefaultParameterSetName = "CurrentCredentials")]
    [Alias()]
    [OutputType([SharePointPnP.PowerShell.Commands.Base.SPOnlineConnection])]
    Param (
        # Param1 help description
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("URI")]
        [String]
        $URL,
        
        # Param2 help description
        [Parameter(Mandatory= $true,
            ParameterSetName = 'CurrentCredentials')]
        [switch]
        $UseCurrentCredentials,
        
        # Credential
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Credentials')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
        
        # Use ADFS authentication with the provided credentials
        [Parameter(ParameterSetName = 'Credentials')]
        [Switch]
        $UseADFS,

        # Ignore SSL Errors - Use with Caution!
        [Parameter(AttributeValues)]
        [Switch]
        $IgnoreSSLErrors
    )
    
    begin
    {
    }
    
    process
    {
        # Parameter Sets
        if ($pscmdlet.ParameterSetName = 'CurrentCredentials')
        {
            $ConnectParam = @{
                URL = $URL
                ReturnConnection = $true
                CurrentCredentials = $true
            }
        }
        else {
            $ConnectParam = @{
                URL = $URL
                ReturnConnection = $true
                Credentials = $Credential
            }
        }

        Connect-PnPOnline @ConnectParam -UseAdfs:$UseADFS -IgnoreSslErrors:$IgnoreSSLErrors
    }
    
    end
    {
    }
}