@echo off

rem file      : build-msvc.bat
rem copyright : Copyright (c) 2014-2016 Code Synthesis Ltd
rem license   : MIT; see accompanying LICENSE file

setlocal EnableDelayedExpansion
goto start

:usage
echo.
echo Usage: %0 [/?] [^<install-dir^>]
echo.
echo By default the batch file will install into C:\build2. It also expects
echo to find the base utilities in the bin\ subdirectory of the installation
echo directory (C:\build2\bin\ by default).
echo.
echo Example usage:
echo.
echo %0 D:\build2
echo.
echo See the BOOTSTRAP-MSVC file for details.
echo.
goto end

:start

set "owd=%CD%"

if "_%1_" == "_/?_" goto usage

rem Package repository URL (or path).
rem
if "_%BUILD2_REPO%_" == "__" (
set "BUILD2_REPO=https://stage.build2.org/1"
rem set "BUILD2_REPO=https://pkg.cppget.org/1/alpha"
)

rem Bpkg configuration directory.
rem
set "cver=0.4"
set "cdir=build2-toolchain-%cver%"

rem Installation directory.
rem
if "_%1_" == "__" (
  set "idir=C:\build2"
) else (
  set "idir=%1"
)

if not exist %idir%\bin\ (
  echo error: %idir%\bin\ does not exist
  goto error
)

if exist build\config.build (
  echo current directory already configured, start with clean source
  goto error
)

if exist ..\%cdir%\ (
  echo ..\%cdir%\ bpkg configuration directory already exists
  goto error
)

set "sdir=%idir%\stage"
set "PATH=%idir%\bin;%PATH%"

rem Show the steps we are performing.
rem
@echo on

@rem Verify the compiler works.
@rem
cl
@if errorlevel 1 goto error

@rem Bootstrap.
@rem
cd build2

@rem Execute in a separate cmd.exe to preserve the echo mode.
@rem
cmd /C bootstrap-msvc.bat cl
@if errorlevel 1 goto error

build2\b-boot --version
@if errorlevel 1 goto error

build2\b-boot config.cxx=cl config.bin.lib=static
@if errorlevel 1 goto error

move /y build2\b.exe build2\b-boot.exe
@if errorlevel 1 goto error

build2\b-boot --version
@if errorlevel 1 goto error

@rem Build and stage the toolchain.
@rem
cd ..

build2\build2\b-boot configure^
 config.cxx=cl^
 config.bin.suffix=-stage^
 config.install.root=%idir%^
 config.install.data_root=root\stage
@if errorlevel 1 goto error

build2\build2\b-boot install
@if errorlevel 1 goto error

where b-stage
@if errorlevel 1 goto error

where bpkg-stage
@if errorlevel 1 goto error

b-stage --version
@if errorlevel 1 goto error

bpkg-stage --version
@if errorlevel 1 goto error

@rem Rebuild via package manager.
@rem
cd ..

md %cdir%
@if errorlevel 1 goto error

cd %cdir%

bpkg-stage create^
 cc^
 config.cxx=cl^
 "config.cc.coptions=/O2 /Oi"^
 config.install.root=%idir%
@if errorlevel 1 goto error

bpkg-stage add %BUILD2_REPO%
@if errorlevel 1 goto error

bpkg-stage fetch
@if errorlevel 1 goto error

bpkg-stage build --yes build2 bpkg
@if errorlevel 1 goto error

bpkg-stage install build2 bpkg
@if errorlevel 1 goto error

where b
@if errorlevel 1 goto error

where bpkg
@if errorlevel 1 goto error

b --version
@if errorlevel 1 goto error

bpkg --version
@if errorlevel 1 goto error

@rem Clean up stage.
@rem
cd %owd%
b uninstall
@if errorlevel 1 goto error

@echo off

echo.
echo Toolchain installation: %idir%\bin
echo Upgrade configuration:  %cdir%
echo.

goto end

:error
@echo off
cd %owd%
endlocal
exit /b 1

:end
endlocal
