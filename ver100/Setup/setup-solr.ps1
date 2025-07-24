# --------------------------------------------------------------------------------
# File		:	setup_solr.ps1
# Purpose	:	Apache solrの起動と停止.
#				Windowsのサービスとして動作させるには別途nssm.exeなどを利用しなければならないが
#				(https://samatsu.github.io/sc91-quick-setup-guide/prerequisites/solr.html)
#				本研究ではサービス登録せず, consoleからのsolrの開始だけのコマンドとする
#
# Usage		:	pwsh.exe setup_solr.ps1
# History	:
#				2025-06-25(Wed) created
#				2025-06-25(Wed) reset PATH env
#						see https://issues.apache.org/jira/browse/SOLR-7283


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
	Write-Host  "  以下のコマンドは 管理者権限で実行する必要があります"
	Write-Host ("  $scriptName  status    " + "   " + "solrの状態を確認する"	)
	Write-Host ("  $scriptName  start     " + "   " + "solrを開始する"	)
	Write-Host ("  $scriptName  stop      " + "   " + "solrを停止する"	)
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

$exe_path  = "d:\WebApps\Framework\solr\bin\solr.cmd"

switch($command) {
	"status"
		{
			$solrUrl = "http://localhost:8983/solr/"
			Write-Host "Checking solr status..." 
			try {
			    $response = Invoke-WebRequest -Uri $solrUrl -UseBasicParsing -TimeoutSec 3
			    if ($response.StatusCode -eq 200) {
			        Write-Host "Solr is running at $solrUrl"
			        exit 0
			    } else {
			        Write-Host "Solr responded, but status code is $($response.StatusCode)"
			        exit 1
			    }
			}
			catch {
			    Write-Host "Solr is not responding at $solrUrl"
			    exit 2
			}
			break
		}
	"start"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			Write-Host "starting solr..."
			# ----------------------------------------
			# 2025-06-25(Wed)
			# solr/bin/solr.cmdを起動するときに PATHに gnu/gitの find.exeが先にあると
			# まともに動かないバグの対応。 solr.cmdの中で C:\Windows\system32\find.exeを
			# "find"として使っている。ひどい。
			# https://issues.apache.org/jira/browse/SOLR-7283
			# https://stackoverflow.com/questions/58592572/unable-to-restart-stop-or-start-solr-server
			# なのでsolr.cmdを呼び出す前に呼び出すプロセスのPATHを変更する					   
			# 

			$env:PATH = 'C:\Windows;C:\Windows\System32'
			$env:SOLR_HOME       = 'd:\WebApps\Instance\solr'
			$env:SOLR_SERVER_DIR = 'd:\WebApps\Instance\solr\server'

			# ----------------------------------------
			# 2025-06-25(Wed)
			# verbose modeで立ち上げ。optionをCheckするため
			# version 8.11.4の場合以下のmessageが表示され立ち上がる
			# -----------------------------------------------------------------
			# OpenJDK 64-Bit Server VM warning: JVM cannot use large page memory because
			# it does not have enough privilege to lock pages in memory.
			# Waiting up to 30 to see Solr running on port 8983
			# Started Solr server on port 8983. Happy searching!
			# Started solr.exe successfully.
			#-------------------------------------------------------------------

			& $exe_path start

			if( $LASTEXITCODE -eq 0) {
				Write-Host "Started solr.exe successfully."
			}
			else {
				Write-Host "Failed to start solr error code is $LASTEXITCODE"
			}
			break
		}
	"stop"
		{
			if( -not (HasAdminRights)) {
				Write-Host "このコマンドを実行するには管理者権限が必要になります。"
				exit 1
			}
			Write-Host "stopping solr..."
			
			$env:PATH = 'C:\Windows;C:\Windows\System32'

			# 
			# solr.cmd stop  だけだと止まらない。 portを指定しろと言われる。
			# solr.cmd stop
			# Using Solr root directory: d:\WebApps\Framework\solr
			# Using Java: c:\opt\JDK\bin\java
			# openjdk version "17.0.15" 2025-04-15 LTS
			# OpenJDK Runtime Environment Microsoft-11369865 (build 17.0.15+6-LTS)
			# OpenJDK 64-Bit Server VM Microsoft-11369865 (build 17.0.15+6-LTS, mixed mode, sharing)
			# ERROR: Must specify the port when trying to stop Solr,
			# or use -all to stop all running nodes on this host.
			# なので -allを追加する	
			#
			& $exe_path stop -all -V
			if( $LASTEXITCODE -eq 0) {
				Write-Host "solr successfully."
			}
			else {
				Write-Host "Failed to start solr error code is $LASTEXITCODE"
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
