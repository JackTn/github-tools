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
Function FailOnError([string]$ErrorMessage, $CleanUpScripts = 0) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "#`#vso[task.logissue type=error]$ErrorMessage"
        if ($CleanUpScripts -ne 0) { Invoke-Command $CleanUpScripts }
        exit 1
    }
}

Function Checkout-Branch($branch, $from) {
    $b = $(git branch --list $branch)
    if ($b) {
        git checkout $branch | Out-Null
    }
    else {
        git checkout -b $branch $from | Out-Null
    }
}

$SourceRepo = "JackTn/TestRepo-One"
$GH_TOKEN = ""
# $SourceBranch = "main" 

$TargetRepo = 'JackTn/TestRepo-Two'
$TargetBranch = "Sync-By-$($SourceRepo)" 
$SyncPath = "/specification/common-types/" 

$home_dir = $pwd
write-host $home_dir

function OriginRepoClone {
    # Set-PsDebug -Trace 1
    
    $FilePath = $SourceRepo -split "/" -join "-"

    if (-not (Test-Path $FilePath)) {
        New-Item -Path $FilePath -ItemType Directory -Force
        Set-Location $FilePath
        git init
        git remote add Source "https://$($GH_TOKEN)@github.com/$($SourceRepo).git"
    }
    else {
        Set-Location $FilePath
    }

    # Check the default branch
    if (!$SourceBranch) {
        $defaultBranch = (git remote show Source | Out-String) -replace "(?ms).*HEAD branch: (\w+).*", '$1'
        # $defaultBranch = git symbolic-ref --short HEAD
        Write-Host "No source branch. Fetch default branch $defaultBranch."
        $SourceBranch = $defaultBranch
    }

    git fetch --no-tags Source $SourceBranch
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "#`#vso[task.logissue type=error]Failed to fetch ${SourceRepo}:${SourceBranch}"
        exit 1
    }
    
    # git checkout -B source_branch "refs/remotes/Source/${SourceBranch}"
    
    # Set-PsDebug -Off
    Set-Location $home_dir
}

# OriginRepoClone


function TargetRepoClone {
    $FilePath = $TargetRepo -split "/" -join "-"

    if (-not (Test-Path $FilePath)) {
        New-Item -Path $FilePath -ItemType Directory -Force
        Set-Location $FilePath
        git init
        git remote add Target "https://$($GH_TOKEN)@github.com/$($TargetRepo).git"
    }
    else {
        Set-Location $FilePath
    }

    $defaultBranch = (git remote show Target | Out-String) -replace "(?ms).*HEAD branch: (\w+).*", '$1'
    
    git fetch --no-tags Target $defaultBranch
    FailOnError "Failed to fetch DefaultBranch ${defaultBranch}."

    $b = $(git branch --list --remotes "Target/$TargetBranch")
    if ($b) {
        $checkoutFrom = "Target/$TargetBranch"
    }
    else {
        $checkoutFrom = "Target/$($defaultBranch)"
    }

    Checkout-Branch $TargetBranch $checkoutFrom
    Write-Host "checking $TargetBranch from $defaultBranch"

    git -c user.name="azure-sdk" -c user.email="azuresdk@microsoft.com" merge --strategy-option=theirs $defaultBranch
    FailOnError "Failed to merge for ${TargetRepo}:${TargetBranch}"
    git -c user.name="azure-sdk" -c user.email="azuresdk@microsoft.com" rebase --strategy-option=theirs $defaultBranch
    FailOnError "Failed to rebase for ${TargetRepo}:${TargetBranch}"

    git push --force Target "target_branch:refs/heads/${TargetBranch}"
    FailOnError "Failed to push to ${TargetRepo}:${TargetBranch}"

    
    # copy path files from github
    Copy-Item "$($ADO_file_path)/$SyncPath" "$($ADO_file_path)/$SyncPath" -Recurse -Force

    Set-Location $home_dir
}

# TargetRepoClone

# copy path files from github
$apath = Join-Path $home_dir "JackTn-TestRepo-One" "arm-compute"
$bpath = Join-Path $home_dir "JackTn-TestRepo-Two" "asd" "cccv"
Copy-Item -Path $apath -Destination $bpath -Recurse -Force