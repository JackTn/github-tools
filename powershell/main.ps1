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
$SourceSyncFilePath = '/cSpell.json'

$TargetRepo = "JackTn/TestRepo-Three"
$TargetFolder = $TargetRepo -split "/" -join "-"
$TargetBranch = "main"
$TargetSyncFilePath = "/cSpell.json"

# $UserName = "azure-sdk"
# $UserEmail = "azuresdk@microsoft.com"
$UserName = "JackTn"
$UserEmail = "347142915@qq.com"
$home_dir = $pwd
$GH_TOKEN = ""


$pullRequestBranch = "Sync-from-$SourceFolder"
$pullRequestTitle = "[AutoSync] Sync $TargetSyncFilePath folder from $SourceRepo repo"
$pullRequestBody = "Sync $TargetSyncFilePath folder from [$SourceRepo](https://github.com/$SourceRepo/tree/$SourceBranch$SourceSyncFilePath)"

function OriginRepoClone {
    # Set-PsDebug -Trace 1
    $SourceFolder = $SourceRepo -split "/" -join "-"

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

Install-Module -Name PowerShellForGitHub

function TargetRepoClone {
    # $SourceFolder = $SourceRepo -split "/" -join "-"
    # $TargetFolder = $TargetRepo -split "/" -join "-"
    # $SourceSyncFilePath = "/specification/common-types/" 
    # $TargetSyncFilePath = "/specification/common-types/" 

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
        write-host "remote has branch"
        git checkout -b $pullRequestBranch "Target/$pullRequestBranch"
        Write-Host "checking $pullRequestBranch from remote"
    }
    else {
        write-host "remote has no branch"
        git checkout -b $pullRequestBranch "Target/$TargetBranch"
        Write-Host "checking new branch $pullRequestBranch from $TargetBranch"
    }

    if (git diff "refs/remotes/Target/$($TargetBranch)") {
        write-host 114
        # Fetch the newest code
        # https://blog.csdn.net/kalman2019/article/details/128214835?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-128214835-blog-127226731.pc_relevant_recovery_v2&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-128214835-blog-127226731.pc_relevant_recovery_v2&utm_relevant_index=1
# git fetch

# # Delete all files which are being added, so there
# # are no conflicts with untracked files
# for file in `git diff HEAD..origin/master --name-status | awk '/^A/ {print $2}'`
# do
#     rm -f -- "$file"
# done

# # Checkout all files which were locally modified
# for file in `git diff --name-status | awk '/^[CDMRTUX]/ {print $2}'`
# do
#     git checkout -- "$file"
# done

# # Finally pull all the changes
# # (you could merge as well e.g. 'merge origin/master')
# git pull


        # try {
        #     git -c user.name=$UserName -c user.email=$UserEmail merge --strategy-option theirs "Target/$TargetBranch"
        #     # FailOnError "Failed to merge for ${TargetRepo}:${TargetBranch}"
        # }
        # catch {
        #     git reset --hard "Target/$TargetBranch"
        #     FailOnError "Failed to reset for ${TargetRepo}:${TargetBranch}"
        # }
        git reset --hard "Target/$TargetBranch"
        FailOnError "Failed to reset for ${TargetRepo}:${TargetBranch}"
        # git -c user.name=$UserName -c user.email=$UserEmail merge --strategy-option theirs "Target/$TargetBranch"
        # FailOnError "Failed to merge for ${TargetRepo}:${TargetBranch}"
        # git -c user.name=$UserName -c user.email=$UserEmail rebase --strategy-option=theirs "Target/$TargetBranch"
        # FailOnError "Failed to rebase for ${TargetRepo}:${TargetBranch}"
    }

    git push Target "${pullRequestBranch}:refs/heads/${pullRequestBranch}"
    FailOnError "Failed to push to ${pullRequestBranch}:${pullRequestBranch}"
    
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
        git commit -m "Sync files from $SourceRepo/$SourceBranch"
        git push Target $($pullRequestBranch)
        FailOnError "Failed to push to $($TargetRepo):$($pullRequestBranch)"
    }
    else {
        write-host 22
        $diffResult = git diff "refs/remotes/Target/$TargetBranch"
        if ($diffResult) {
            write-host 999992
            git add .
            git commit -m "Sync files from $SourceRepo/$SourceBranch"
            git push Target $($pullRequestBranch)
            FailOnError "Failed to push to $($TargetRepo):$($TargetBranch)"
        }
        else {
            write-host 7777
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

    write-host $pullRequests
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
            -Head "$($OwnerName):$($pullRequestBranch)" `
            -Base $($TargetBranch) `
            -Title $($pullRequestTitle) `
            -Body $($pullRequestBody) `
            -MaintainerCanModify

        FailOnError "create $($TargetBranch) pull request: $_"

        Write-Host $newPullRequest
        echo "PR has been created at https://github.com/$($TargetRepo)/pull/$($newPullRequest.number)"
    }

    Set-Location $home_dir
}

TargetRepoClone
