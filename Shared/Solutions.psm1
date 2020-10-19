$Solutions = (
    [pscustomobject]@{
        Name = "Backend"
        IdentifyURL = ("https://someComp.visualstudio.com/Common/_git/Backend", 
                "https://dev.azure.com/someComp/Common/_git/Backend")
        URL = "https://dev.azure.com/someComp/Common/_git/Backend"
        Project = "proj"
        Repo = "Backend"
        DevBranch = "Development"
        IntBranch = "Integration"
        TempBranchPreFix = "Merge"    
    },
	
    [pscustomobject]@{
        Name = "Fontend"
        IdentifyURL = ("https://someComp.visualstudio.com/Common/_git/Backend", 
                "https://dev.azure.com/someComp/Common/_git/Backend")
        URL = "https://dev.azure.com/someComp/Common/_git/Backend"
        Project = "proj"
        Repo = "Frontend"
        DevBranch = "Development"
        IntBranch = "Integration"
        TempBranchPreFix = "Merge"    
    }	
)

function GetSolution {
    param ($SolName)

    if ($SolName -eq $null) {
        return $Solutions
    } else {
        if ($SolName -eq "menu") {
            Import-Module "$PSScriptRoot\Menu.psm1"
            $SolName = Menu @($Solutions.Where( {$_.Name -gt "" } ).Name);
        }

        $Solution = $Solutions.Where( {$_.Name -eq $SolName } ) 
        if ($Solution.Count -eq 0) {
            Write-Error "No solution with name [$SolName]" -ErrorAction Stop
        }
        return $Solution
    }
}
