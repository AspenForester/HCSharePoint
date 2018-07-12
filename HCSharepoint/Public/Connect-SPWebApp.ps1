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
                else
                {
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