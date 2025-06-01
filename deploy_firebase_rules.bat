@echo off
echo Deploying Firestore Security Rules...
firebase deploy --only firestore:rules
echo Done!
pause 