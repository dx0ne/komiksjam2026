@echo off
echo Checking for Komiks Game Jam 2025 repository...

cd ..
if exist ".git" (
    echo Repository exists. Updating...
    git pull
    echo Repository has been updated!
)