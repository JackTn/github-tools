# Azure/azure-sdk-for-python:
# Branch: release/v3
# FilePath: 123123132
# TargetRepos:
#   Azure/azure-sdk-for-python-pr:
#   azure-sdk/azure-sdk-for-python:
#   azure-sdk/azure-sdk-for-python-pr:

# sourceRepo:
#     -branch:
#     -path:
# targetRepos:
#     -targetRepo:
#         -branch:
#         -path:
#     -targetRepo:
#         -branch:
#         -path:

function main {

    Set-PsDebug -Trace 1
    $GH_TOKEN = ""
    $home_dir = $pwd
    write-host $home_dir
    
    $SourceRepo = "JackTn/github-tools"
    $SourceBranch = "main" 
    
    $path = "gitRepoFolder"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force
        Set-Location $path
        git init
        git remote add Source "https://$($GH_TOKEN)@github.com/$($SourceRepo).git"
    }
    else {
        Set-Location $SourceRepo
    }
    
    # Check the default branch
    if (!$SourceBranch) {
        $defaultBranch = (git remote show Source | Out-String) -replace "(?ms).*HEAD branch: (\w+).*", '$1'
        Write-Host "No source branch. Fetch default branch $defaultBranch."
        $SourceBranch = $defaultBranch
    }
    git fetch --no-tags Source $SourceBranch
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "#`#vso[task.logissue type=error]Failed to fetch ${SourceRepo}:${SourceBranch}"
        exit 1
    }
    
    git checkout -B source_branch "refs/remotes/Source/${SourceBranch}"
    
    Set-PsDebug -Off
}

# main

write-host ${coalesce('asdasd', 'dfdfgdfg')}