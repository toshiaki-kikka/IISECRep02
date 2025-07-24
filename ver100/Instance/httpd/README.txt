2025-06-24(Tue)
 ./logsフォルダーは事前に作成されていないと service起動で失敗する。
 =>嘘だった。サービスの登録はされていた。ただし以下のエラーを吐くが、
	PS D:\WebApps\Setup> .\setup_httpd.ps1 register
	Installing the 'ApacheHttpdService' service
	The 'ApacheHttpdService' service is successfully installed.

	Testing httpd.conf....
	Errors reported here must be corrected before the service can be started.
	(OS 2)指定されたファイルが見つかりません。  : AH02291: Cannot access directory 'D:/WebApps/Instance/httpd/logs/' for main error log
	AH00014: Configuration check failed 
