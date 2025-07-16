# --------------------------------------------------------------------------------
# File		:	setup_httpd.ps1
# Purpose	:	Apache httpdのservice install, uninstall, start, stop script
# Usage		:	pwsh.exe setup_httpd.ps1

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
	Write-Host ("  $scriptName  status    " + "  httpdがサービス登録されているか？動作しているかのを状態を返す" )
	Write-Host ""
	Write-Host  "  以下のコマンドは 管理者権限で実行する必要があります"
	Write-Host ("  $scriptName  register  " + "   " + "httpdをサービス登録する"		)
	Write-Host ("  $scriptName  start     " + "   " + "httpdのサービスを開始する"	)
	Write-Host ("  $scriptName  stop      " + "   " + "httpdのサービスを停止する"	)
	Write-Host ("  $scriptName  unregister" + "   " + "httpdのサービス登録を解除する"	)
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
				$service = Get-Service -Name $svc_name -ErrorAction Stop
				Write-Host "サービス [$svc_name] は登録されています。"
				Write-Host "状態: $($service.Status)"  # Running / Stopped / StartPending / StopPending など
			}
			catch {
				Write-Host "サービス [$svc_name] は登録されていません。"
			}
			break
		}
	"register"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			& $httpd_path -k install -n $svc_name -f $conf_path;
			   break
		}
	"unregister"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			& $httpd_path -k uninstall -n $svc_name
			   break
		}
	"start"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			Write-Host "starting httpd..."
			& $httpd_path -k start -n $svc_name
			if( $LASTEXITCODE -eq 0) {
				Write-Host "Started httpd.exe successfully."
			}
			else {
				Write-Host "Failed to start httpd.exe error code is $LASTEXITCODE"
			}
			break
		}
	"stop"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			Write-Host "stopping httpd..."
			& $httpd_path -k stop -n $svc_name
			if( $LASTEXITCODE -eq 0) {
				Write-Host "Stopped httpd.exe successfully."
			}
			else {
				Write-Host "Failed to start httpd.exe error code is $LASTEXITCODE"
			}
			break
		}
	default
		{
			Write-Host "Unknown command $command"
			ShowUsage
			break;
		}
}
