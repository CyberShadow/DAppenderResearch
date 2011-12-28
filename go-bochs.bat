@echo off
call dbuildr -version=DOS -defaultlib=phobos_dos -debuglib=phobos_dos -oftest2dos.exe test2
cd C:\Temp\bochs-dos
call makefloppy.bat
