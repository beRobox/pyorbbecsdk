@echo off
WHERE cmake
IF %ERRORLEVEL% NEQ 0 ECHO CMake wasn't found, if installed make sure it's added to the PATH

SET /p MinGW_PATH= Provide a path for MinGW (/bin) You can find an installation at https://github.com/skeeto/w64devkit/releases/latest: 
SET PATH=%PATH%;%MinGW_PATH%

python -m venv ./venv

@REM # Enter python virtual env
call venv\Scripts\activate

pip install -r requirements.txt

for /f "tokens=*" %%a in ('pybind11-config --cmakedir') do SET pybind11_DIR=%%a

rmdir /s /q build
mkdir build

cd build

SET CMAKE_CXX_COMPILER="%MinGW_PATH%\g++.exe"
SET CMAKE_C_COMPILER="%MinGW_PATH%\gcc.exe"

cmake -G "MinGW Makefiles" ..

@REM # Remove old /install directory and create new /install/lib directory
rmdir /s /q install

make -j4
make install

@REM # Move back to the parent directory
cd ..

mkdir ./install/lib/pyorbbecsdk/examples
mkdir ./install/lib/pyorbbecsdk/config

@REM # Copy shared objects (*.pyd) from /build to /install/lib
robocopy ./build/Release/ ./install/lib/ *.pyd /E

@REM # Copy all c++ librarys except *.cmake to /install/lib
robocopy ./sdk/lib/win_x64/ ./install/lib/ /E

@REM # Copy examples to /install/lib
robocopy ./examples/ ./install/lib/pyorbbecsdk/examples /E
robocopy ./requirements.txt ./install/lib/pyorbbecsdk/examples
robocopy ./config ./install/lib/pyorbbecsdk/config /E

@echo off
REM Get the directory of the currently running batch script
SET "CURR_DIR=%~dp0"

REM Remove trailing backslash if present
IF "%CURR_DIR:~-1%"=="\" SET "CURR_DIR=%CURR_DIR:~0,-1%"

REM Set the PYTHONPATH environment variable
SET "PYTHONPATH=%CURR_DIR%\install\lib;%PYTHONPATH%"

pip3 install pybind11-stubgen
pybind11-stubgen pyorbbecsdk

copy "stubs\pyorbbecsdk.pyi" "install\lib\pyorbbecsdk\__init__.pyi"

@REM # Run Python setup.py to build a wheel package
python setup.py bdist_wheel

@REM # Exit python virtual env
call deactivate