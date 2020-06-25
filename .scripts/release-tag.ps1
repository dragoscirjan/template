param(
  [switch]$Help,
  [switch]$Major,
  [switch]$Minor,
  [switch]$Patch,
  [switch]$Dev,
  [switch]$Rc,
  [switch]$Alpha,
  [switch]$Beta,
  [switch]$Clear,
  [switch]$Dry,
  [switch]$F,
  [System.String]$Version = '',
  [System.String]$VersionFile = ''
)

if ($Help) {
  Write-Host "#######################################################################"
  Write-Host "usage: release-tag.ps1 [major|minor|patch]"
  Write-Host ""
  Write-Host "  -dry Dry run"
  Write-Host "  -major for a major release"
  Write-Host "  -minor for a minor release"
  Write-Host "  -patch for a patch release"
  Write-Host ""
  Write-Host "  -rc    for adding -rcX suffix"
  Write-Host "  -dev   for adding -dev suffix"
  Write-Host "  -alpha for adding -alpha suffix"
  Write-Host "  -beta  for adding -beta suffix"
  Write-Host "  -clear for clearing suffix"
  Write-Host ""
  Write-Host "  -version for initializing version"
  Write-Host "  -versionfile for file track of version instead of git tag"
  Write-Host "#######################################################################"
  Write-Host ""
  exit 0
}

Set-Location -Path $PSScriptRoot\..

if (-not $Major -and -not $Minor -and -not $Patch) {
  $Patch = $True;
}

if (-not $Version) {
  Write-Host -ForegroundColor Gray "Fetching Tags ..."
  git fetch --prune --tags

  $Version = (git describe --abbrev=0 --tags)
} else {
  if ($VersionFile) {
    if (Test-Path $VersionFile -PathType Leaf) {
      $Version = Get-Content -Path $VersionFile
    } else {
      Write-Host -ForegroundColor Red "Version file missing: $VersionFile"
    }
  }
}

$RcVersion = '0';

Write-Host -ForegroundColor Gray "Current Version: $Version"

$tokens = $version.Substring(1, $version.Length - 1).Split('-')
# obtain rc version
if ($tokens -is [array] -and $tokens.Count -gt 1) {
  $RcVersion = $tokens[1].replace('rc', '');
}
# split version into major, minor, patch
$tokens = $tokens[0].Split('.')

$prefix = ''

# if RC, alpha, beta, dev
if (-not $Clear) {
  if ($Rc) {
    $RcVersion = [int]$RcVersion + 1
    $prefix = '-rc' + $RcVersion
  } else {
    if ($Alpha) {
      $prefix = '-alpha'
    } else {
      if ($Beta) {
        $prefix = '-beta'
      } else {
        if ($Dev) {
          $prefix = '-dev'
        }
      }
    }
  }
}

$Inc = (-not $Alpha -and -not $Beta -and -not $Dev -and -not $Rc -and -not $Clear) -or $F

# if not rc, alpha, beta, dev or forced, increase version
if ($Inc) {
  if ($Major) {
    $tokens[0] = [int]$tokens[0] + 1
    $tokens[1] = 0
    $tokens[2] = 0
    $Minor = $False
    $Patch = $False
  }
  if ($Minor) {
    $tokens[1] = [int]$tokens[1] + 1
    $tokens[2] = 0
    $Patch = $False
  }
  if ($Patch) {
    $tokens[2] = [int]$tokens[2] + 1
  }
}

# compose version from version and rc/alpha/beta/dev prefix
$version = 'v' + ($tokens -Join '.') + $prefix

# prepare commit message
$UserName  = $(git config user.name)
$Message = "Version increase to $Version by $UserName"

# If its a dry run, just display the new release version number
if ($Dry) {
  Write-Host -ForegroundColor Gray "Tag message: $Message"
  Write-Host -ForegroundColor Green  "Next version: $Version"
} else {
  if ($VersionFile) {
    Write-Output $Version | Set-Content -Path $VersionFile
    git add $VersionFile
    git commit $VersionFile -m "$Message"
  }

  # Push master
  git push origin master

  # Add tag
  Write-Host -ForegroundColor Gray "Add git tag $Version with message: $Message"
  git tag -a "$Version" -m "$Message"

  # Push tag
  Write-Host -ForegroundColor Gray "Push the tag"
  git push --tags origin master

  Write-Host -ForegroundColor Green "Release tag done: $Version"
}

# Set-Location -Path $PSScriptRoot
