param([string]$OutputDirectory = 'docs/expansion_20261015')
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$downloads = 'C:\Users\Administrator\Downloads'
$packages = @(
    @{Role='office'; Name='电报房.rar'},
    @{Role='camp'; Name='伐木场破房子合集.rar'},
    @{Role='village'; Name='东北农村.rar'},
    @{Role='rifle'; Name='98k步枪.rar'},
    @{Role='dock'; Name='渡口和小船.rar'},
    @{Role='river'; Name='河（可以删掉里面的鱼之类的没用模型）.rar'},
    @{Role='fence'; Name='栅栏铁丝网.rar'}
)
$results = @(foreach ($package in $packages) {
    $original = Join-Path $downloads $package.Name
    $preserved = Join-Path $workspace ('AssetLibrary/environment/user_expansion_20261015/' + $package.Role + '/original.rar')
    $sourceHash = (Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash.ToLowerInvariant()
    $savedHash = (Get-FileHash -LiteralPath $preserved -Algorithm SHA256).Hash.ToLowerInvariant()
    [ordered]@{Role=$package.Role; Original=$original; Preserved=$preserved; Bytes=(Get-Item -LiteralPath $preserved).Length; SHA256=$savedHash; Matches=($sourceHash -eq $savedHash)}
})
$result = [ordered]@{CheckedAt=[DateTimeOffset]::Now.ToString('o'); Packages=$results; Passed=(@($results | Where-Object { -not $_.Matches }).Count -eq 0)}
$destination = Join-Path $workspace $OutputDirectory
[IO.Directory]::CreateDirectory($destination) | Out-Null
[IO.File]::WriteAllText((Join-Path $destination 'source-package-verification.json'), (ConvertTo-Json -InputObject $result -Depth 8), [Text.UTF8Encoding]::new($false))
$results | ForEach-Object { '{0}: {1}, {2} bytes' -f $_.Role,$_.Matches,$_.Bytes }
if (-not $result.Passed) { throw 'One or more supplied archives differ from preserved copies.' }
