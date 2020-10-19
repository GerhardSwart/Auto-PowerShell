class ApiTester {
    [string] $apiURL
    [object] $authorization

    #constructor
    APITester([string] $apiURL, [string] $authorization) {
        $this.apiURL = $apiURL
        $this.authorization = $authorization
    }

    [PSCustomObject] HttpRequest ([string] $url, [string] $httpMethod, [object] $header, [string] $body) {    
        $requestResult = [PSCustomObject]
        try {
            $url = "$($this.apiURL)/$url"
            if ($header -ne '') {
                $requestResult = Invoke-WebRequest -Uri $url -Method $httpMethod -ContentType "application/json" -Headers $header -Body $body
            } else {
                $requestResult = Invoke-WebRequest -Uri $url -Method $httpMethod -ContentType "application/json" -Body $body
            }
        } catch {            
            return [PSCustomObject]@{
                    "Error" = $_.Exception
                    "Details" = $_.ErrorDetails
                    "URL" = $url
            }
        }

        return [PSCustomObject]@{
            Status = $requestResult.StatusCode
            Content = $requestResult.Content
        }
    }

	# TODO : just test staring is not good enoughe
    [PSCustomObject] CompareResults ([string] $expected, [string] $result) {
        if ($result -ne $expected) {
            reutn [PSCustomObject]@{
                result = $result
                expected = $expected
            }
        }

        return $null
    }

    TestEndpoint ([string] $endpointPath, [string] $httpMethod, [string] $paramters, [string] $expectedStatus, [string] $expectedResults) {
        #$header = @{ "Accept" = "application/json" };
        $header = ""
        if ($this.authorization -ne '') {
            $header.Add("Authorization" , $this.authorization)
        }
        $body = $paramters
        $result = $this.HttpRequest($endpointPath, $httpMethod, $header, $body)
        if ($result.error -ne $null) {
            write-host $($result.URL)
            write-host "Error $($result.error)" -ForegroundColor Red
            write-host "$($result.details)" -ForegroundColor Red
        } else {
            Write-Host CompareResults($expectedResults, $result.content)-ForegroundColor Yellow
        }
    }
}

function New-ApiTester([string] $apiURL, [string] $authorization) {
    return [ApiTester]::new($apiURL, $authorization)
}

Export-ModuleMember -Function New-ApiTester