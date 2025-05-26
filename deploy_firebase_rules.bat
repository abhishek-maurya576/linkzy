@echo off
echo Deploying Firestore rules and indexes...

rem Set the project ID
set PROJECT_ID=linkzy-b883e

rem Make sure Firebase CLI is installed
call npm list -g firebase-tools >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Firebase CLI not found. Installing...
  call npm install -g firebase-tools
)

echo Please login to your Firebase account...
call firebase login

echo Setting project to %PROJECT_ID%...
call firebase use --add %PROJECT_ID%

echo Deploying Firestore rules...
call firebase deploy --only firestore:rules --project %PROJECT_ID%

echo Deploying Firestore indexes...
call firebase deploy --only firestore:indexes --project %PROJECT_ID%

echo Done! Your Firestore rules and indexes have been deployed.
pause 