$ErrorActionPreference = 'Stop'
$raiz = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$build = Join-Path $raiz 'build'
if (-not (Test-Path (Join-Path $build 'app\fiscal-lancador.jar'))) { & (Join-Path $PSScriptRoot 'compilar.ps1') }

$imagem = Join-Path $build 'imagem'
$runtime = Join-Path $build 'runtime'
$entrada = Join-Path $build 'entrada'
foreach ($d in @($imagem, $runtime, $entrada)) { if (Test-Path $d) { Remove-Item -Recurse -Force $d } }
New-Item -ItemType Directory -Force $entrada | Out-Null
Copy-Item (Join-Path $build 'app\fiscal-lancador.jar') $entrada

$jmods = Join-Path $env:JAVA_HOME 'jmods'
if (-not $env:JAVA_HOME) { $jmods = Join-Path (Split-Path (Split-Path (Get-Command java).Source)) 'jmods' }
& jlink --module-path $jmods --add-modules ALL-MODULE-PATH --strip-debug --no-header-files --no-man-pages --output $runtime
if ($LASTEXITCODE) { throw 'falha no jlink' }

& jpackage --type app-image --name Fiscal --dest $imagem --input $entrada --main-jar fiscal-lancador.jar `
    --main-class com.you.fiscal.lancador.Lancador --runtime-image $runtime `
    --icon (Join-Path $raiz 'app\src\main\resources\icone\fiscal.ico') --vendor 'You Contabilidade' --app-version 1.0
if ($LASTEXITCODE) { throw 'falha no jpackage' }

$jcef = Join-Path $build 'jcef'
if (Test-Path $jcef) { Remove-Item -Recurse -Force $jcef }
Copy-Item -Recurse (Join-Path $env:USERPROFILE '.fiscal-jcef') $jcef

$iscc = Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'
& $iscc /Q (Join-Path $PSScriptRoot 'fiscal.iss')
if ($LASTEXITCODE) { throw 'falha no Inno Setup' }
Get-Item (Join-Path $build 'instalador\Fiscal-Instalador.exe') | Select-Object FullName, Length
