# --------------------------------------------------------------------------------
# File		:	setup_apps_dummy.ps1
# Purpose	:	OSSを利用するアプリケーションのsetup. ただしここでは dummy. 何もしない。
# Usage		:	pwsh.exe setup_apps_dummy.ps1

# --------------------------------------------------------------------------------
# moduleの parameter は commandのみ
#
param (
	[string]$command
)

# --------------------------------------------------------------
# Function: ShowUsage
# Purpose:	引数の詳細を表示する
# 
function ShowUsage {
	# 自分自身のscript file名を取得する
	$scriptName = Split-Path -Leaf $PSCommandPath

	Write-Host "applicationのスタート、停止を行う"
	Write-Host ""
	Write-Host "Usage: "
	Write-Host "   $scriptName command"     
	Write-Host ""
	Write-Host "Examples: "
	Write-Host  "  以下のコマンドは 管理者権限で実行する必要があります"
	Write-Host ("  $scriptName  start     " + "   " + "アプリを開始する"	)
	Write-Host ("  $scriptName  stop      " + "   " + "アプリを停止する"	)
}

#
# main start.

if ([string]::IsNullOrEmpty($command)) {
   ShowUsage
   exit 1
}

switch($command) {
	"start"
		{
			Write-Host "アプリを開始します"
			break
		}
	"stop"
		{
			Write-Host "アプリを終了します"
			break
		}
	default
		{
			Write-Host "Unknown command $command "
			ShowUsage
			break;
		}
}
