@echo off
rem Convertit l'export OBJ de SketchUp en model.glb pour l'app.
rem
rem Avant de lancer :
rem   1. Exporter depuis SketchUp : Fichier -> Exporter -> Modele 3D -> OBJ
rem      Options : Exporter materiaux/textures ON, "Swap YZ coordinates (Y up)" ON
rem   2. Placer Plan 3D.obj + Plan 3D.mtl + dossier textures ici (meme dossier que ce script)
rem
rem Dependance : Node.js doit etre installe (https://nodejs.org)
rem
rem Usage : double-cliquer sur ce fichier, ou l'executer depuis PowerShell

cd /d "%~dp0"
echo Conversion OBJ -^> GLB...
npx obj2gltf -i "Plan 3D.obj" -o "..\model.glb"
if %errorlevel%==0 (
  echo.
  echo OK : model.glb genere dans le dossier racine du projet.
  echo Commiter + pousser pour deployer sur Vercel.
) else (
  echo.
  echo ERREUR : verifier que Plan 3D.obj est present dans ce dossier.
)
pause
