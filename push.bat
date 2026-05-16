@echo off
echo Adding files to git...
git add .
echo.
echo Committing changes...
git commit -m "Update deployment configuration"
echo.
echo Pushing to GitHub...
git push origin main
echo.
echo If it says 'src refspec main does not match any', trying master...
git push origin master
echo.
echo Done!
pause
