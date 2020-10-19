Remove-Variable * -ErrorAction SilentlyContinue; Remove-Module *; $error.Clear();
Clear-Host;

Import-Module "$PSScriptRoot\..\Shared\Solutions.psm1" -Force
Import-Module "$PSScriptRoot\..\Shared\SettingManager.psm1" -Force
Import-Module "$PSScriptRoot\AzureDevops.psm1" -Force

#helper function
function GetValidToken { 
    $UserPAT = GetUserSetting("AzureDevopsPersonalAccessToken")
    if  ($UserPAT -ne $null) {
        $token = decodeString(GetUserSetting("AzureDevopsPersonalAccessToken"))
    }

    if ($token -ne $null -and $token -ne "") {
        $tokenValid = ValidateToken -token $token -organization "someComp"
    }

    if ($tokenValid -ne $true) {
        while ($tokenValid -ne $true) {        
            #Clear-Host
            if ($token -eq $null -and $token -eq "") {
                Write-host "Personal Access Token is required!" -ForegroundColor Red
            } else {
                Write-Host "Personal Access Token is not valid!" -ForegroundColor Red             
            }        

            Write-host
            Write-Host "How to get the Personal Access Token for AzureDevops/VSTS :" -ForegroundColor Green
            Write-host "https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page#create-personal-access-tokens-to-authenticate-access" -ForegroundColor Green
            Write-host
            Write-Host "Please enter Personal Access Token:"
            $token = Read-Host
            $tokenValid = ValidateToken -token $token -organization "someComp"
        }

        $temp = SetUserSetting "AzureDevopsPersonalAccessToken" $(encodeString($token))
        Write-Host "Personal Access Token saved to $(SettingsFilePath)" -ForegroundColor Green
    } else {
        Write-Host "Valid Personal Access Token" -ForegroundColor Green                
    }

    return $token
}


function HandelPRStatus {
    param(
        [Parameter(mandatory=$true)][string]$token,
        [Parameter(mandatory=$true)][psobject]$pullrequest
    )
    $minLoop = 0

    do {     
        Start-Sleep -Seconds 3
        $pr = GetPullRequestByID `
            -token $token `
            -organization "someComp" `
            -project $($pullrequest.repository.project.name) `
            -pullRequestId $($pullrequest.pullRequestId)

        $status = $pr.mergeStatus

        switch ($status)
        {
            "queued" {Write-Host "Pullrequest Status - $status" -ForegroundColor Gray}
            "conflicts" { Write-Host "Pullrequest Status - $status" -ForegroundColor Red }
            "failure" { Write-Host "Pullrequest Status - $status" -ForegroundColor Red }
            "notSet" { Write-Host "Pullrequest Status - $status" -ForegroundColor Red }
            "rejectedByPolicy" { Write-Host "Pullrequest Status - $status" -ForegroundColor Red }
            "succeeded" { Write-Host "Pullrequest Status - $status" -ForegroundColor Green }
            deafult {Write-Host "Pullrequest Status - $status" -ForegroundColor Yellow}
        }
        $minLoop = $minLoop + 1
    } while ($status -eq "queued" -and $minLoop -ge 6)

    return $status
}


Write-Host $token
$token = GetValidToken

$DailyMergeName = "DailyMerge-" + (Get-Date -UFormat "%Y%m%d")
Write-Host 
Write-Host "$DailyMergeName"
Write-Host


$SolutionParam = $args[0]
if ($host.name -match 'ISE') {
    Write-Host 'Running in Powershell ISE' -ForegroundColor Yellow
    $SolutionParam = "test"
    Write-Host "Defaulted to : $($SolutionParam)" -ForegroundColor Yellow
}

if ($SolutionParam -eq $null) {
    $SolutionVar = GetSolution("menu")
    Clear-Host
} else {
    $SolutionVar = GetSolution($SolutionParam)
}

Write-Host "Creating DailyMerge for :"
$SolutionVar | Format-List | Out-String | Write-Host

$pr = CreatePullrequest `
        -token $token `
        -organization "someComp" `
        -project $($SolutionVar.Project) `
        -repository $($SolutionVar.Repo) `
        -sourceBranch $($SolutionVar.IntBranch) `
        -targetBranch $($SolutionVar.DevBranch) `
        -title $DailyMergeName `
        -autoComplete $true

if ($pr.error -ne $null) {
    write-host "Error Creating Pullrequest : " -ForegroundColor Red
    write-host $pr.error -ForegroundColor Red

    $prs = GetPullRequestByBranchs `
        -token $token `
        -organization "someComp" `
        -project $($SolutionVar.Project) `
        -repository $($SolutionVar.Repo) `
        -sourceBranch $($SolutionVar.IntBranch) `
        -targetBranch $($SolutionVar.DevBranch) `

    $pr = $prs.value[0]
    $prUrl = "https://dev.azure.com/someComp/$($SolutionVar.Project)/_git/$($SolutionVar.Repo)/pullrequest/$($pr.pullRequestId)"
    Write-Host
    Write-Host "Opening Pullrequest $($pr.pullRequestId)" -ForegroundColor Magenta
    start $prUrl

} else {
    #PR created, now handel the mreging
    $status =HandelPRStatus `
                -token $token `
                -pullrequest $pr

    $prUrl = "https://dev.azure.com/someComp/$($SolutionVar.Project)/_git/$($SolutionVar.Repo)/pullrequest/$($pr.pullRequestId)"
    if ($status -eq "succeeded") {
        start $prUrl
    } else {
        if ($status -eq "conflicts") {
            start $prUrl
            #Adondon Pullrequest


            #create local pullrequest
            Import-Module "$PSScriptRoot\..\DailyMerge\DailyMergeLocal.psm1" -Force
            DailyMergeLocal($SolutionVar.Name)

        } else {
            Write-Host "Issues with Pullrequest" -ForegroundColor Red
            Write-Host
            Write-Host "Opening Pullrequest"
            start $prUrl
        }
    }
}



