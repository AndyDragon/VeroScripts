#!/bin/bash

cd PrepareTemplates
dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true
cp ./bin/Release/net7.0/win-x64/publish/PrepareTemplates.exe ../PrepareTemplates.exe
dotnet publish -c Release -r linux-x64 --self-contained true /p:PublishSingleFile=true
cp ./bin/Release/net7.0/linux-x64/publish/PrepareTemplates ../PrepareTemplates-linux
dotnet publish -c Release -r osx-x64 --self-contained true /p:PublishSingleFile=true
cp ./bin/Release/net7.0/osx-x64/publish/PrepareTemplates ../PrepareTemplates-mac
cd ..
