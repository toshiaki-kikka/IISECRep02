# OSSを利用したシステムのインストーラーのサンプル
OSSを利用したシステムのデプロイメントの行うサンプルです。
Powershellで記述したスクリプトで、OSSを利用したシステムのセットアップ、アンインストール、メンテナンス、サービス登録、動作開始などを容易行えるか？OSSが更新された際どのようにシステムを更新するか？を検証するためのサンプルプログラムです。

サンプルシステム
サンプルのシステムはWindowsのローカルPCで動作するWebアプリをシミュレートしています。以下のOSSを利用しています。
- Apache Web Server(httpd)
- Apache tomcat
- Apache Solr

運用中のシステムが利用しているOSSに脆弱性が発覚した際、速やかに更新版をデプロイするためのシミュレーション、そのためのインストールプログラムです。

### シナリオ
- システム開発終了後、運用環境にシステムをインストール、運用開始
- システムが利用しているOSSに脆弱性が発覚。すぐに修正版が提供される。
- 修正版を取り込んだインストーラーを作成する
- インストーラーを運用環境に配信
- 利用システムを速やかに停止
- インストーラーを利用し修正版をインストール。動作確認
- 問題がなければ前バージョンを削除
- 問題がありば前バージョンにロールバック


動作検証済み環境
本プログラム、スクリプトはプログラムは以下の環境で動作することを確認しています。
- Windows 11 Pro Version 24H2. Build 26100.4652 x64
- PowerShell ver5.1 (powershell.exe)
- PowerShell ver7.5 (pwsh.exe)


ファイル、フォルダー構成
git cloneをすると以下のようなフォルダー構成でファイルとフォルダーが作成されます。これがセットアップパッケージと考えてください。以下は X:\PKG配下に ver100以降のファイルをダウンロードした場合の例です。

 ```
X:\PKG\
└─ver100
    ├─Instance
    │  ├─httpd
    │  ├─solr
    │  ├─tomcat
    │  └─MyApps
    │  
    ├─Modules
    │  ├─dummy.txt
    │  └─MyApps
    │  
    ├─Setup
    │  ├─setup-all.ps1	
    │  ├─setup-apps.ps1	
    │  ├─setup-httpd.ps1
    │  ├─setup-solr.ps1	
    │  └─setup-tomcat.ps1
    │  
    └─Setup.ps1
```
#### OSSモジュールのダウンロードと配置方法
本リポジトリにはサンプルシステムで利用するOSSをチェックインしていませんので別途ダウンロード、解凍する必要があります。
Modulesフォルダーに、apache Web Service, apache tomcat, apache solrを配置します。ダウンロードURLは以下になります。
- apache httpd
  - https://www.apachelounge.com/download/
    - https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.64-250710-win64-VS17.zip
- apache tomcat
  - https://tomcat.apache.org/
    - https://archive.apache.org/dist/tomcat/tomcat-11/

- apache solr
    - https://solr.apache.org/downloads.html
      - https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.4/solr-8.11.4.zip

powershellを起動して x:\PKG\ver100\Modulesに移動します。
```
PS x:\pkg\ver100\Modules
```

```
PS x:\pkg\ver100\Modules>　
Invoke-WebRequest -Uri https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.64-250710-win64-VS17.zip -OutFile httpd2.4.64.zip
PS x:\pkg\ver100\Modules> Expand-Archive -Path .\httpd2.4.64.zip -DestinationPath .\httpd-2.4.63
```

```powershell
PS x:\pkg\ver100\Modules>　
Invoke-WebRequest -Uri https://archive.apache.org/dist/tomcat/tomcat-11/v11.0.5/bin/apache-tomcat-11.0.5-windows-x64.zip -OutFile tomcat11.0.5.zip
PS x:\pkg\ver100\Modules> Expand-Archive -Path .\tomcat11.0.5.zip -DestinationPath .\  
PS x:\pkg\ver100\Modules>
```
```powershell
PS x:\pkg\ver100\Modules> Invoke-WebRequest -Uri 
https://dlcdn.apache.org/lucene/solr/8.11.4/solr-8.11.4.zip -OutFile solr8.11.4.zip
PS x:\pkg\ver100\Modules> Expand-Archive -Path .\sor8.11.4.zip -DestinationPath .\
```
JDKをインストールする場合は、JDK17を準備します。

```powershell
PS X:\pkg\ver100\Modules> Invoke-WebRequest -Uri https://aka.ms/download-jdk/microsoft-jdk-17.0.16-windows-x64.zip -OutFile jdk.zip
PS X:\pkg\ver100\Modules> Expand-Archive -Path .\jdk.zip -DestinationPath .\

PS x:\pkg\ver100\Modules> del *.zip
PS x:\pkg\ver100\Modules> dir
    ディレクトリ: X:\pkg\ver100\Modules
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        2025/07/24     17:49                apache-tomcat-11.0.5
d-----        2025/07/25     13:26                httpd-2.4.63
d-----        2025/07/25     14:06                jdk-17.0.16+8
d-----        2025/07/25     13:34                solr-8.11.4
```

```
X:\PKG\
└─ver100
    ├─Instance
    │  ├─httpd
    │  ├─solr
    │  ├─tomcat
    │  └─MyApps
    │  
    ├─Modules
    │  ├─apache-tomcat-11.0.5
    │  ├─dummy.txt
    │  ├─httpd-2.4.63
    │  ├─jdk-17.0.16+8
    │  ├─MyApps
    │  └─solr-8.11.4
    │  
    ├─Setup
    │  ├─setup-all.ps1	
    │  ├─setup-apps.ps1	
    │  ├─setup-httpd.ps1
    │  ├─setup-solr.ps1	
    │  └─setup-tomcat.ps1
    │  
    └─Setup.ps1
```

x:\pkg\ver100\Setup.ps1を編集します。Modulesフォルダー下のFolder名を22行目以降のデータ定義の'folder'の値をModulesフォルダー下のサブフォルダーの名前に書き換えます。
(httpdだけは'subfolder'として "Apache24"を記述します。これは httpd-2.4.64フォルダーの配下にApache24というフォルダーが固定で作成されるためです。)

```powershell
#--------------------------------------------------------------------------------
# DATA DEFINITION start start start
# 
$InstJava  = [PSCustomObject]@{fSetup=$false;  mod="jdk";    folder="jdk-17.0.16+8";		subFolder=$null;		symDst=$JDKRoot}

$InstHttpd = [PSCustomObject]@{fSetup=$true;   mod="httpd";  folder="httpd-2.4.63";         subFolder="Apache24";   symDst=$null   }
$InstTomcat= [PSCustomObject]@{fSetup=$true;   mod="tomcat"; folder="apache-tomcat-11.0.5"; subFolder=$null;        symDst=$null   }
$InstSolr  = [PSCustomObject]@{fSetup=$true;   mod="solr";   folder="solr-8.11.4";          subFolder=$null;        symDst=$null   }
$InstApp   = [PSCustomObject]@{fSetup=$true;   mod="MyApps"; folder="MyApps";               subFolder=$null;        symDst=$null   }
```
### システムの初回インストール
システムを運用環境に初めてインストールするとします。インストール場所は固定で D:\WebApps以下とします。
X:\　はインストーラーが入っているUSBドライブとみなして X:\PKG\ver100から 運用環境 D:\WebAppsにシステムをインストールします。
powershellでx:\pkg\ver100に移動し、JDKのインストール、初期データのインストール、モジュールのセットアップを行います。

```powershell
PS X:\pkg\ver100> .\Setup.ps1 initdata
システムのデータを初期化します。
D:\WebApps\Frameworkを作成します。
D:\WebApps\Modulesを作成します。
D:\WebApps\Setupを作成します。
D:\WebApps\Instanceを作成します。
PS X:\pkg\ver100\Instance\* -> D:\WebApps\Instance にコピーします
PS X:\pkg\ver100> 
```
JDKがインストールされていない場合はJDKをインストールします。

```powershell
PS X:\pkg\ver100> .\Setup.ps1 instjdk
JDKをインストールします。
    X:\pkg\ver100\Modules\jdk-17.0.16+8 を
    D:\WebApps\Modules\ver100\jdk-17.0.16+8 へコピーします。
  コピーが終了しました。
C:\opt\JDK <<===>> D:\WebApps\Modules\ver100\jdk-17.0.16+8 のシンボリック リンクが作成されました
環境変数 %JAVA_HOME% に C:\opt\JDKを設定します

```
その後 .\Setup.ps1 setupを実行してモジュールをインストールします。
```powershell
PS X:\pkg\ver100> .\Setup.ps1 setup
システムのセットアップを始めます。
    X:\pkg\ver100\Modules\httpd-2.4.63 を
    D:\WebApps\Modules\ver100\httpd-2.4.63 へコピーします。
D:\WebApps\Framework\httpd <<===>> D:\WebApps\Modules\ver100\httpd-2.4.63\Apache24 のシンボリック リンクが作成されました
    :(以下省略)
    :
   X:\pkg\ver100\Setup を D:\WebApps\Setup\ver100 にコピーします。
   X:\pkg\ver100\Setup.ps1 を D:\WebApps\Setup\Setup_ver100.ps1 にコピーします。
   D:\WebApps\Setup\current と D:\WebApps\Setup\ver100 にシンボリックリンクを貼ります。
D:\WebApps\Setup\current <<===>> D:\WebApps\Setup\ver100 のシンボリック リンクが作成されました
```
これでシステムのインストールは終了です。

### システムの動作シミュレーション
Powershellで、D:\WebApps\Setup\currentに移動します。setup-all.ps1を引数無しで実行するとusageが表示されます。
```powershell
PS D:\WebApps\Setup\current> .\setup-all.ps1
システムが利用する，サービス登録、サービス登録解除、サービスのスタート、停止

Usage:
   setup-all.ps1 command

Examples:
  setup-all.ps1  status      httpdがサービス登録されているか？動作しているかのを状態を返す

  以下のコマンドは 管理者権限で実行する必要があります
  setup-all.ps1  register     システム利用のサービス登録する
  setup-all.ps1  start        システム利用のサービスを開始する
  setup-all.ps1  stop         システム利用のサービスを停止する
  setup-all.ps1  unregister   システム利用のサービス登録を解除する
PS D:\WebApps\Setup\current>
```
サービス等の登録を行います。

```powershell
PS D:\WebApps\Setup\current> .\setup-all.ps1 register
Installing the 'ApacheHttpdService' service
The 'ApacheHttpdService' service is successfully installed.
Testing httpd.conf....
Errors reported here must be corrected before the service can be started.
Installing the service 'Tomcat11' ...
Using CATALINA_HOME:    "d:\WebApps\Framework\tomcat"
Using CATALINA_BASE:    "d:\WebApps\Instance\tomcat"
Using JRE_HOME:         "c:\opt\JDK"
Using JVM:              "c:\opt\JDK\bin\server\jvm.dll"
The service 'Tomcat11' has been installed.
PS D:\WebApps\Setup\current>
```
システムを開始します。
```
PS D:\WebApps\Setup\current> .\setup-all.ps1 start
starting httpd...
Started httpd.exe successfully.
starting tomcat
Apache Tomcat 11.0 Tomcat11 サービスを開始します.
Apache Tomcat 11.0 Tomcat11 サービスは正常に開始されました。
Started tomcat successfully.
starting solr...
OpenJDK 64-Bit Server VM warning: JVM cannot use large page memory because it does not have enough privilege to lock pages in memory.
PS D:\WebApps\Setup\current>
```
- apache httpd:  http://localhost
- apache tomcat: http://localhost:8080/
- apache solr:   http://localhost:8983/

にブラウザでアクセスできれば正常に動作しています。


### システムのUpdateのシミュレーション
x:\PKG\ver100 はシステムバージョン ver1.0.0のインストーラーとします。利用しているtomcat11.0.5に脆弱性が発覚したとして、tomcat11.0.6にUpdateが必要になったと仮定し、新しいtomcat11.0.6を含めたインストーラーを作成します。このシステムのバージョンを2.0.0(ver200)とします。
ver200のインストーラーの作成
ver100-> ver200へフォルダーごとコピーします。
```powershell
PS X:\pkg>
PS X:\pkg> xcopy ver100 ver200 /E /I /Y
   :(省略) 
xxx個のファイルをコピーしました。
PS X:\pkg>
```
ver200\Modules\の apache-tomcat-11.0.5を削除し、[OSSモジュールのダウンロードと配置方法]で記述した方法と同様にapache-tomcat-11.0.6をダウンロードします。

```powershell
PS x:\pkg>cd .\ver200\Modules
PS x:\pkg\ver200\Modules>　
PS x:\pkg\ver200\Modules>　rmdir apache-tomcat-11.0.6
PS x:\pkg\ver200\Modules>　
Invoke-WebRequest -Uri https://archive.apache.org/dist/tomcat/tomcat-11/v11.0.6/bin/apache-tomcat-11.0.6-windows-x64.zip -OutFile tomcat11.0.6.zip
PS x:\pkg\ver200\Modules> Expand-Archive -Path .\tomcat11.0.6.zip -DestinationPath .\  
PS x:\pkg\ver100\Modules>del *.zip
PS x:\pkg\ver100\Modules> dir
    ディレクトリ: X:\pkg\ver100\Modules
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        2025/07/25     17:27                apache-tomcat-11.0.6
d-----        2025/07/25     13:26                httpd-2.4.63
d-----        2025/07/25     14:06                jdk-17.0.16+8
d-----        2025/07/25     13:34                solr-8.11.4
```
Setup.ps1を書き換えます。 tomcatの'folder'部分を
"apache-tomcat-11.0.**5**"　から　"apache-tomcat-11.0.**6**" に変更し保存します。
```powershell
#--------------------------------------------------------------------------------
# DATA DEFINITION start start start
# 
   : (省略)
$InstTomcat= [PSCustomObject]@{fSetup=$true;   mod="tomcat"; folder="apache-tomcat-11.0.6"; subFolder=$null;        symDst=$null   }
   : (省略)
```
これでver200のインストーラーの作成は終了です。

### システムのUpdate
現在動作している運用環境で新しいシステムのインストーラーver2.0.0が X:\pkg\ver200として利用可能であるとします。まず最初に動作しているver100のシステムを停止します。
#### システムの停止
システムを止めるには以下のコマンドを実行します。
```powershell
PS D:\WebApps\Setup\current> .\setup-all.ps stop
The 'ApacheHttpdService' service has stopped.
Stopped httpd.exe successfully.
stopping httpd...
Apache Tomcat 11.0 Tomcat11 サービスを停止中です.
Apache Tomcat 11.0 Tomcat11 サービスは正常に停止されました。

Stopped httpd.exe successfully.
stopping solr...
Using Solr root directory: D:\WebApps\Framework\solr
Using Java: c:\opt\JDK\bin\java
openjdk version "17.0.16" 2025-07-15 LTS
OpenJDK Runtime Environment Microsoft-11926163 (build 17.0.16+8-LTS)
OpenJDK 64-Bit Server VM Microsoft-11926163 (build 17.0.16+8-LTS, mixed mode, sharing)

Stopping Solr process 29564 running on port 8983
solr successfully.
アプリを終了します
PS D:\WebApps\Setup\current>
```
```
PS D:\WebApps\Setup\current> .\setup-all.ps1 unregister
Removing the 'ApacheHttpdService' service
The 'ApacheHttpdService' service has been removed successfully.
Removing the service 'Tomcat11' ...
Using CATALINA_BASE:    "d:\WebApps\Instance\tomcat"
The service 'Tomcat11' has been removed
指定されたファイルが見つかりません。
指定されたファイルが見つかりません。
PS D:\WebApps\Setup\current>
```
#### ver2.0.0のインストール
x:\pkg\**ver200**\Setup.ps1を利用してインストールします。
```
PS X:\pkg\ver200> .\Setup.ps1 setup
```
これでシステムの更新は終了です。JDKはUpdateしていません。また運用中に D:\WebApps\Instance以下のデータが書き換わっているのでデータはそのまま利用します。
その後 d:\WebApps\Setup\currentへ移動し [システムの動作シミュレーション]で記述したコマンドを実行することにより新しいtomcatを利用したシステムが動作します。
