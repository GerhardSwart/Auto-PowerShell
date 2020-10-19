function EncodeToken {
    param ($PersonalAzureDevopsToken)

    $token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PersonalAzureDevopsToken)"))
    return @{authorization = "Basic $token"}
}

function UpdatePullrequest {
   param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][string]$organization,
        [Parameter(mandatory=$true)][string]$project,
        [Parameter(mandatory=$true)][string]$repository,
        [Parameter(mandatory=$true)][string]$pullRequestId,
        [Parameter(mandatory=$true)][string]$autoCompleteUser,
        [Parameter(mandatory=$true)][string]$mergeMessage,
        [Boolean]$isDraft,
        [string]$status
    )

    $header = EncodeToken($token);
    
    if($isDraft -ne $null) {
        $jDraft = ", ""isDraft"" : "
        if($isDraft -eq $true) { 
            $jDraft += "true" 
        } else { 
            $jDraft +="false" 
        }
    }

    if($status -ne "") {
        $jStatus = ", ""status"" : $Status"
    }

    $url = "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/pullrequests/$($pullRequestId)?api-version=5.1"
    $body = @"
            {
                "autoCompleteSetBy": $autoCompleteUser,
                "completionOptions": { 
                    "deleteSourceBranch": "true",
                    "mergeCommitMessage": "$mergeMessage", 
                    "squashMerge": "false" 
                }
                $jDraft
                $jStatus
            }
"@

    try {
        $requestResult = Invoke-WebRequest -Uri $url -Method Patch -ContentType "application/json" -Headers $header -Body $body
    } catch {
         return "[{ ""error"" : ""UpdatePullrequest - $(($_.ErrorDetails | ConvertFrom-Json).message)"" }]" | ConvertFrom-Json
    }

    if ($requestResult.StatusCode -eq 200) {
        $pr = $requestResult.Content | ConvertFrom-Json
        return $pr
    } else {
        return "[{ ""error"" : ""UpdatePullrequest - $($requestResult.StatusDescription)"" }]" | ConvertFrom-Json
    }

}

function CreatePullrequest {
    param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][string]$organization,
        [Parameter(mandatory=$true)][string]$project,
        [Parameter(mandatory=$true)][string]$repository,
        [Parameter(mandatory=$true)][string]$sourceBranch,
        [Parameter(mandatory=$true)][string]$targetBranch,
        [Parameter(mandatory=$true)][string]$title,
        [Boolean]$autoComplete
    )

    $header = EncodeToken($token);

    $url = "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/pullrequests?api-version=5.0"  
    $body = @"
            {
                "sourceRefName": "refs/heads/$sourceBranch",
                "targetRefName": "refs/heads/$targetBranch",
                "title": "$title",
                "isDraft": true
            }
"@ 
    try {
        $requestResult = Invoke-WebRequest -Uri $url -Method Post -ContentType "application/json" -Headers $header -Body $body
    } catch {
         return "[{ ""error"" : ""$(($_.ErrorDetails | ConvertFrom-Json).message)"" }]" | ConvertFrom-Json
    }

    if ($requestResult.StatusCode -eq 201) {
        #on sucess Auto Complete PR
        $pr = $requestResult.Content | ConvertFrom-Json
        $createdBy = $pr.createdBy | ConvertTo-Json
        if ($autoComplete) {       
            $pr = UpdatePullrequest `
                -token $token `
                -organization "someComp" `
                -project $($project) `
                -repository $($repository) `
                -pullRequestId $($pr.pullRequestId) `
                -autoCompleteUser $createdBy `
                -mergeMessage "Merge $title" `
                -isDraft $false
        }
        return $pr
    } else {
        return "[{ ""error"" : ""CreatePullrequest - $($requestResult.StatusDescription)"" }]" | ConvertFrom-Json
    }
}

function ValidateToken {
    param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][string]$organization
    )

    $header = EncodeToken($token);

    $url = "https://dev.azure.com/$organization/_apis/projects?api-version=5.1"  
    
    try {
        $result = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -Headers $header
    } catch {
       Write-Host $result.StatusDescription
    }

    if ($result.StatusCode -eq 200) {
        return $true
    } else {
        Write-Host "$($result.StatusCode) - $($result.StatusDescription)" -ForegroundColor Red
        return $false
    }
}


function GetPullRequestByID {
    param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][string]$organization,
        [Parameter(mandatory=$true)][string]$project,
        [Parameter(mandatory=$true)][string]$pullRequestId
    )

    $header = EncodeToken($token);
    $url =  "https://dev.azure.com/$organization/$project/_apis/git/pullrequests/$($pullRequestId)?api-version=5.1"

    try {
        $requestResult = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -Headers $header
    } catch {
         return "[{ ""error"" : ""GetPullRequestByID - $($_.ErrorDetails.message)"" }]" | ConvertFrom-Json
    }

    if ($requestResult.StatusCode -eq 200) {
        $pr = $requestResult.Content | ConvertFrom-Json
        return $pr
    } else {
        return "[{ ""error"" : ""GetPullRequestByID - $($requestResult.StatusDescription)"" }]" | ConvertFrom-Json
    }
}


function GetPullRequestByBranchs {
    param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][string]$organization,
        [Parameter(mandatory=$true)][string]$project,
        [Parameter(mandatory=$true)][string]$repository,
        [Parameter(mandatory=$true)][string]$sourceBranch,
        [Parameter(mandatory=$true)][string]$targetBranch
    )

    $header = EncodeToken($token);

    $sourceBranch = "refs/heads/$sourceBranch"
    $targetBranch = "refs/heads/$targetBranch"
    $url = "https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/pullrequests?searchCriteria.sourceRefName=$sourceBranch&searchCriteria.targetRefName=$targetBranch&api-version=5.1"

    try {
        $requestResult = Invoke-WebRequest -Uri $url -Method Get -ContentType "application/json" -Headers $header
    } catch {
         return "[{ ""error"" : ""GetPullRequestByBranchs - $($_.ErrorDetails.message)"" }]" | ConvertFrom-Json
    }

    if ($requestResult.StatusCode -eq 200) {
        $prs = $requestResult.Content | ConvertFrom-Json
        return $prs
    } else {
        return "[{ ""error"" : ""GetPullRequestByBranchs - $($requestResult.StatusDescription)"" }]" | ConvertFrom-Json
    }

}