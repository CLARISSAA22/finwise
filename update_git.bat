@echo off
echo ====================================================
echo   GitHub Remote Setup and Push
echo ====================================================
echo.
set /p new_url="Enter your NEW GitHub repository URL (e.g., https://github.com/newuser/finwise.git): "
echo.
echo Setting new remote URL...
git remote set-url origin %new_url%
echo.
echo Adding files...
git add .
git commit -m "Update deployment configuration for new account"
echo.
echo Pushing to new repository...
git push -u origin main
echo.
echo If it says 'src refspec main does not match any', trying master...
git push -u origin master
echo.
echo Done! 
echo Make sure to log into Render with your NEW GitHub account!
pause
