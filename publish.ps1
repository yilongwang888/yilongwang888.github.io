# Publish this site to GitHub Pages.
# Usage:
#   1. Edit $GitHubUser below
#   2. In PowerShell:  .\publish.ps1
# Requires: git, and GitHub login (gh auth login  OR  browser prompt on push)

param(
  [Parameter(Mandatory = $true)]
  [string]$GitHubUser,
  [string]$RepoName = ""
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not $RepoName) {
  $RepoName = "$GitHubUser.github.io"
}

Write-Host "Repo will be: https://github.com/$GitHubUser/$RepoName"
Write-Host "Site will be: https://$GitHubUser.github.io/" -ForegroundColor Cyan

if (-not (Test-Path .git)) {
  git init
  git branch -M main
}

git add index.html styles.css README.md
git status

$hasCommit = git rev-parse --verify HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
  git commit -m "Initial personal site for GitHub Pages"
} else {
  git commit -m "Update personal site" --allow-empty-from-status 2>$null
  if ($LASTEXITCODE -ne 0) {
    # commit only if there are staged changes
    $staged = git diff --cached --quiet; if ($LASTEXITCODE -ne 0) {
      git commit -m "Update personal site"
    } else {
      Write-Host "No changes to commit."
    }
  }
}

$remote = "https://github.com/$GitHubUser/$RepoName.git"
$existing = git remote get-url origin 2>$null
if ($LASTEXITCODE -ne 0) {
  git remote add origin $remote
} else {
  git remote set-url origin $remote
}

# Create repo if gh is available
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
  gh repo view "$GitHubUser/$RepoName" 2>$null
  if ($LASTEXITCODE -ne 0) {
    gh repo create $RepoName --public --source=. --remote=origin --push
  } else {
    git push -u origin main
  }
  gh pages --help 2>$null | Out-Null
  # Enable Pages from main root via API
  gh api -X POST "repos/$GitHubUser/$RepoName/pages" -f build_type=legacy -f source[branch]=main -f source[path]=/ 2>$null
  if ($LASTEXITCODE -ne 0) {
    gh api -X PUT "repos/$GitHubUser/$RepoName/pages" -f build_type=legacy -f source[branch]=main -f source[path]=/ 2>$null
  }
  Write-Host ""
  Write-Host "Done. Open: https://$GitHubUser.github.io/" -ForegroundColor Green
  Write-Host "If 404, wait 1-2 minutes, or set Pages in repo Settings > Pages > Deploy from branch main / root."
} else {
  Write-Host ""
  Write-Host "GitHub CLI (gh) not found. Do this in browser:" -ForegroundColor Yellow
  Write-Host "  1. Create public repo named exactly: $RepoName"
  Write-Host "  2. Then run:"
  Write-Host "       git push -u origin main"
  Write-Host "  3. Settings > Pages > Source: Deploy from a branch > main > / (root) > Save"
  Write-Host "  4. Open https://$GitHubUser.github.io/"
}
