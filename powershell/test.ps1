
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
# test
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

function test4 {
    $TargetSyncFilePath = "/cSpell.json", "/custom-words.txt", "/specification/common-types/resource-management"
    $SourceSyncFilePath = "/cSpell.json", "/custom-words.txt"

    foreach ($item in $SourceSyncFilePath) {
        $index = $SourceSyncFilePath.IndexOf($item)
        Write-Host $SourceSyncFilePath[$index]

        if ($null -eq $TargetSyncFilePath[$index]) {
            Write-Host 11
        }

    }
}
# test4

Function Test5 {
    Param      
    (       
        [parameter(Mandatory = $true)]$Name,       
        $Age = "18"       
    )
    Write-Host "$Name 今年 $Age 岁."      
}
# Test5

function Test6 {
    $a = coalesce(1,2)
    write-host $a
}

Test6