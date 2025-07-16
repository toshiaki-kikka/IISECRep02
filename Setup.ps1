# ------------------------------------------------------------
# File     :	Setup.ps1
# Purpose  :	既存システムDeploymentのサンプル
#				導入企業にCD/USBでインストールするモジュールを持ってきて
#				それをインストールすることが目的.
#				そのCD/USBが WindowsのX:ドライブに割り当てられたと仮定して
#				そこにあるモジュールを実PCにコピーする。
#				実際に動作、起動させるのは別のscript

# ------------------------------------------------------------
# script parameter: command
# --------------------------------------------------------------------------------
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

	Write-Host "Module Setup script."
	Write-Host ""
	Write-Host "Usage: "
	Write-Host "   $scriptName command"     
	Write-Host ""
	Write-Host "Examples: "
	Write-Host ""
	Write-Host  "  以下のコマンドは 管理者権限で実行する必要があります"
	Write-Host ("  $scriptName  help      " + "   " + "usageを表示"		)
	Write-Host ("  $scriptName  setup     " + "   " + "moduleをpkg->PCへcopy, symlinkを貼る"	)
	Write-Host ("  $scriptName  copyonly  " + "   " + "moduleをpkg->PCへcopyのみ"	)
	Write-Host ("  $scriptName  setsymlink" + "   " + "installされているmoduleのsymlinkのみ行う"	)
	Write-Host ("  $scriptName  delsymlink" + "   " + "installされているmoduleのsymlinkのみ削除を行う"	)
	Write-Host ("  $scriptName  delall    " + "   " + "installされているmoduleとsymlinkの削除を行う"	)
}



# ------------------------------------------------------------
# Function: IsSameFolder
# ------------------------------------------------------------
function IsSameFolder {
	param (
        [string]$path1,
        [string]$path2
    )
	# 絶対パスに変換してから比較（大文字小文字や末尾\なども吸収）
	$full1 = [System.IO.Path]::GetFullPath($path1)
	$full2 = [System.IO.Path]::GetFullPath($path2)

	if ($full1.ToLower() -eq $full2.ToLower()) {
	    # Write-Host "パスは同一です。"
		return $true
	} else {
	    # Write-Host "パスは異なります。"
		return $false
	}	
}

# ------------------------------------------------------------
# Function: 管理者権限チェック
# ------------------------------------------------------------
function HasAdminRights {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

}

# ------------------------------------------------------------
# Function: フォルダの中身を別のFolderにコピー. コピー先のFolderは新規作成
# ex)
#	X:\Folder\ver12345\Setup\aaaa.ps1
#	                         bbb.ps1
# を 
#  E:\WebApps\Setup\ver12345\aaaa.ps1
#	                         bbb.ps1 
# のようにコピーする。 E:\WebApps\Setup\ver12345 フォルダーは基本無いとことが多い。
# sourceRootには "X:\Folder\ver12345\Setup"
# destRootには   "E:\WebApps\Setup\ver12345"
# を指定する。apiがありそうで無い。
# ------------------------------------------------------------
function CreateFolder_n_Copy {
	param (
		[string]$sourceRoot,
		[string]$destRoot
	)

	Get-ChildItem -Path $sourceRoot -Recurse -Filter *.* | ForEach-Object {
	    $relativePath = $_.FullName.Substring($sourceRoot.Length).TrimStart('\')
		Write-Host "relativePath = $relativePath"

	    $destPath = Join-Path $destRoot $relativePath
		Write-Host "destPath = $destPath"
	    # フォルダーがなければ作成
	    $destDir = Split-Path $destPath
	    if (-not (Test-Path $destDir)) {
	        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
	    }
	    Copy-Item -Path $_.FullName -Destination $destPath -Force
	}
}

# --------------------------------------------------------------------------------		
# Function: ReSymLink
# 
# --------------------------------------------------------------------------------		
function ReSymLink {
	param (
		[string]$symSrc,
		[string]$symDst
	)

	if (Test-Path -LiteralPath $symDst) {
	    $item = Get-Item -LiteralPath $symDst
	    if ( $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint ) {
			# folderが Symbolic Link だった時
	        Write-Host "    SymLink $symDst は既に存在します。"
	
	        # Write-Host "    Real path is $item.Target"
			# 上記コードは
			# Real Path is D:\WebApps\Framework\Apache.Target
			# と出力する。 $item がD:\WebApps\Framework\Apacheなので。 ひどい。 なので 別の変数に入れる
			$realTarget = $item.Target
	        Write-Host "    実際のPath is $realTarget"
			if( IsSameFolder -path1 $realTarget -path2 $symSrc) {
				# symbolic linkは既に設定されている。
				Write-Host "    Warning: SymLink先は既に $symSrc に設定されていますので何もしません。"
			}
			else {
				#	既存の シンボリックリンクを削除
				Write-Host "    SymLinkを一度削除します。ターゲットは $symDst です"
				Remove-Item -LiteralPath $symDst
				# 新しい symboliclinkを作成
				cmd /c mklink /D "$symDst" "$symSrc"
			}
		}
		else {	
	       Write-Error "  Folder $symDst already Exists but NOT Symbolick Link. Error"
		   return
		}
	}
	else {
		# 新しい symboliclinkを作成
		cmd /c mklink /D "$symDst" "$symSrc"
	}
}

# ------------------------------------------------------------
# Function: DelSymLink
#
function DelSymLink {
	param (
		[string]$symLink
	)
	if (Test-Path -LiteralPath $symLink) {
	    $item = Get-Item -LiteralPath $symLink
	    if ( $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint ) {
			# folderが Symbolic Link だった時
			Write-Host "    deleting symbolic link: $symLink"
			Remove-Item -LiteralPath $symLink
		}
		else {	
	       Write-Error "  Folder $symLinkは Symbolick Linkではありません. Error"
		   return
		}
	}
	else {
		Write-Host "$symLink を消そうとしましたが存在しません"
	}
}

#管理者権限で無ければエラーで終了
if( -not (HasAdminRights) ) {
	Write-Host "このスクリプトは管理者権限で実行する必要があります。"
	Write-Host "pwsh.exeを管理者で実行後、このスクリプトを実行してください。"
	exit 1
}

$f_help		 =$false
$f_debug	 =$false	
$f_setup	 =$false
$f_copyonly	 =$false
$f_setsymlink=$false
$f_delsymlink=$false
$f_delall    =$false

switch($command) {
	"help"			{ $f_help		= $true; break}
	"debug"			{ $f_debug		= $true; break}
	"setup"			{ $f_setup		= $true; break}
	"copyonly"		{ $f_copyonly	= $true; break}
	"setsymlink"	{ $f_setsymlink	= $true; break}
	"delsymlink"    { $f_delsymlink	= $true; break}
	"delall"		{ $f_delall		= $true; break}
	default			{ $f_help		= $true; break}
}

if( $f_help ) {
	ShowUsage
	exit 1
}


# スクリプト自身のフルパス
$myScriptPath = $MyInvocation.MyCommand.Path
$verFolderName= Split-Path -Leaf (Split-Path -Parent $myScriptPath)

$pkgPath = $MyInvocation.MyCommand.Path
# スクリプトのディレクトリ
$pkgDir  = Split-Path -Parent $pkgPath
$pkgMod  = $pkgDir + "\" + "Modules"	
$pkgSetup= $pkgDir + "\" + "Setup"		

# カスタムオブジェクト配列でコピー元 先, symbolic link先の定義、

$path_JDK    = "C:\opt\JDK"				#JDKのSymbolicLink
$instroot    = "D:\WebApps\"
$fwpath		 = $instroot + "Framework"	#OSSのSymbolicLink場所
$instancepath= $instroot + "Instance"	#OSSが更新するファイル、フォルダーの場所
$modpath	 = $instroot + "Modules" + "\" + $verFolderName 	#OSSの実install場所
$setuppath	 = $instroot + "Setup"
$setuppath_inst = $setuppath + "\" + $verFolderName 	#setup用のpowershell script
$setuppath_sym  = $setuppath + "\" + "current"

# -------------------------------------------------------------------
# Setup filesの copy, delete
#
# -------------------------------------------------------------------
# X:\pkg\verXXXXX\Setup\****.ps1を
# D:\WebApps\Setup\verXXXXX\****.ps1にコピーする
# D:\WebApps\Setup\current -> .\verXXXXX に symbolic linkを貼る
if($f_setup -or $f_copy) {
	CreateFolder_n_Copy -sourceRoot $pkgSetup -destRoot $setuppath_inst 
	# 自分自身を D:\WebApps\Setup\Setup_ver****.ps1としてコピーする
	$name = $myScriptPath
	$baseName = [System.IO.Path]::GetFileNameWithoutExtension($name)
	$destName = $setuppath + "\" + $baseName + "_" + $verFolderName + ".ps1"
	Write-Host "Copying $name to $destName"
	Copy-Item -Path $name -Destination $destName
}

if($f_setup -or $f_setsymlink) {
	ReSymLink -symSrc $setuppath_inst -symDst $setuppath_sym
}

if($f_delsymlink -or $f_delall) {
	DelSymLink -symLink $setuppath_sym
}

#------------------------------------------------------------
# module copy

if($f_setup -or $f_copy ) {
	# if(Test-Path -Path $pkgMod -PathType Container) { 
	# 	Write-Host ""
	# 	Write-Host "    $pkgMod を"
	# 	Write-Host "    $modpath へコピーします。"
	# 
	# 	if (Test-Path -LiteralPath $modpath) {
	# 		# コピーするフォルダーが既にコピー先にあったら=> 削除する
	# 	    Write-Host "    Warning: $modpath は既に存在しますので削除します。"
	# 		Remove-Item -LiteralPath $modpath -Recurse -Force
	# 	} 
	# 	Copy-Item -Path $pkgMod -Destination $modpath -Recurse -Force
	# }
}


#
# installする OSSの バージョン。 x:\pkg\Modulesに存在するもの
# version up時にここを書き換える

#------------------------------------------------------------------------
#
$inst_java	 = "microsoft-jdk-17.0.15-windows-x64"
$inst_httpd  = "httpd-2.4.63-250207-win64-VS17"
$inst_tomcat = "apache-tomcat-11.0.8"
#$inst_solr   = "solr-9.8.1" 
$inst_solr   = "solr-8.11.4"	#9.8.1はどうやってもWindows11で動作しないため8.11.4に変更
$inst_app	 = "MyApps"			#applicationのモジュール 

# -----------------
# java
$cpSrc_java	  = $pkgMod  + "\" + $inst_java					
$cpDst_java	  = $modpath + "\" + $inst_java
$symSrc_java  = $cpDst_java + "\" + "jdk-17.0.15+6"
$symDst_java  = $path_JDK

# -----------------
# httpd
# -----------------
$cpSrc_httpd  = $pkgMod  + "\" + $inst_httpd
$cpDst_httpd  = $modpath + "\" + $inst_httpd
$symSrc_httpd = $cpDst_httpd + "\" + "Apache24"
$symDst_httpd = $fwpath + "\" + "apache"

# -----------------
# tomcat
# -----------------
$cpSrc_tomcat = $pkgMod  + "\" + $inst_tomcat
$cpDst_tomcat = $modpath + "\" + $inst_tomcat
$symSrc_tomcat= $cpDst_tomcat
$symDst_tomcat= $fwpath + "\" + "tomcat"

# -----------------
# solr
# -----------------
$cpSrc_solr   = $pkgMod  + "\" + $inst_solr
$cpDst_solr   = $modpath + "\" + $inst_solr
$symSrc_solr  = $cpDst_solr
$symDst_solr  = $fwpath + "\" + "solr"

# -----------------
# app
$cpSrc_app  = $pkgMod  + "\" + $inst_app
$cpDst_app  = $modpath + "\" + $inst_app
$symSrc_app = $cpDst_app
$symDst_app = $fwpath  + "\" + "MyApps"


$pairList = @(
  [PSCustomObject]@{fcopy=$false; mod="java";  src=$cpSrc_java;  dst=$cpDst_java;  symSrc=$symSrc_java;  symDst=$symDst_java }
  [PSCustomObject]@{fcopy=$false; mod="httpd"; src=$cpSrc_httpd; dst=$cpDst_httpd; symSrc=$symSrc_httpd; symDst=$symDst_httpd }
  [PSCustomObject]@{fcopy=$false; mod="tomcat";src=$cpSrc_tomcat;dst=$cpDst_tomcat;symSrc=$symSrc_tomcat;symDst=$symDst_tomcat}
  [PSCustomObject]@{fcopy=$false; mod="solr";  src=$cpSrc_solr;  dst=$cpDst_solr;  symSrc=$symSrc_solr;  symDst=$symDst_solr}
  [PSCustomObject]@{fcopy=$true;  mod="app";   src=$cpSrc_app;   dst=$cpDst_app;   symSrc=$symSrc_app;   symDst=$symDst_app}
)

$index = 0;
foreach ($pair in $pairList) {
	$src    = $($pair.src)
	$dst    = $($pair.dst)
	$symSrc = $($pair.symSrc)
	$symDst = $($pair.symDst)
	$mod	= $($pair.mod)
	$fcopy  = $($pair.fcopy)	#強制的にコピー

	Write-Host "$index"
	Write-Host "    src   = $src"
	Write-Host "    dst   = $dst"
	Write-Host "    symSrc= $symSrc"
	Write-Host "    symDst= $symDst"
	$index++

	if($f_debug) {
		continue
	}
	
	# x:\pkg\ModuleInst.ps1として動作したら
	# x:\pkg\Modules\xxxxx -> d:\WebApps\Modules\xxxxにcopyする
	# 運用PCの d:\WebApps\Setup\ModuleInst.ps1として動作したら、SymbolicLinkを貼るだけ
	# 

	if ($f_setup -or $f_copy ) {
		if(Test-Path -Path $src -PathType Container) { 
			Write-Host ""
			Write-Host "    $src を"
			Write-Host "    $dst へコピーします。"
		
			if (Test-Path -LiteralPath $dst) {
				# コピーするフォルダーが既にコピー先にあったら=> 既に同一 versionの apacheがinstallされていたら とみなし何もしない
			    Write-Host "    Warning: $dst は既に存在します。コピーしません。"
			} else {
				# このファイルコピーは D:\WebApps\modules\httpd がなかったとしても D:\WebApps\modules\httpd\httpd-2.4.63-250207-win64-VS17フォルダーを作ってくれる	
				Copy-Item -Path $src -Destination $dst -Recurse -Force
			}
		}
	}

	if($f_setup -or $f_setsymlink) {
		#
		# symbolic linkを作成. 既にSymbolic Linkが存在したならば一度削除
		#
		Write-Host ""
		Write-Host "    SymLink $symSrc -> $symDst を作成します。"
		
		if (Test-Path -LiteralPath $symDst) {
		    $item = Get-Item -LiteralPath $symDst
		    if ( $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint ) {
				# folderが Symbolic Link だった時
		        Write-Host "    SymLink $symDst は既に存在します。"
		
		        # Write-Host "    Real path is $item.Target"
				# 上記コードは
				# Real Path is D:\WebApps\Framework\Apache.Target
				# と出力する。 $item がD:\WebApps\Framework\Apacheなので。 ひどい。 なので 別の変数に入れる
				$realTarget = $item.Target
		        Write-Host "    実際のPath is $realTarget"
				if( IsSameFolder -path1 $realTarget -path2 $symSrc) {
					# symbolic linkは既に設定されている。
					Write-Host "    Warning: SymLink先は既に $symSrc に設定されていますので何もしません。"
				}
				else {
					#	既存の シンボリックリンクを削除
					Write-Host "    SymLinkを一度削除します。ターゲットは $symDst です"
					Remove-Item -LiteralPath $symDst
					# 新しい symboliclinkを作成
					cmd /c mklink /D "$symDst" "$symSrc"
				}
			}
			else {	
		       Write-Error "  Folder $symDst already Exists but NOT Symbolick Link. Error"
			}
		}
		else {
			# 新しい symboliclinkを作成
			cmd /c mklink /D "$symDst" "$symSrc"
		}
	}

	if($f_delall -or $f_delsymlink) {
		DelSymLink -symLink $symDst
	}
	if($f_delall ) {
		Write-Host "deleting $dst"
		if (Test-Path -LiteralPath $dst) {
			Remove-Item -Path $dst -Recurse -Force
		}
	}
}

if($f_delall -or $f_delsymlink) {
	DelSymLink -symLink $setuppath_sym
}
if($f_delall ) {
	if (Test-Path -LiteralPath $modpath -PathType Container) {
		Remove-Item -Path $modpath -Recurse -Force
	}

	if (Test-Path -LiteralPath $setuppath_inst -PathType Container) {
		Remove-Item -Path $setuppath_inst -Recurse -Force
	}
}




