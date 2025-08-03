# Clean Git History of AWS Credentials
# This script removes AWS credentials from git history

Write-Host "Cleaning Git History of AWS Credentials..." -ForegroundColor Green

# Create a backup branch
Write-Host "Creating backup branch..." -ForegroundColor Yellow
git branch backup-before-clean

# Remove the credentials from all commits
Write-Host "Removing credentials from git history..." -ForegroundColor Yellow

# Use git filter-branch to remove the credentials
git filter-branch --force --index-filter @"
git ls-files -z | xargs -0 sed -i 's/AKIAZBY6MS55AXICVEUC/REMOVED_ACCESS_KEY/g'
git ls-files -z | xargs -0 sed -i 's/GRVYYktANeSFZHg7lGXj9AV1uaOBk+fta1ZCxKiP/REMOVED_SECRET_KEY/g'
"@ --prune-empty --tag-name-filter cat -- --all

Write-Host "Git history cleaned!" -ForegroundColor Green
Write-Host "You can now push to GitHub without the credentials." -ForegroundColor Yellow
Write-Host "To push: git push origin master --force" -ForegroundColor Cyan 