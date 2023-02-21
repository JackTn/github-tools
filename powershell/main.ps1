Function FailOnError([string]$ErrorMessage, $CleanUpScripts = 0) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "#`#vso[task.logissue type=error]$ErrorMessage"
        if ($CleanUpScripts -ne 0) { Invoke-Command $CleanUpScripts }
        exit 1
    }
}

$SourceRepo = "JackTn/TestRepo-One"
$SourceFolder = $SourceRepo -split "/" -join "-"
$SourceBranch = 'main'

$TargetRepo = "JackTn/TestRepo-Three"
$TargetFolder = $TargetRepo -split "/" -join "-"
$TargetBranch = "main"

# $UserName = "azure-sdk"
# $UserEmail = "azuresdk@microsoft.com"
$UserName = "JackTn"
$UserEmail = "347142915@qq.com"
$home_dir = $pwd
$GH_TOKEN = ""
$pullRequestBranch = "Sync-from-$SourceFolder"

function OriginRepoClone {
    # Set-PsDebug -Trace 1
    git config init.defaultBranch "main"

    if (-not (Test-Path $SourceFolder)) {
        New-Item -Path $SourceFolder -ItemType Directory -Force
        Set-Location $SourceFolder
        git init
        # git config init.defaultBranch main
        git remote add Source "https://$($GH_TOKEN)@github.com/$($SourceRepo).git"
    }
    else {
        Set-Location $SourceFolder
    }

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

Install-Module -Name PowerShellForGitHub

function TargetRepoClone {
    git config init.defaultBranch "main"

    if (-not (Test-Path $TargetFolder)) {
        New-Item -Path $TargetFolder -ItemType Directory -Force
        Set-Location $TargetFolder
        git init
        git remote add Target "https://$($GH_TOKEN)@github.com/$($TargetRepo).git"
    }
    else {
        Set-Location $TargetFolder
    }

    git config user.email "$UserEmail"
    git config user.name "$UserName"

    if (!$TargetBranch) {
        $defaultBranch = (git remote show Target | Out-String) -replace "(?ms).*HEAD branch: (\w+).*", '$1'
        Write-Host "No target branch. Fetch default branch $defaultBranch."
        $TargetBranch = $defaultBranch
    }

    git fetch --all
    FailOnError "Failed to fetch DefaultBranch ${defaultBranch}."

    $isExistBranch = $(git branch --list --remotes "Target/$pullRequestBranch")
    if ($isExistBranch) {
        git checkout -b $pullRequestBranch "Target/$pullRequestBranch"
        Write-Host "checking $pullRequestBranch from remote"
    }
    else {
        git checkout -b $pullRequestBranch "Target/$TargetBranch"
        Write-Host "checking new branch $pullRequestBranch from $TargetBranch"
    }

    if (git diff "refs/remotes/Target/$($TargetBranch)") {
        Write-Host "The ${$pullRequestBranch} in ${$TargetRepo} has diff by ${$TargetBranch} branch"
        git -c user.name=$UserName -c user.email=$UserEmail merge --strategy-option theirs "Target/$TargetBranch"
        FailOnError "Failed to merge for ${TargetRepo}:${TargetBranch}"
    }

    git push Target "${pullRequestBranch}:refs/heads/${pullRequestBranch}"
    FailOnError "Failed to push to ${pullRequestBranch}:${pullRequestBranch}"
    
    $TargetSyncFilePath = "/cSpell.json", "/custom-words.txt", "/specification/common-types/resource-management"
    $SourceSyncFilePath = "/cSpell.json", "/custom-words.txt"
    # Sync Files
    foreach ($item in $SourceSyncFilePath) {
        $index = $SourceSyncFilePath.IndexOf($item)

        if ($null -eq $TargetSyncFilePath[$index]) {
            continue
        }

        $SourcePathItem = $SourceSyncFilePath[$index]
        $TargetPathItem = $TargetSyncFilePath[$index]
        $FromPath = Join-Path $home_dir "$SourceFolder" "$SourcePathItem"
        $ToPath = Join-Path $home_dir "$TargetFolder" "$TargetPathItem"
        
        Write-Host "It will sync files from ${$SourceRepo}:${$SourcePathItem} to ${$TargetRepo}:${$ToPath}"

        if (test-path $ToPath) {
            Remove-Item "$ToPath" -Force -Recurse
        }
        Copy-Item -Path "$FromPath" -Destination "$ToPath" -Recurse -Force

        $untrackkedFiles = git ls-files -o 
        if ($untrackkedFiles) {
            Write-Host "The $TargetRepo in $pullRequestBranch has untracked files should commit first"
            git add .
            git commit -m "Sync files from ${$SourceRepo}:${$SourceBranch}"
            git push Target $($pullRequestBranch)
            FailOnError "Failed to push to $($TargetRepo):$($pullRequestBranch)"
        }else {
            $diffResult = git diff "refs/remotes/Target/$TargetBranch"
            if ($diffResult) {
                Write-Host "The $TargetRepo in $pullRequestBranch has diff files should commit first"
                git add .
                git commit -m "Sync files from ${$SourceRepo}:${$SourceBranch}"
                git push Target $($pullRequestBranch)
                FailOnError "Failed to push to ${$TargetRepo}:${$TargetBranch}"
            }
        }
        $OwnerName = ($TargetRepo -split '/')[0] 
        $pullRequests = Get-GitHubPullRequest `
            -AccessToken $GH_TOKEN `
            -Uri "https://github.com/$($TargetRepo)" `
            -State Open `
            -Head "$($OwnerName):$($pullRequestBranch)" `
            -Base $($TargetBranch)
        FailOnError "Get $($TargetRepo) pull request: $_"

        if ($pullRequests.Count -ne 0) { 
            echo "PR has been created at https://github.com/$($TargetRepo)/pull/$($pullRequests.number)"
        }
        else {
            $pullRequestTitle = "[AutoSync] Sync $TargetPathItem folder from $SourceRepo repo"
            $pullRequestBody = "Sync $TargetPathItem folder from [$SourceRepo](https://github.com/$SourceRepo/tree/$SourceBranch$SourcePathItem)"
            $newPullRequest = New-GitHubPullRequest `
                -AccessToken $GH_TOKEN `
                -Uri "https://github.com/$($TargetRepo)" `
                -Head "$($OwnerName):$($pullRequestBranch)" `
                -Base $($TargetBranch) `
                -Title $($pullRequestTitle) `
                -Body $($pullRequestBody) `
                -MaintainerCanModify
            FailOnError "create $($TargetBranch) pull request: $_"
            echo "PR has been created at https://github.com/$($TargetRepo)/pull/$($newPullRequest.number)"
        }
    }
    Set-Location $home_dir
}

TargetRepoClone
