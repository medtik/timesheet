REM Copyright © 2018-2019 Stanislav Valasek <valasek@gmail.com>

@ECHO OFF
set zip="C:\Program Files\7-Zip\7z.exe"
set version="1.2.2"
REM rem git describe --tags

if "%1" == "cloud" (
    echo building cloud build
    copy .\client\.env.production.cloud .\client\.env.production.local
    copy .\server\timesheet-cloud.yaml .\server\timesheet-prod.yaml
) else (
    echo building DataArch build
    copy .\client\.env.production.dataarch.local .\client\.env.production.local
    copy .\server\timesheet-dataarch.yaml .\server\timesheet-prod.yaml
)

ECHO ==============================================
ECHO Removing aftifacts from the previous build ...
IF EXIST .\build\timesheet.exe del .\build\timesheet.exe
IF EXIST .\build\timesheet.app del .\build\timesheet.app
IF EXIST .\build\timesheet.bin del .\build\timesheet.bin
IF EXIST .\build\timesheet_arm.bin del .\build\timesheet_arm.bin
IF EXIST .\build\timesheet.yaml del .\build\timesheet.yaml
IF EXIST .\build\timesheet-prod.yaml del .\build\timesheet-prod.yaml
IF EXIST .\build\MS_Windows_64bit.zip del .\build\MS_Windows_64bit.zip
IF EXIST .\build\Linux_64bit.zip del .\build\Linux_64bit.zip
IF EXIST .\build\Raspberry_Pi.zip del .\build\Raspberry_Pi.zip
IF EXIST .\build\Mac_OS_X_64bit.zip del .\build\Mac_OS_X_64bit.zip
IF EXIST .\build\documentation\documentation.md del .\build\documentation\documentation.md
IF EXIST .\build\logs\error.log del .\build\logs\error.log
IF EXIST .\build\logs\info.log del .\build\logs\info.log
IF EXIST .\build\client\dist\ @RD /S /Q .\build\client\dist
del .\build\data\*.csv /F /Q

ECHO ======================
ECHO Compiling frontend ...
cd .\client
call npm run build
xcopy .\dist .\..\build\client\dist\ /s /e
cd ..

ECHO =====================
ECHO Compiling backend ...
cd .\server
if "%1" == "cloud" (
    copy .\timesheet-cloud.yaml .\..\build\timesheet.yaml
    copy .\data\consultants_cloud.csv .\..\build\data\consultants_cloud.csv
    copy .\data\holidays_us_2019.csv .\..\build\data\holidays_us_2019.csv
    copy .\data\projects_cloud.csv .\..\build\data\projects_cloud.csv
    copy .\data\rates_cloud.csv .\..\build\data\rates_cloud.csv
    copy .\data\reported_records_cloud.csv .\..\build\data\reported_records_cloud.csv
) else (
    copy .\timesheet-dataarch.yaml .\..\build\timesheet.yaml
    copy .\data\consultants_dataarch.csv .\..\build\data\consultants_dataarch.csv
    copy .\data\holidays_cz_2019.csv .\..\build\data\holidays_cz_2019.csv
    copy .\data\projects_dataarch.csv .\..\build\data\projects_dataarch.csv
    copy .\data\rates_dataarch.csv .\..\build\data\rates_dataarch.csv
    copy .\data\reported_records_dataarch.csv .\..\build\data\reported_records_dataarch.csv
)
copy .\documentation\documentation.md .\..\build\documentation\documentation.md

ECHO MS Windows, 64-bit ...
set GOOS=windows
set GOARCH=amd64
go build -ldflags "-X github.com/valasek/timesheet/server/version.Version=%version%" -o .\..\build\timesheet.exe .\timesheet.go
ECHO Linux, 64-bit...
set GOOS=linux
set GOARCH=amd64
go build -ldflags "-X github.com/valasek/timesheet/server/version.Version=%version%" -o .\..\build\timesheet.bin .\timesheet.go
ECHO Raspberry Pi, ARM 5 ...
set GOOS=linux
set GOARCH=arm
set GOARM=5
go build -ldflags "-X github.com/valasek/timesheet/server/version.Version=%version%" -o .\..\build\timesheet_arm.bin .\timesheet.go
ECHO MAC OS X, 64-bit ...
set GOOS=darwin
set GOARCH=amd64
go build -ldflags "-X github.com/valasek/timesheet/server/version.Version=%version%" -o .\..\build\timesheet.app .\timesheet.go
cd ..

ECHO =========================
ECHO Compressing artifacts ...
cd .\build
call %zip% a -r MS_Windows_64bit.zip timesheet.exe timesheet.yaml client/ data/ logs/ documentation/
call %zip% a -r Linux_64bit.zip ./timesheet.bin ./timesheet.yaml client/ data/ logs/ documentation/
call %zip% a -r Raspberry_Pi.zip ./timesheet_arm.bin ./timesheet.yaml client/ data/ logs/ documentation/
call %zip% a -r Mac_OS_X_64bit.zip ./timesheet.app ./timesheet.yaml client/ data/ logs/ documentation/
cd ..

ECHO ===========
ECHO Builds are ready

@ECHO ON