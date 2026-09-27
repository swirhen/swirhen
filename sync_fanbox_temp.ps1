<#
.SYNOPSIS
    fanbox_temp 同期・圧縮転送スクリプト
.DESCRIPTION
    ローカルの fanbox_temp 配下のフォルダを走査し同期処理を行います。
    
    1. 通常フォルダ:
       サブフォルダが複数ある場合、
       全フォルダ（最新含む）を zip 圧縮して SMB 共有へ転送。（ファイルの存在しないフォルダは処理しない）
       ローカル側は最新フォルダのみ保持し、それ以外のフォルダは削除します。

    2. 連番管理対象フォルダ ($SpecialCreators で指定):
       SMB側の同名フォルダ配下にある連番(01〜nn)フォルダの最大値フォルダへ、
       ローカルのサブフォルダ内のファイルのみを移動（上書き）。
       移動前に連番フォルダ内のファイル数が100件以上であれば、
       その連番フォルダをzip圧縮してフォルダを削除し、新規インクリメント連番フォルダを作成してそこへ移動します。
       ファイル移動完了後、フォルダは最新フォルダを保持して削除します。
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [string]$LocalBasePath = "C:\Users\swirh\Downloads\fanbox_temp",
    [string]$SmbBasePath   = "\\192.168.0.108\share\temp\fanbox_temp",
    # 連番フォルダ管理を行う対象クリエイター名（配列で複数指定可能、環境変数や引数から指定可能）
    [string[]]$SpecialCreators = @("豆ラッコ")
)

# パスの存在確認
if (-not (Test-Path -LiteralPath $LocalBasePath)) {
    Write-Error "ローカルフォルダが見つかりません: $LocalBasePath"
    return
}
if (-not (Test-Path -LiteralPath $SmbBasePath)) {
    Write-Error "SMB共有フォルダにアクセスできません: $SmbBasePath"
    return
}

# -------------------------------------------------------------------------
# ヘルパー関数: zip ファイル名の長さを 255 バイト (UTF-8) 以内に切り詰める
# 「フォルダ名 + .zip」のバイト数が 255 を超える場合、文字単位で安全に短縮します。
# -------------------------------------------------------------------------
function Get-SafeZipName {
    param ([string]$FolderName)
    $enc = [System.Text.Encoding]::UTF8
    $suffix = '.zip'
    $maxBytes = 255 - $enc.GetByteCount($suffix)  # .zip の分を引いた上限
    $nameBytes = $enc.GetBytes($FolderName)
    if ($nameBytes.Length -le $maxBytes) {
        return $FolderName + $suffix
    }
    # バイト数が超過する場合: 文字境界を壊さないよう後ろから削る
    $truncated = [System.Text.StringBuilder]::new()
    $bytesUsed = 0
    foreach ($ch in $FolderName.GetEnumerator()) {
        $chBytes = $enc.GetByteCount([string]$ch)
        if ($bytesUsed + $chBytes -gt $maxBytes) { break }
        [void]$truncated.Append($ch)
        $bytesUsed += $chBytes
    }
    return $truncated.ToString() + $suffix
}

# -------------------------------------------------------------------------
# ヘルパー関数: Windows 通知の表示
# -------------------------------------------------------------------------
function Show-Notification {
    param (
        [string]$Title,
        [string]$Message
    )
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $notify = New-Object System.Windows.Forms.NotifyIcon
        $notify.Icon = [System.Drawing.SystemIcons]::Information
        $notify.BalloonTipTitle = $Title
        $notify.BalloonTipText = $Message
        $notify.Visible = $true
        $notify.ShowBalloonTip(10000)
        Start-Sleep -Seconds 1
        $notify.Dispose()
    }
    catch {
        Write-Warning "通知の表示に失敗しました: $($_.Exception.Message)"
    }
}


Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " fanbox_temp 同期・圧縮転送処理を開始します" -ForegroundColor Cyan
Write-Host " ローカル      : $LocalBasePath" -ForegroundColor Gray
Write-Host " 共有先        : $SmbBasePath" -ForegroundColor Gray
Write-Host " 連番管理対象  : $($SpecialCreators -join ', ')" -ForegroundColor Gray
Write-Host "==========================================" -ForegroundColor Cyan

# 処理結果の集計用リスト
$summaryResults = [System.Collections.Generic.List[PSCustomObject]]::new()

# 配下の親フォルダ（各クリエイターフォルダなど）を取得
$parentFolders = Get-ChildItem -LiteralPath $LocalBasePath -Directory

foreach ($parent in $parentFolders) {
    Write-Host "`n[親フォルダ] $($parent.Name)" -ForegroundColor Yellow
    $parentTransferred = 0
    $parentDeleted = 0

    # サブフォルダ一覧を取得
    $subDirs = Get-ChildItem -LiteralPath $parent.FullName -Directory

    $targetSmbParent = Join-Path -Path $SmbBasePath -ChildPath $parent.Name
    if (-not (Test-Path -LiteralPath $targetSmbParent)) {
        Write-Host "  SMB側に親フォルダを作成します: $targetSmbParent" -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($targetSmbParent, "ディレクトリ作成")) {
            New-Item -ItemType Directory -Path $targetSmbParent -Force | Out-Null
        }
    }

    # =========================================================================
    # 分岐A: 連番フォルダ管理モード ($SpecialCreators に該当する場合)
    # ファイルが存在しないフォルダも対象にし、最新（最後尾）を残して他は削除
    # =========================================================================
    if ($SpecialCreators -contains $parent.Name) {
        Write-Host "  [モード] 連番フォルダ管理（ファイル直下移動）" -ForegroundColor Cyan

        if ($subDirs.Count -le 1) {
            Write-Host "  -> サブフォルダが複数存在しないため（$($subDirs.Count)件）、処理をスキップします。" -ForegroundColor DarkGray
            $summaryResults.Add([PSCustomObject]@{
                Name        = $parent.Name
                Transferred = $parentTransferred
                Deleted     = $parentDeleted
            })
            continue
        }

        # SMB配下の連番フォルダ（半角数字のみ）を取得
        $numberedDirs = Get-ChildItem -LiteralPath $targetSmbParent -Directory | Where-Object { $_.Name -match '^\d+$' }

        $targetNumberedDir = $null
        if ($numberedDirs.Count -gt 0) {
            # 数値としてソートし、最大値を取得
            $targetNumberedDir = $numberedDirs | Sort-Object { [int]$_.Name } | Select-Object -Last 1
        }
        else {
            # 連番フォルダがまだ1つもない場合は "01" を作成
            $initialDirPath = Join-Path -Path $targetSmbParent -ChildPath "01"
            Write-Host "  SMB側に初期連番フォルダを作成: $initialDirPath" -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess($initialDirPath, "連番フォルダ作成")) {
                $targetNumberedDir = New-Item -ItemType Directory -Path $initialDirPath -Force
            }
            else {
                $targetNumberedDir = [System.IO.DirectoryInfo]::new($initialDirPath)
            }
        }

        Write-Host "  現在の最新連番フォルダ: [$($targetNumberedDir.Name)]" -ForegroundColor Magenta

        # 最新連番フォルダ内のファイル数を判定
        $currentFileCount = 0
        if (Test-Path -LiteralPath $targetNumberedDir.FullName) {
            $currentFileCount = (Get-ChildItem -LiteralPath $targetNumberedDir.FullName -File).Count
        }
        Write-Host "  連番フォルダ [$($targetNumberedDir.Name)] 内のファイル数: $currentFileCount 件" -ForegroundColor Gray

        # 100ファイル以上登録されていたら zip 圧縮してフォルダ削除、新規インクリメントフォルダを作成
        if ($currentFileCount -ge 100) {
            Write-Host "  [条件合致] ファイル数が100件以上のため、連番フォルダをアーカイブします。" -ForegroundColor Yellow
            $zipPath = Join-Path -Path $targetSmbParent -ChildPath "$($targetNumberedDir.Name).zip"

            Write-Host "     [圧縮中] $($targetNumberedDir.Name) -> $zipPath" -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess($zipPath, "連番フォルダのzip圧縮")) {
                try {
                    Compress-Archive -LiteralPath $targetNumberedDir.FullName -DestinationPath $zipPath -CompressionLevel Optimal -Force
                    Write-Host "     [圧縮完了]" -ForegroundColor Green

                    Write-Host "     [フォルダ削除] $($targetNumberedDir.FullName)" -ForegroundColor Red
                    Remove-Item -LiteralPath $targetNumberedDir.FullName -Recurse -Force
                    Write-Host "     [フォルダ削除完了]" -ForegroundColor DarkGreen
                }
                catch {
                    Write-Error "連番フォルダのアーカイブに失敗しました: $($_.Exception.Message)"
                    continue
                }
            }

            # 新しい連番の算出 (例: 12 -> 13, 09 -> 10, 1桁なら2桁ゼロ埋め)
            $nextNumber = [int]$targetNumberedDir.Name + 1
            $padLength = [Math]::Max(2, $targetNumberedDir.Name.Length)
            $nextDirName = $nextNumber.ToString().PadLeft($padLength, '0')
            $newNumberedDirPath = Join-Path -Path $targetSmbParent -ChildPath $nextDirName

            Write-Host "  新規連番フォルダを作成: [$nextDirName]" -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess($newNumberedDirPath, "新規連番フォルダ作成")) {
                $targetNumberedDir = New-Item -ItemType Directory -Path $newNumberedDirPath -Force
            }
            else {
                $targetNumberedDir = [System.IO.DirectoryInfo]::new($newNumberedDirPath)
            }
        }

        # 名前順にソートし、最新（最後尾）フォルダを特定（空フォルダ含む全サブフォルダが対象）
        $sortedDirs = $subDirs | Sort-Object -Property Name
        $latestKeepDir = $sortedDirs[-1]
        Write-Host "  -> ローカルに空で保持する最新フォルダ: [$($latestKeepDir.Name)]" -ForegroundColor Magenta

        # ローカルの各サブフォルダからファイルのみを移動（同名ファイルは上書き）
        foreach ($dir in $sortedDirs) {

            $isLatest = ($dir.Name -eq $latestKeepDir.Name)
            $label = if ($isLatest) { "[最新]" } else { "" }
            Write-Host "  >> ファイル移動元サブフォルダ$($label): $($dir.Name)" -ForegroundColor Cyan
            $filesToMove = Get-ChildItem -LiteralPath $dir.FullName -File -Recurse

            foreach ($file in $filesToMove) {
                $destFilePath = Join-Path -Path $targetNumberedDir.FullName -ChildPath $file.Name
                Write-Host "     [移動] $($file.Name) -> $($targetNumberedDir.Name)\" -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($file.FullName, "移動 to $destFilePath (上書き)")) {
                    try {
                        Move-Item -LiteralPath $file.FullName -Destination $destFilePath -Force
                        $parentTransferred++
                    }
                    catch {
                        Write-Error "ファイルの移動に失敗しました: $($file.FullName) - $($_.Exception.Message)"
                    }
                }
                else {
                    $parentTransferred++
                }
            }

            # 移動後にローカルのサブフォルダを削除（最新フォルダは空のまま保持）
            if ($isLatest) {
                Write-Host "     [保持] 最新フォルダのためローカルフォルダは残します（中身は空）。" -ForegroundColor DarkCyan
            }
            else {
                Write-Host "     [削除中] ローカルフォルダを削除: $($dir.FullName)" -ForegroundColor Red
                if ($PSCmdlet.ShouldProcess($dir.FullName, "空サブフォルダの削除")) {
                    try {
                        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
                        Write-Host "     [削除完了]" -ForegroundColor DarkGreen
                        $parentDeleted++
                    }
                    catch {
                        Write-Error "フォルダの削除に失敗しました: $($dir.FullName) - $($_.Exception.Message)"
                    }
                }
                else {
                    $parentDeleted++
                }
            }
        }

        $summaryResults.Add([PSCustomObject]@{
            Name        = $parent.Name
            Transferred = $parentTransferred
            Deleted     = $parentDeleted
        })
        continue
    }

    # =========================================================================
    # 分岐B: 通常モード（複数存在する場合に同期処理）
    # 空フォルダも対象とし、最新（最後尾）フォルダのみ保持、過去フォルダは削除
    # ただし、ファイルを含まない過去フォルダは zip圧縮・転送をスキップして削除のみ行う
    # =========================================================================
    if ($subDirs.Count -le 1) {
        Write-Host "  -> サブフォルダが複数存在しないため（$($subDirs.Count)件）、処理をスキップします。" -ForegroundColor DarkGray
        $summaryResults.Add([PSCustomObject]@{
            Name        = $parent.Name
            Transferred = $parentTransferred
            Deleted     = $parentDeleted
        })
        continue
    }

    # 全サブフォルダを名前順にソート
    $sortedDirs = $subDirs | Sort-Object -Property Name

    # 最後のもの（最新）
    $latestKeepDir = $sortedDirs[-1]
    Write-Host "  -> ローカルに保持する最新フォルダ: [$($latestKeepDir.Name)]" -ForegroundColor Magenta

    foreach ($dir in $sortedDirs) {
        $isLatest = ($dir.Name -eq $latestKeepDir.Name)
        $label = if ($isLatest) { "[最新]" } else { "" }
        Write-Host "  >> 処理対象$($label) : $($dir.Name)" -ForegroundColor Cyan

        # フォルダ内にファイルが存在するかチェック
        $hasFiles = (Get-ChildItem -LiteralPath $dir.FullName -File -Recurse | Select-Object -First 1) -ne $null

        $zipFileName  = Get-SafeZipName $dir.Name
        $smbZipPath   = Join-Path -Path $targetSmbParent -ChildPath $zipFileName
        $localTempZip = Join-Path -Path $parent.FullName -ChildPath $zipFileName

        $compressionSucceeded = $false

        if (-not $hasFiles) {
            # ファイルが存在しない空フォルダの場合：zip圧縮・転送はスキップ
            Write-Host "     [空フォルダ] ファイルが存在しないため、zip圧縮・転送はスキップします。" -ForegroundColor Gray
            $compressionSucceeded = $true  # 削除可能とする
        }
        else {
            # ファイルが存在する場合：zip圧縮・転送処理
            # 1. すでに SMB 側に同名 zip が存在するかチェック
            if (Test-Path -LiteralPath $smbZipPath) {
                Write-Host "     [スキップ] SMB側に同名zipが既に存在します: $zipFileName" -ForegroundColor Yellow
                $compressionSucceeded = $true  # 転送済み扱いにして削除判定へ
            }
            else {
                # 2. 圧縮と転送
                Write-Host "     [圧縮中] $localTempZip を作成中..." -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($localTempZip, "zip圧縮作成")) {
                    try {
                        if (Test-Path -LiteralPath $localTempZip) {
                            Remove-Item -LiteralPath $localTempZip -Force
                        }
                        Compress-Archive -LiteralPath $dir.FullName -DestinationPath $localTempZip -CompressionLevel Optimal
                        Write-Host "     [圧縮完了]" -ForegroundColor Green

                        Write-Host "     [転送中] SMB共有へ移動中 -> $smbZipPath" -ForegroundColor Green
                        Move-Item -LiteralPath $localTempZip -Destination $smbZipPath -Force
                        Write-Host "     [転送完了]" -ForegroundColor Green
                        $compressionSucceeded = $true
                        $parentTransferred++
                    }
                    catch {
                        Write-Error "     [エラー] 圧縮または転送に失敗しました: $($_.Exception.Message)"
                    }
                }
                else {
                    $compressionSucceeded = $true
                    $parentTransferred++
                }
            }
        }

        # 3. ローカル削除：最新フォルダは削除しない、最新以外は転送成功（または空フォルダ）時のみ削除
        if (-not $isLatest) {
            if ($compressionSucceeded) {
                Write-Host "     [削除中] ローカルフォルダを削除: $($dir.FullName)" -ForegroundColor Red
                if ($PSCmdlet.ShouldProcess($dir.FullName, "フォルダごと削除")) {
                    try {
                        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
                        Write-Host "     [削除完了]" -ForegroundColor DarkGreen
                        $parentDeleted++
                    }
                    catch {
                        Write-Error "     [エラー] フォルダの削除に失敗しました: $($_.Exception.Message)"
                    }
                }
                else {
                    $parentDeleted++
                }
            }
            else {
                Write-Host "     [保留] 圧縮失敗のためローカルフォルダを保持します。" -ForegroundColor DarkYellow
            }
        }
        else {
            Write-Host "     [保持] 最新フォルダのためローカルは削除しません。" -ForegroundColor Magenta
        }
    }

    $summaryResults.Add([PSCustomObject]@{
        Name        = $parent.Name
        Transferred = $parentTransferred
        Deleted     = $parentDeleted
    })

}

Write-Host "`nすべての同期処理が完了しました。" -ForegroundColor Cyan

# =========================================================================
# 処理結果の Windows 通知
# =========================================================================
$localFolderName = (Split-Path -Leaf $LocalBasePath)
$notificationTitle = "$localFolderName 同期処理結果"

# 転送または削除が1件以上あったフォルダを抽出
$activeResults = @($summaryResults | Where-Object { $_.Transferred -gt 0 -or $_.Deleted -gt 0 })

if ($activeResults.Count -gt 0) {
    $lines = foreach ($res in $activeResults) {
        "$($res.Name): 転送 $($res.Transferred) / フォルダ削除 $($res.Deleted)"
    }
    $notificationBody = $lines -join "`n"
}
else {
    $notificationBody = "処理無し"
}

Write-Host "`n[通知内容]`n$notificationTitle`n$notificationBody" -ForegroundColor Yellow
Show-Notification -Title $notificationTitle -Message $notificationBody

