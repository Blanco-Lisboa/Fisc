$ErrorActionPreference = 'Stop'
$raiz = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$saida = Join-Path $raiz 'build\app'
$app = Join-Path $raiz 'app'

$mvn = (Get-Command mvn.cmd -ErrorAction SilentlyContinue).Source
if (-not $mvn) { $mvn = (Get-ChildItem (Join-Path $env:USERPROFILE '.m2\wrapper\dists') -Recurse -Filter mvn.cmd | Sort-Object FullName -Descending | Select-Object -First 1).FullName }
if (-not $mvn) { throw 'maven nao encontrado' }

if (Test-Path $saida) { Remove-Item -Recurse -Force $saida }
New-Item -ItemType Directory -Force (Join-Path $saida 'lib') | Out-Null

$alvo = Join-Path $raiz 'build\maven'
& $mvn -q -f (Join-Path $app 'pom.xml') "-Dfiscal.build.dir=$alvo" -DskipTests clean package
if ($LASTEXITCODE) { throw 'falha no maven (package)' }
& $mvn -q -f (Join-Path $app 'pom.xml') "-Dfiscal.build.dir=$alvo" dependency:copy-dependencies -DincludeScope=runtime "-DoutputDirectory=$(Join-Path $saida 'lib')"
if ($LASTEXITCODE) { throw 'falha no maven (dependencias)' }
$jar = Get-ChildItem $alvo -Filter *.jar.original | Select-Object -First 1
Copy-Item $jar.FullName (Join-Path $saida 'fiscal.jar')

$cls = Join-Path $raiz 'build\lancador'
if (Test-Path $cls) { Remove-Item -Recurse -Force $cls }
New-Item -ItemType Directory -Force $cls | Out-Null
$fontes = Get-ChildItem (Join-Path $raiz 'lancador\src') -Recurse -Filter *.java | ForEach-Object { $_.FullName }
& javac --release 21 -encoding UTF-8 -d $cls @fontes
if ($LASTEXITCODE) { throw 'falha ao compilar o lancador' }
Copy-Item (Join-Path $app 'src\main\resources\icone\fiscal-64.png') $cls
& jar --create --date=2026-01-01T00:00:02Z --file (Join-Path $saida 'fiscal-lancador.jar') --main-class com.you.fiscal.lancador.Lancador -C $cls .
if ($LASTEXITCODE) { throw 'falha ao empacotar o lancador' }
Write-Host "Compilado em $saida"
