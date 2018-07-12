<#
  .Synopsis
    Returns the items from the specified Sharepoint list.
  .DESCRIPTION
    This function returns the contents of a specified sharepoint list.  
    The list items are returned as a collection of a custom object type, HC.Sharepoint.List.<name of list>
  .EXAMPLE
    $mylist = Get-SPListItem -uri "https://my.sharepoint.local/mysite" -list "testlist"
    Returns all records in a list.
  .EXAMPLE
    $mylist = Get-SPListItem -uri "https://my.sharepoint.local/mysite" -list "testlist" -SizeLimit 27
    Returs the first 27 records as specified by the SizeLimit Parameter
  .EXAMPLE
    $mylist = Get-SPListItem -uri "https://my.sharepoint.local/mysite" -list "testlist" -SizeLimit 0
    Returns all records in a list.
  .EXAMPLE
    $Creds = Get-Credential mydomain\myuser
    $mylist = Get-SPListItem -uri "https://team.mydomain.local/mysite" -list "testlist" -Credential $creds
    Uses the provided credential to authenticate with the SharePoint server
  .PARAMETER uri
    URI of the the sharepoint site to access.  Example: https://my.sharepoint.local/mysite
  .PARAMETER listname
    Name of the sharepoint list to access. In the uri "https://my.sharepoint.local/mysite/lists/mylist", "mylist" is the name of the list.
  .PARAMETER SizeLimit
    The Number of records to return.  Default is "0" to return all records.
  .PARAMETER Credential
    Credential to authenticate to the SharePoint server.  
  .LINK
    http://msdn.microsoft.com/en-us/library/office/fp179912(v=office.15).aspx#BasicOps_SPListItemTasks
#>
function Get-SPListItem
{
    [CmdletBinding()]  
    Param
    (
        # URI of the Sharepoint Site
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]
        $uri,

        # Name of the list to access
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [string]
        $listname,

        #Number of items to return
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 2)]
        [int]
        $SizeLimit = 0,

        # Credentials
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Use ADFS Authentication
        [Switch]
        $UseADFS
    )

    Begin
    {
        # First we need to connect
        try 
        {
            # There's a chance I might have to deal with mulitple connections...
            # Ensure we are connected to the WebApp specified by $URI
            $Connection = Get-PnPConnection
            if ($Connection.url -ne $uri)
            {
                if ($PSBoundParameters['Credential'])
                {
                    $ConnectParam = @{
                        Credentials = $Credential
                    }
                }
                else {
                    $ConnectParam = @{
                        CurrentCredentials = $true
                    }
                }
                
                $Connection = Connect-PnPOnline -ReturnConnection -Url $uri -UseAdfs:$UseADFS -ErrorAction Stop
            }
        }
        catch 
        {
            # I might want to handle this differently in the future
            
            Throw $_
        }
    }
    Process
    {
        $Lists = Get-PnPList
        # Case Sensitive List Name
        $CSList = ($Lists | Where Title -like $listname).Title

        If ($CSList)
        {
            $Items = Get-PnPListItem -List $CSList
        
            # Convert the Fieldvalues Dictionary items into a PSCustomObject
            foreach ($Item in $Items) 
            { 
                $obj = [pscustomobject]([hashtable]$Item.FieldValues)
                $obj.psobject.TypeNames.Insert(0, "HC.Sharepoint.List.$listname")
                $obj
            }
        }
        else {
            Throw "Could not find list: $listname"
        }
    }
    End
    {
    }
}