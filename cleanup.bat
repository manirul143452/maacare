@echo off
echo Cleaning up MaaCare repository...

del hs_err_pid*.log /q 2>nul
del replay_pid*.log /q 2>nul
del build_log*.txt /q 2>nul
del web_build.log /q 2>nul
del analyze.log /q 2>nul
del build_error.txt /q 2>nul
del Untitled-1.txt /q 2>nul
del "maacare.lnk" /q 2>nul
del "maacare (2).lnk" /q 2>nul
del fix.dart /q 2>nul
del setup_images.dart /q 2>nul
del test_auth.dart /q 2>nul

echo Cleanup complete!
pause
