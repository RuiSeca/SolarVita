@echo off
echo Setting up environment for Flutter 3.32.7...

REM Set locale environment variables
set JAVA_OPTS=-Duser.country=US -Duser.language=en -Dfile.encoding=UTF-8 -Duser.timezone=UTC
set GRADLE_OPTS=-Duser.country=US -Duser.language=en -Dfile.encoding=UTF-8 -Duser.timezone=UTC
set LC_ALL=en_US.UTF-8
set LANG=en_US.UTF-8

echo Cleaning project...
flutter clean

echo Getting dependencies...
flutter pub get

echo Running app...
flutter run

pause