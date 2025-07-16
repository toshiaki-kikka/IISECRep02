# --------------------------------------------------------------------------------
# File		:	setup-tomcat.ps1
# Purpose	:	Apache httpdのservice install, uninstall, start, stop script
# Usage		:	powershell.exe/pwsh.exe setup_httpd.ps1

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

	Write-Host "httpdのサービス登録、サービス登録解除、サービスのスタート、停止"
	Write-Host ""
	Write-Host "Usage: "
	Write-Host "   $scriptName command"     
	Write-Host ""
	Write-Host "Examples: "
	Write-Host ("  $scriptName  register  " + "  tomcatをサービス登録する"		)
	Write-Host ("  $scriptName  start     " + "  tomcatのサービスを開始する"		)
	Write-Host ("  $scriptName  stop      " + "  tomcatのサービスを停止する"		)
	Write-Host ("  $scriptName  unregister" + "  tomcatのサービス登録を解除する"	)
}

# --------------------------------------------------------------------------------
# Function:	管理者権限チェック
# Purpose:	Integrity level Highで動作しているかどうかのcheck

function HasAdminRights {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

}

#
# main start.

if( -not (HasAdminRights)) {
	Write-Host "このコマンドを実行するには管理者権限が必要です"
}

if ([string]::IsNullOrEmpty($command)) {
   ShowUsage
   exit 1
}

$tomcat_home = "d:\WebApps\Framework\tomcat"
$tomcat_base = "d:\WebApps\Instance\tomcat"
$tomcat_service_bat  = "d:\WebApps\Framework\tomcat\bin\service.bat"
$tomcat_service_name = "Tomcat11"

switch($command) {
	"register"
		{
			if( -not (HasAdminRights)) {
				Write-Host "管理者必要"
				exit 1
			}
			# CATALINA_HOME, CATALINA_BASEをここで登録しておく。service.batが参照しているから
			[System.Environment]::SetEnvironmentVariable('CATALINA_HOME', $tomcat_home, 'Machine')
			[System.Environment]::SetEnvironmentVariable('CATALINA_BASE', $tomcat_base, 'Machine')

			# 上の環境設定だけではだめ。tomcatの server.batを動かす時のshellが上記の環境変数を持っていないとだめ。
			# つまりこの .ps1が動いている pwsh.exeの環境変数を設定する必要があった(だったら上のコードはいらないのか？
			$env:CATALINA_HOME = $tomcat_home
			$env:CATALINA_BASE = $tomcat_base
			& $tomcat_service_bat install
			   break
		}
	"unregister"
		{
			if( -not (HasAdminRights)) {
				Write-Host "管理者必要"
				exit 1
			}
			& $tomcat_service_bat remove
			#システムの環境変数を削除
			#[System.Environment]::SetEnvironmentVariable('CATALINA_HOME', $null, 'Machine')
			#[System.Environment]::SetEnvironmentVariable('CATALINA_BASE', $null, 'Machine')
			break
		}
	"start"
		{
			Write-Host "starting tomcat"
			& net.exe start $tomcat_service_name
			if( $LASTEXITCODE -eq 0) {
				Write-Host "Started tomcat successfully."
			}
			else {
				Write-Host "Failed to start httpd.exe error code is $LASTEXITCODE"
			}
			break
		}
	"stop"
		{
			Write-Host "stopping httpd..."
			& net.exe stop $tomcat_service_name
			if( $LASTEXITCODE -eq 0) {
				Write-Host "Stopped httpd.exe successfully."
			}
			else {
				Write-Host "Failed to start httpd.exe error code is $LASTEXITCODE"
			}
			break
		}
	default  {  Write-Host "知らない parameter $func です"; break }
}
