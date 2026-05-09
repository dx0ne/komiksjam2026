@echo off
echo Git Push Helper
echo --------------

cd ..

if not exist ".git" (
    echo Error: Not in a git repository!
    pause
    exit /b 1
)

echo.
echo Current git status:
git status

echo.
set /p CONTINUE="Do you want to continue with the push? (Y/N): "
if /i not "%CONTINUE%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo.
echo Adding all changes...
git add .

echo.
set /p COMMIT_MSG="Enter commit message: "
git commit -m "%COMMIT_MSG%"

echo.
echo Pushing changes to remote repository...
git push origin main

echo.
echo Operation completed!
pause