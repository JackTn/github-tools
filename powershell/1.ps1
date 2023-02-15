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
    
    $SourceFilePath = $SourceRepo -split "/" -join "-"

    if (-not (Test-Path $SourceFilePath)) {
        New-Item -Path $SourceFilePath -ItemType Directory -Force
        Set-Location $SourceFilePath
        git init
        # git config --global init.defaultBranch main
        git remote add Source "https://$($GH_TOKEN)@github.com/$($SourceRepo).git"
    }
    else {
        Set-Location $SourceFilePath
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
    
    git checkout -B source_branch "refs/remotes/Source/${SourceBranch}"
    
    # Set-PsDebug -Off
    Set-Location $home_dir
}

# OriginRepoClone


function TargetRepoClone {
    $SourceFilePath = $SourceRepo -split "/" -join "-"
    $TargetFilePath = $TargetRepo -split "/" -join "-"
    $SourceSyncPath = "/specification/common-types/" 
    $TargetSyncPath = "/specification/common-types/" 

    if (-not (Test-Path $TargetFilePath)) {
        New-Item -Path $TargetFilePath -ItemType Directory -Force
        Set-Location $TargetFilePath
        git init
        git remote add Target "https://$($GH_TOKEN)@github.com/$($TargetRepo).git"
    }
    else {
        Set-Location $TargetFilePath
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

    if (git diff "Target/$defaultBranch") {
        write-host 123
        git -c user.name="azure-sdk" -c user.email="azuresdk@microsoft.com" merge --strategy-option=theirs "Target/$defaultBranch"
        FailOnError "Failed to merge for ${TargetRepo}:${TargetBranch}"
        git -c user.name="azure-sdk" -c user.email="azuresdk@microsoft.com" rebase --strategy-option=theirs "Target/$defaultBranch"
        FailOnError "Failed to rebase for ${TargetRepo}:${TargetBranch}"
    }

    git push --force Target ${TargetBranch}
    FailOnError "Failed to push to ${TargetRepo}:${TargetBranch}"

    
    $apath = Join-Path $home_dir "$SourceFilePath" "$SourceSyncPath"
    $bpath = Join-Path $home_dir "$TargetFilePath" "$TargetSyncPath"
    write-host $apath
    write-host $bpath
    # delete path files
    if (test-path $bpath) {
        write-host 00000
        Remove-Item "$bpath" -Force -Recurse
    }
    # copy path files from github
    Copy-Item -Path "$apath" -Destination "$bpath" -Recurse -Force

    git add .
    git commit -m "sync"
    git push --force Target ${TargetBranch}
    FailOnError "Failed to push to ${TargetRepo}:${TargetBranch}"

    Set-Location $home_dir
}

# TargetRepoClone


Set-Location JackTn-TestRepo-Two
Install-Module -Name PowerShellForGitHub
$url = "https://api.github.com/repos/$($TargetRepo)/pulls"
write-host $url
function Get-Headers ($token) {
    $headers = @{ Authorization = "bearer $token" }
    return $headers
}
# $resp = Invoke-RestMethod -Uri $url -Method Get -ContentType "application/json" -Headers (Get-Headers -token $GH_TOKEN) | ConvertFrom-Json

# $resp = Invoke-WebRequest `
#     -Method GET `
#     -Headers (Get-Headers -token $GH_TOKEN) `
#     -Uri $url `
# | ConvertFrom-Json

# $secureString = ("$GH_TOKEN" | ConvertTo-SecureString -AsPlainText -Force)
# $cred = New-Object System.Management.Automation.PSCredential "username is ignored", $secureString
# Set-GitHubAuthentication -Credential $cred
# # $secureString = $null # clear this out now that it's no longer needed
# # $cred = $null # clear this out now that it's no longer needed

# -Uri "https://github.com/$($TargetRepo)"`
    # -State Open `
    # -Base "main" ` 
    #user:ref-name
    # -Head "user:Jmain" `

$pullRequests = Get-GitHubPullRequest `
    -OwnerName "JackTn" `
    -RepositoryName "TestRepo-Two" `
    -AccessToken $GH_TOKEN `
    -State Open `
    -Head "Jacktn:JackTn-patch-2" `
    -Base "main" 

FailOnError "Faileded $_"
# write-host $resp
write-host $pullRequests
Set-Location $home_dir