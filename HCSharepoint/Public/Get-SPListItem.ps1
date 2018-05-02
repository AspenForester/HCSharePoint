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
        $Credential = [System.Management.Automation.PSCredential]::Empty 
    )

    Begin
    {
    }
    Process
    {
        # Connect to the Sharepoint Server
        $ClientContext = New-Object -TypeName Microsoft.SharePoint.Client.ClientContext($uri)

       if ($PSBoundParameters['Credential'])
       {
           $ClientContext.Credentials = New-Object System.Net.NetworkCredential($Credential.Username, $Credential.password) 
       }

        # Get the List
        $List = $ClientContext.Web.Lists.GetByTitle($listname)
 
        If ($SizeLimit -ne 0)
        {
            Write-Verbose ('Only retrieving {0} records' -f $SizeLimit)
            $Query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery($SizeLimit)
        }
        else
        {
            Write-Verbose "Retrieving all records"
            $Query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()
        }
		
        $Items = $List.GetItems($Query)

        $ClientContext.Load($Items)

        # Error handling!
        Try
        {
            $ErrorActionPreference = "Stop"
            $ClientContext.ExecuteQuery()
        }
        Catch
        {
            Write-Error $_.Exception.Message
        }
        Finally
        {
            $ErrorActionPreference = "Continue"
        }

        foreach ($Item in $Items) 
        { 
            <#
            $obj = New-Object -TypeName psobject 
            # Convert the hash table / dictionary object to a custom object
            foreach ($i in $Item.FieldValues) 
            { 
                foreach ($key in $i.keys) 
                {
                    Add-Member -InputObject $obj -NotePropertyName $key -NotePropertyValue $i.Item($key)
                }
            }
            $obj.psobject.TypeNames.Insert(0, "HC.Sharepoint.List.$listname")
            #>
            $obj = [pscustomobject]([hashtable]$Item.FieldValues)
            $obj.psobject.TypeNames.Insert(0, "HC.Sharepoint.List.$listname")
            $obj
        }
    }
    End
    {
    }
}