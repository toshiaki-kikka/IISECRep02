# --------------------------------------------------------------------------------
# File		:	setup-all.ps1
# Purpose	:	利用OSSのサービス登録，解除，開始，停止
# Usage		:	powershell.exe/pwsh.exe setup-_httpd.ps1

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

	Write-Host "システムが利用する，サービス登録、サービス登録解除、サービスのスタート、停止"
	Write-Host ""
	Write-Host "Usage: "
	Write-Host "   $scriptName command"     
	Write-Host ""
	Write-Host "Examples: "
	Write-Host ("  $scriptName  status    " + "  httpdがサービス登録されているか？動作しているかのを状態を返す" )
	Write-Host ""
	Write-Host  "  以下のコマンドは 管理者権限で実行する必要があります"
	Write-Host ("  $scriptName  register  " + "   " + "システム利用のサービス登録する"		)
	Write-Host ("  $scriptName  start     " + "   " + "システム利用のサービスを開始する"	)
	Write-Host ("  $scriptName  stop      " + "   " + "システム利用のサービスを停止する"	)
	Write-Host ("  $scriptName  unregister" + "   " + "システム利用のサービス登録を解除する"	)
}

# --------------------------------------------------------------------------------
# Function:	管理者権限チェック
# Purpose:	Integrity level Highで動作しているかどうかのcheck

function HasAdminRights {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

}

#
# main start.

if ([string]::IsNullOrEmpty($command)) {
   ShowUsage
   exit 1
}

$httpd_path  = "d:\WebApps\Framework\Apache\bin\httpd.exe"
$svc_name    = "ApacheHttpdService"
$conf_path   = "d:/WebApps/Instance/httpd/modified_httpd.conf"

switch($command) {
	"status"
		{
			try {
				& .\setup-httpd.ps1 status
				& .\setup-tomcat.ps1 status
				& .\setup-solr.ps1 status
			}
			catch {
			}
			break
		}
	"register"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			& .\setup-httpd.ps1 register
			& .\setup-tomcat.ps1  register
			   break
		}
	"unregister"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			& .\setup-httpd.ps1 unregister
			& .\setup-tomcat.ps1 unregister
			   break
		}
	"start"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			& .\setup-httpd.ps1 start
			& .\setup-tomcat.ps1 start
			& .\setup-solr.ps1 start
			& .\setup-apps.ps1 start
			break
		}
	"stop"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			& .\setup-httpd.ps1 stop
			& .\setup-tomcat.ps1 stop
			& .\setup-solr.ps1 stop
			& .\setup-apps.ps1 stop
			break
		}
	default
		{
			Write-Host "Unknown command $command"
			ShowUsage
			break;
		}
}
