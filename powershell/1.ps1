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

$SourceRepo = "JackTn/TestRepo-One"
$GH_TOKEN = ""
# $SourceBranch = "main" 

$TargetRepo = 'JackTn/TestRepo-Two'
$TargetBranch = "Sync-By-$($SourceRepo)-4" 
$SyncPath = "/specification/common-types/" 

$home_dir = $pwd
write-host $home_dir

function OriginRepoClone {
    # Set-PsDebug -Trace 1
    
    $SourceFolder = $SourceRepo -split "/" -join "-"

    if (-not (Test-Path $SourceFolder)) {
        New-Item -Path $SourceFolder -ItemType Directory -Force
        Set-Location $SourceFolder
        git init
        # git config --global init.defaultBranch main
        git remote add Source "https://$($GH_TOKEN)@github.com/$($SourceRepo).git"
    }
    else {
        Set-Location $SourceFolder
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

OriginRepoClone

function TargetRepoClone {
    $SourceFolder = $SourceRepo -split "/" -join "-"
    $TargetFolder = $TargetRepo -split "/" -join "-"
    $SourceSyncFilePath = "/specification/common-types/" 
    $TargetSyncFilePath = "/specification/common-types/" 
    git config --global init.defaultBranch "main"
    if (-not (Test-Path $TargetFolder)) {
        New-Item -Path $TargetFolder -ItemType Directory -Force
        Set-Location $TargetFolder
        git init
        git remote add Target "https://$($GH_TOKEN)@github.com/$($TargetRepo).git"
    }
    else {
        Set-Location $TargetFolder
    }

    $defaultBranch = (git remote show Target | Out-String) -replace "(?ms).*HEAD branch: (\w+).*", '$1'
    
    git fetch --all
    FailOnError "Failed to fetch DefaultBranch ${defaultBranch}."

    $isExistBranch = $(git branch --list --remotes "Target/$TargetBranch")
    if ($isExistBranch) {
        write-host "has branch vb1"
        git checkout -b $TargetBranch "Target/$TargetBranch"
        Write-Host "checking $TargetBranch from remote"
    }
    else {
        write-host "has no vb2"
        git checkout -b $TargetBranch "Target/$defaultBranch"
        Write-Host "checking new branch $TargetBranch from $defaultBranch"
    }

    if (git diff "Target/$defaultBranch") {
        write-host 123
        git -c user.name="azure-sdk" -c user.email="azuresdk@microsoft.com" merge --strategy-option=theirs "Target/$defaultBranch"
        FailOnError "Failed to merge for ${TargetRepo}:${TargetBranch}"
        git -c user.name="azure-sdk" -c user.email="azuresdk@microsoft.com" rebase --strategy-option=theirs "Target/$defaultBranch"
        FailOnError "Failed to rebase for ${TargetRepo}:${TargetBranch}"
    }

    git push --force Target "${TargetBranch}:refs/heads/${TargetBranch}"
    FailOnError "Failed to push to ${TargetRepo}:${TargetBranch}"
    
    $FromPath = Join-Path $home_dir "$SourceFolder" "$SourceSyncFilePath"
    $ToPath = Join-Path $home_dir "$TargetFolder" "$TargetSyncFilePath"
    write-host $FromPath
    write-host $ToPath
    # delete path files
    if (test-path $ToPath) {
        write-host 00000
        Remove-Item "$ToPath" -Force -Recurse
    }
    # copy path files from github
    Copy-Item -Path "$FromPath" -Destination "$ToPath" -Recurse -Force

    $untrackkedFiles = git ls-files -o 
    if ($untrackkedFiles) {
        write-host 11
        git add .
        git commit -m "add untracked files"
        git push --force Target $($TargetBranch)
        FailOnError "Failed to push to $($TargetRepo):$($TargetBranch)"
    }
    else {
        write-host 22
        $diffResult = git diff "refs/remotes/Target/$($defaultBranch)"
        if ($diffResult) {
            write-host 999992
            git add .
            git commit -m "sync files"
            git push --force Target $($TargetBranch)
            FailOnError "Failed to push to $($TargetRepo):$($TargetBranch)"
        }
        else {
            write-host 7777
        }
    }
    # write-host $diffResult


    Install-Module -Name PowerShellForGitHub
    # $TargetFolder = $TargetRepo -split "/" -join "-"
    # -Uri "https://github.com/$($TargetRepo)"`
    # -OwnerName "JackTn" `
    # -RepositoryName "TestRepo-Two" `
    $OwnerName = ($TargetRepo -split '/')[0] 
    $pullRequests = Get-GitHubPullRequest `
        -AccessToken $GH_TOKEN `
        -Uri "https://github.com/$($TargetRepo)" `
        -State Open `
        -Head "$($OwnerName):$($TargetBranch)" `
        -Base "main" 
    FailOnError "Get $($TargetRepo) pull request: $_"

    write-host $pullRequests
    write-host "llllllll"
    if ($pullRequests.Count -ne 0) { 
        write-host 9999
        write-host "pr already exists"
        echo "PR has been created at https://github.com/$($TargetRepo)/pull/$($pullRequests.number)"
    }
    else {
        write-host 6666
        write-host "pr not exists"
        
        # create pull request
        $newPullRequest = New-GitHubPullRequest `
            -AccessToken $GH_TOKEN `
            -Uri "https://github.com/$($TargetRepo)" `
            -Head "$($OwnerName):$($TargetBranch)" `
            -Base $($defaultBranch) `
            -Title "test title2" `
            -Body "test body2" `
            -MaintainerCanModify `

        FailOnError "create $($TargetBranch) pull request: $_"

        Write-Host $newPullRequest
        echo "PR has been created at https://github.com/$($TargetRepo)/pull/$($newPullRequest.number)"
    }

    Set-Location $home_dir
}

TargetRepoClone

function test {
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
}

function test1 {
    $pr111 = New-GitHubPullRequest `
        -AccessToken $GH_TOKEN `
        -Uri "https://github.com/JackTn/TestRepo-Two" `
        -Head "JackTn:JackTn-patch-3" `
        -Base "main" `
        -Title 'test title' `
        -Body "test body" `
        -MaintainerCanModify

    Write-Host $pr111
    write-host "https://github.com/JackTn/TestRepo-Two/pull/$($pr111.number)"
}
# test1
function test2 {
    Set-Location JackTn-TestRepo-Two
    $untracked = git status
    write-host $status
    if ($status) {
        write-host "not empty"
    }
    else {
        write-host "empty"
    }

    $untracked = git ls-files -o
    write-host $untracked
    if ($untracked) {
        write-host "not empty"
    }
    else {
        write-host "empty"
    }

    $diff = git diff
    write-host $diff
    if ($diff) {
        write-host "not empty"
    }
    else {
        write-host "empty"
    }

    Set-Location $home_dir
}
# test2
function test3 {
    Set-Location JackTn-TestRepo-Two
    
    $b = $(git branch --list --remotes "Target/JackTn-patc2h-2")
    if ($b) {
        write-host "has branch vb1"
    }
    else {
        write-host "no branch vb2"
    }
    Set-Location $home_dir
}
# test3