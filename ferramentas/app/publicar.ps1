param([string]$Token = $env:FISCAL_PUBLICAR_TOKEN, [string]$Departamento = 'fiscal')
$ErrorActionPreference = 'Stop'
$raiz = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$saida = Join-Path $raiz 'build\app'

$alvos = @{
    fiscal      = @{ url = 'https://vvohwixeokxydmbhqklu.supabase.co'; chave = 'sb_publishable_jQVklnYdEmsbVYzsp7_0Nw_ZLht78GM'; jvm = @('-Dfile.encoding=UTF-8') }
    legalizacao = @{ url = 'https://ynqcmzukahkmqbvirlkb.supabase.co'; chave = 'sb_publishable_YWo2MLN_-IBgo9cIMmOezw_tCD5cWz6'; jvm = @('-Dfile.encoding=UTF-8', '-Dfiscal.front=estavel') }
}
$alvo = $alvos[$Departamento]
if (-not $alvo) { throw "departamento desconhecido: $Departamento" }
$edge = "$($alvo.url)/functions/v1/fiscal-app-publicar"

if (-not $Token) {
    $cofre = Join-Path $env:APPDATA 'Fiscal-publicar\token.dpapi'
    $sec = Get-Content $cofre | ConvertTo-SecureString
    $Token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

& (Join-Path $PSScriptRoot 'compilar.ps1') -Departamento $Departamento
if ($LASTEXITCODE) { throw 'falha ao compilar' }

$arquivos = @()
$arquivos += Get-Item (Join-Path $saida 'fiscal.jar')
$arquivos += Get-ChildItem (Join-Path $saida 'lib') -Filter *.jar | Sort-Object Name
$lancador = Get-Item (Join-Path $saida 'fiscal-lancador.jar')

function Item($f) {
    [ordered]@{ nome = $f.Name; sha256 = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower(); tamanho = $f.Length; caminho = $f.FullName }
}
$itens = @($arquivos | ForEach-Object { Item $_ })
$itemLanc = Item $lancador
$todos = @($itens) + @($itemLanc)

$h = @{ 'x-publicar-token' = $Token }
$pedido = @{ acao = 'faltando'; arquivos = @($todos | ForEach-Object { @{ sha256 = $_.sha256; tamanho = $_.tamanho } }) } | ConvertTo-Json -Depth 5
$r = Invoke-RestMethod -Method Post -Uri $edge -Headers $h -Body $pedido -ContentType 'application/json'
foreach ($f in $r.faltam) {
    $it = $todos | Where-Object { $_.sha256 -eq $f.sha256 } | Select-Object -First 1
    Write-Host "Enviando $($it.nome) ($([math]::Round($it.tamanho/1KB)) KB)"
    Invoke-RestMethod -Method Put -Uri $f.url -InFile $it.caminho -ContentType 'application/octet-stream' -Headers @{ 'x-upsert' = 'true'; 'cache-control' = 'max-age=31536000' } | Out-Null
}

$commit = (git -C $raiz rev-parse --short HEAD).Trim()
$versao = (Get-Date -Format 'yyyy.MM.dd-HHmm') + '-' + $commit
$manifesto = [ordered]@{
    principal = 'com.you.fiscal.FiscalApplication'
    jvm = $alvo.jvm
    arquivos = @($itens | ForEach-Object { [ordered]@{ nome = $_.nome; sha256 = $_.sha256; tamanho = $_.tamanho } })
    lancador = [ordered]@{ nome = $itemLanc.nome; sha256 = $itemLanc.sha256; tamanho = $itemLanc.tamanho }
}
$corpo = [ordered]@{ acao = 'publicar'; aplicativo = $Departamento; versao = $versao; manifesto = $manifesto } | ConvertTo-Json -Depth 6
$p = Invoke-RestMethod -Method Post -Uri $edge -Headers $h -Body ([Text.Encoding]::UTF8.GetBytes($corpo)) -ContentType 'application/json; charset=utf-8'
if (-not $p.ok) { throw "publicacao recusada: $($p | ConvertTo-Json -Compress)" }

$conf = Invoke-RestMethod -Uri "$($alvo.url)/rest/v1/fiscal_app_versao?aplicativo=eq.$Departamento&select=versao" -Headers @{ apikey = $alvo.chave }
if ($conf[0].versao -ne $versao) { throw "versao no ar ($($conf[0].versao)) diferente da publicada ($versao)" }
foreach ($it in $todos) {
    $u = "$($alvo.url)/storage/v1/object/public/fiscal-app/arquivos/$($it.sha256)"
    $resp = Invoke-WebRequest -Method Head -Uri $u -UseBasicParsing
    if ([int64]$resp.Headers['Content-Length'] -ne $it.tamanho) { throw "arquivo no ar com tamanho errado: $($it.nome)" }
}
Write-Host "Publicado e conferido: $versao ($($r.faltam.Count) arquivo(s) novo(s) de $($todos.Count))"
