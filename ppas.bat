@echo off
SET THEFILE=C:\DATA\ensino\aulas\informatica_industrial_MIEIGI\2020_21\trabalho\lazarus\comm_MES_PLC_V3\project1.exe
echo Linking %THEFILE%
C:\lazarus\fpc\3.0.4\bin\x86_64-win64\ld.exe -b pei-x86-64  --gc-sections   --subsystem windows --entry=_WinMainCRTStartup    -o C:\DATA\ensino\aulas\informatica_industrial_MIEIGI\2020_21\trabalho\lazarus\comm_MES_PLC_V3\project1.exe C:\DATA\ensino\aulas\informatica_industrial_MIEIGI\2020_21\trabalho\lazarus\comm_MES_PLC_V3\link.res
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
