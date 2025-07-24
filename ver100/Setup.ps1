#################################################################################
# File		:	Setup.ps1 or Setup_verXXX.ps1
# Purpose	:	インストーラー、メンテナンスツール、アンインストーラー.
#				Setup.ps1: インストーラーとして動作させる時の名前
#				Setup_verXXX.ps1. インストール後のメンテナンス、アンインストーラーとして動かすときの名前
# Details	:		
#				インストール先は D:\WebApps固定
#
#--------------------------------------------------------------------------------
# このスクリプトの引数: command
#--------------------------------------------------------------------------------
param (
	[string]$command
)
#--------------------------------------------------------------------------------
# 利用する変数の定義.

$JDKRoot = "C:\opt\JDK"				#JDKのsymbolic Link root
$AppRoot = "D:\WebApps"				#アプリケーションのインストール場所


#--------------------------------------------------------------------------------
# DATA DEFINITION start start start
# 
$InstJava  = [PSCustomObject]@{fSetup=$false;  mod="jdk";    folder="microsoft-jdk-17.0.15-windows-x64"; subFolder="jdk-17.0.15+6"; symDst=$JDKRoot}
$InstHttpd = [PSCustomObject]@{fSetup=$true;   mod="httpd";  folder="httpd-2.4.63";                      subFolder="Apache24";      symDst=$null   }
$InstTomcat= [PSCustomObject]@{fSetup=$true;   mod="tomcat"; folder="apache-tomcat-11.0.5";              subFolder=$null;           symDst=$null   }
$InstSolr  = [PSCustomObject]@{fSetup=$true;   mod="solr";   folder="solr-8.11.4";                       subFolder=$null;           symDst=$null   }
$InstApp   = [PSCustomObject]@{fSetup=$true;   mod="MyApps"; folder="MyApps";                            subFolder=$null;           symDst=$null   }

$folderDefList = @(
  [PSCustomObject]@{inst=$InstJava	}
  [PSCustomObject]@{inst=$InstHttpd	}
  [PSCustomObject]@{inst=$InstTomcat}
  [PSCustomObject]@{inst=$InstSolr	}
  [PSCustomObject]@{inst=$InstApp	}
)
#
# DATA DEFINITION end end end end 
#--------------------------------------------------------------------------------


#基本固定値
$FolderModules    = "Modules"	
$FolderSetup      = "Setup"	
$FolderFramework  = "Framework"	
$FolderInstance   = "Instance"	

#--------------------------------------------------------------------------------
# Setup.ps1という名前なら インストーラーのSetupプログラムと解釈する
# Setup_ver***という名前なら、インストーラーによってインストールされたあとのメンテナンスSetupと判断する。
#
$MY_SELF_PATH = $MyInvocation.MyCommand.Path	#ファイル名の絶対パス(X:\pkg\ver100\Setup.ps1 or d:\WebApps\Setup\Setup_ver***.ps1)
$MY_SELF = Split-Path -Leaf $MY_SELF_PATH		#ファイル名(Setup.ps1 or Setup_ver***.ps1)
$PKG_SETUP = $true
if($MY_SELF -ieq 'Setup.ps1')
{
	$VERSION_NAME = Split-Path -Leaf (Split-Path -Parent $MY_SELF_PATH)
	$PKG_SETUP = $true
}
elseif($MY_SELF -imatch '^Setup_([^_]+)\.ps1$') {
    $VERSION_NAME= $matches[1]
	$PKG_SETUP = $false
}
else {
	Write-Host "Error"
}

Write-Host ('$MY_SELF=      ' + $MY_SELF)
Write-Host ('$VERSION_NAME= ' + $VERSION_NAME)
Write-Host ('$PKG_SETUP=    ' + $PKG_SETUP )

#利用変数はcustom object(sParam)で定義。
#PowerShell 5.1ではdynamicに変数定義できないので。(7.1以降ならできる)

$sParam = [PSCustomObject]@{
	myScriptPath		=   $MY_SELF_PATH		# スクリプト自身のフルパス ex) e:\pkg\verXXX\Setup.ps1, d:\WebApps\Setup\Setup_ver***.ps1. 				
	myScriptName		=   $MY_SELF				#ファイル名(Setup.ps1 or Setup_ver***.ps1)
	verFolderName		=   $VERSION_NAME
	pkgPath				=	""	#	Setup.ps1として動作したときのみ設定する
	pkgDir				=	""	#	Setup.ps1として動作したときのみ設定する
	pkgMod				=   ""	#	Setup.ps1として動作したときのみ設定する
	pkgInst				=   ""	#	Setup.ps1として動作したときのみ設定する
	pkgSetup			=   ""	#	Setup.ps1として動作したときのみ設定する
	path_JDK		    =   $JDKRoot							#JDKのSymbolicLink
	TargetFW			=   $AppRoot + "\" + $FolderFramework	#OSSのSymbolicLink場所
	TargetInst			=   $AppRoot + "\" + $FolderInstance	#OSSが更新するファイル、フォルダーの場所
	TargetMod			=   $AppRoot + "\" + $FolderModules		#OSSをインストールする場所
	TargetSetup			=   $AppRoot + "\" + $FolderSetup		#Setupファイルをインストールする場あほ
	TargetModInst		=   ""	#	あとで設定 d:\WebApps\Modules\verXXXX
	TargetSetupInst		=   ""	#	あとで設定 d:\WebApps\Setup\verXXXX
	TargetSetupSym		=   ""	#	あとで設定 d:\WebApps\Setup\current
	versionName			=   $VERSION_NAME
	f_pkgSetup			=   $PKG_SETUP
}

if($sParam.f_pkgSetup) {	
	$sParam.pkgPath			= ($script:_pkgPath = $MyInvocation.MyCommand.Path)			#スクリプト自身のフルパス
	$sParam.pkgDir			= ($script:_pkgDir  = Split-Path -Parent $script:_pkgPath)	#スクリプト自身のフォルダー
	$sParam.pkgMod			=  $script:_pkgDir + "\" + $FolderModules					#インストールするモジュールのパス
	$sParam.pkgInst			=  $script:_pkgDir + "\" + $FolderInstance					#インストールする初期データのパス
	$sParam.pkgSetup		=  $script:_pkgDir + "\" + $FolderSetup						#インストールするSetupファイルのパス
}
$sParam.TargetModInst		=  $AppRoot + "\" + $FolderModules + "\" + $sParam.versionName 	#OSSの実install場所 d:\WebApps\Modules\verXXX
$sParam.TargetSetupInst		=  $AppRoot + "\" + $FolderSetup   + "\" + $sParam.versionName  #setup用のpowershell scriptのfolder
$sParam.TargetSetupSym		=  $AppRoot + "\" + $FolderSetup   + "\" + "current"


#################################################################################
#
# Function definition start
#
# --------------------------------------------------------------
# Function: ShowUsage
# Purpose:	使いかたを表示する。 引数の詳細を表示する
# 
function ShowUsage {
	param (
        [string]$FileName,
		[bool]  $fPkg
    )
	Set-StrictMode -Version Latest
	Write-Host ""
	Write-Host "Script: $FileName"
	if($fPkg) {
		Write-Host "  システムのインストールを行います。"
	}
	else {
		Write-Host "  既にインストールされているモジュールのメンテナンス、アンインストールを行います。"
	}
	Write-Host "Usage: "
	Write-Host "   $FileName [command]"     
	Write-Host "Examples: "
	Write-Host ("   " + "$FileName help      " + "   " +     "usageを表示 ")
	Write-Host ("   以下のコマンドは 管理者権限で実行する必要があります  ")
	if($fPkg) {
		Write-Host ("   " + "$FileName datainit  "  +  "  " + "初期データをセットアップします。初めてインストールするとき一度だけ行います。")
		Write-Host ("   " + "$FileName setup     "  +  "  " + "システムをインストールします。 "	)
	}
	else {
		Write-Host ("   " + "$FileName setsymlink" + "   " + "インストール済みのモジュールのシンボリックリンクのみ行います "	)
		Write-Host ("   " + "$FileName delsymlink" + "   " + "インストール済みのモジュールのシンボリックリンクの削除を行います "	)
		Write-Host ("   " + "$FileName delall    " + "   " + "インストール済みのモジュールの削除を行います "	)
	}
}

# ------------------------------------------------------------
# Function: DoDumpParam
# Purpose:	指定されたフォルダーがどちらも同一のものかどうかを確認する
# 
function DoDumpParam {
	param($setupParam)

	Write-Host ('$myScriptPath   = ' + $($setupParam.myScriptPath    ) ) 
	Write-Host ('$myScriptName   = ' + $($setupParam.myScriptName    ) )
	Write-Host ('$verFolderName  = ' + $($setupParam.verFolderName   ) )
	Write-Host ('$pkgPath        = ' + $($setupParam.pkgPath         ) )
	Write-Host ('$pkgDir         = ' + $($setupParam.pkgDir          ) )
	Write-Host ('$pkgMod         = ' + $($setupParam.pkgMod          ) )
	Write-Host ('$pkgInst        = ' + $($setupParam.pkgInst         ) )
	Write-Host ('$pkgSetup       = ' + $($setupParam.pkgSetup        ) )
	Write-Host ('$path_JDK       = ' + $($setupParam.path_JDK        ) )
	Write-Host ('$TargetFW       = ' + $($setupParam.TargetFW        ) )
	Write-Host ('$TargetInst     = ' + $($setupParam.TargetInst      ) )
	Write-Host ('$TargetMod      = ' + $($setupParam.TargetMod       ) )
	Write-Host ('$TargetSetup    = ' + $($setupParam.TargetSetup     ) )
	Write-Host ('$TargetModInst  = ' + $($setupParam.TargetMod       ) )
	Write-Host ('$TargetSetupInst= ' + $($setupParam.TargetSetupInst ) )
	Write-Host ('$TargetSetupSym = ' + $($setupParam.TargetSetupSym  ) )
	Write-Host ('$versionName    = ' + $($setupParam.versionName     ) )
	Write-Host ('$f_pkgSetup     = ' + $($setupParam.f_pkgSetup      ) )
}


# ------------------------------------------------------------
# Function: IsSameFolder
# Purpose:	指定されたフォルダーがどちらも同一のものかどうかを確認する
# 
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
# Function: IsReparsePointFolder
# Purpose:	指定されたフォルダーがSymbolicLink, Juncionの ReporsePOintFolderならtrue, 普通のフォルダーならfalseを返す
# 
function IsReparsePointFolder {
	param (
		[string]$path
	)
	
	if(Test-Path -LiteralPath $path) {
		#---------------------------------------
		# Get-Itemは$pathが存在しないとエラーになる  
		#---------------------------------------
		$item = Get-Item $path	
		if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
			# ReparsePoint ならジャンクションかシンボリックリンク
			if ($item.LinkType -eq "SymbolicLink") {
				#Write-Host "$path はシンボリックリンクです"
			} elseif ($item.LinkType -eq "Junction") {
				#Write-Host "$path はジャンクションです"
			} else {
				#Write-Host "$path は別のReparsePointです: $($item.LinkType)"
			}
			return $true
		} else {
			#Write-Host "$path はシンボリックリンクではありません"
			return $false
		}
	}
	else {
		#フォルダーが存在しない時は ReparsePointではない -> trueを返す
		return $true;
	}
}

# ------------------------------------------------------------
# Function: 管理者権限チェック
# 
function HasAdminRights {
	return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

}
# ------------------------------------------------------------
# Function: 管理者権限出なければエラーメッセージを出す
# 
function CheckAdmin {
	if( -not (HasAdminRights) ) {
		Write-Host "このコマンドは管理者権限で実行してください。"
		return $false
	}
	else {
		return $true
	}
}

function FnDummy {
	param (
		[string]$src,
		[string]$dst,
		[string]$symSrc,
		[string]$symDst
	)
	Write-Host "FnDummy Start"
	Write-Host ('    $src   =' + $src)
	Write-Host ('    $dst   =' + $dst)
	Write-Host ('    $symSrc=' + $symSrc)
	Write-Host ('    $symDst=' + $symDst)
	Write-Host "FnDummy End"
}

function FnCopy_n_SymLink {
	param (
		[string]$src,
		[string]$dst,
		[string]$symSrc,
		[string]$symDst
	)
	& FnCopy      -src $src -dst $dst -symSrc $symSrc -symDst $symDst
	& FnReSymLink -src $src -dst $dst -symSrc $symSrc -symDst $symDst
}

function FnCopy {
	param (
		[string]$src,
		[string]$dst,
		[string]$symSrc,
		[string]$symDst
	)

	if(Test-Path -Path $src -PathType Container) { 
		Write-Host ""
		Write-Host "    $src を"
		Write-Host "    $dst へコピーします。"
	
		if (Test-Path -LiteralPath $dst) {
			# コピーするフォルダーが既にコピー先にあったら=> 既に同一 versionの apacheがinstallされていたとみなし何もしない
		    Write-Host "    Warning: $dst は既に存在するためコピーしません"
		} else {
			# このファイルコピーは D:\WebApps\modules\httpd がなかったとしても D:\WebApps\modules\httpd\httpd-2.4.63-250207-win64-VS17フォルダーを作ってくれる	
			Copy-Item -Path $src -Destination $dst -Recurse -Force
			Write-Host "  コピーが終了しました。 "		
		}
	}
	else {
		Write-Host "Error no $src"
	}
}

# --------------------------------------------------------------------------------		
# Function: FnReSymLink
# 
function FnReSymLink {
	param (
		[string]$src,
		[string]$dst,
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
		if(IsReparsePointFolder -path $symDst) {
			Write-Debug "$symSetupDst は既にシンボリックリンクが貼られています"
		}
		Write-Debug "try to run mklink"
		cmd /c mklink /D "$symDst" "$symSrc"
	}
}

# ------------------------------------------------------------
# Function: FnDelSymLink
#
function FnDelSymLink {
	param (
		[string]$src,
		[string]$dst,
		[string]$symSrc,
		[string]$symDst
	)

	if (Test-Path -LiteralPath $symDst) {
	    $item = Get-Item -LiteralPath $symDst
	    if ( $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint ) {
			# folderが Symbolic Link だった時
			Write-Host "    deleting symbolic link: $symDst"
			Remove-Item -LiteralPath $symDst
		}
		else {	
	       Write-Error "  Folder $symDstは Symbolick Linkではありません. Error"
		   return
		}
	}
	else {
		Write-Host "$symDst を消そうとしましたが存在しません"
	}
}

# ------------------------------------------------------------
# Function: FnDelFolder
#
function FnDelFolder {
	param (
		[string]$src,
		[string]$dst,
		[string]$symSrc,
		[string]$symDst
	)

	& FnDelSymLink -symSrc $symSrc -symDst $symDst
	Write-Host ($dst + "を削除します。")
	if (Test-Path $dst) {
		Remove-Item $dst -Recurse -Force
	}	
}

# ------------------------------------------------------------
# Function: DoCommand_4_FolderDef
# Purpose:	DATA DEFINITIONで定義された folderDefListを引数に取り
#			folder定義ごとに指定されたcommandNameの関数を呼び出す。
#
function DoCommand_4_FolderDef {
	param (
		[string]$commandName,			# Fn***関数名を指定
		[pscustomobject]$setupParam,	# $sParamを指定	
		[pscustomobject]$defList		# DATA DEFINITIONで定義された $folderDefListを指定	
	)
	# $folderDefList には 
	$index = 0
	foreach ($pair in $defList) {
		Write-Host "[$index]"
		$mod	= $($pair.inst.mod)
		$fSetup = $($pair.inst.fSetup)
		if($setupParam.f_pkgSetup) {
			$src    = $setupParam.pkgMod + "\" + $($pair.inst.folder)
		}
		else {
			$src    = $null
		}
		$dst    = $setupParam.TargetModInst + "\" + $($pair.inst.folder)
	
		# symlinkの元を作成		
		$symSrc = $dst
		if($($pair.inst.subfolder) -ne $null) {
			# subFolderが指定されていたらそれを追加してlink元とする。
			Write-Host ('    $($pair.inst.subfolder)' + "="  + $($pair.inst.subfolder))
			$symSrc = $symSrc + "\" + $($pair.inst.subfolder)
		}
		if($($pair.inst.symDst) -eq $null) {
			$symDst = $setupParam.TargetFW + "\" + $($pair.inst.mod)
		}
		else {
			$symDst = $($pair.inst.symDst)
		}
	
		Write-Host "    mod   = $mod"
		Write-Host "    src   = $src"
		Write-Host "    dst   = $dst"
		Write-Host "    symSrc= $symSrc"
		Write-Host "    symDst= $symDst"
	
		if($fSetup ) {
			#指定されたcommandNameをコマンドとして実行(&)
			& $commandName -src $src -dst $dst -symSrc $symSrc -symDst $symDst
		}
		else {
			Write-Host ('   ' + $mod  + 'はセットアップ対象になっていないのでスキップします')
		}
		$index++
	}
}
function FnCreateFolder {
	param (
		[string]$folder
	)
	Write-Host ($folder + "を作成します。") -NoNewLine
	if(Test-Path -LiteralPath $folder) {
		Write-Host "=>既に存在します。"
	}
	else {
		#New-Itemでfolderと作ると、その後以下のように作成されたfolderのdirを勝手にやった結果を標準出力に出しやがる。
		#------------------------------------------------------------------------
		# ディレクトリ: D:\WebApps
		# Mode                 LastWriteTime         Length Name
		# ----                 -------------         ------ ----
		# d-----        2025/07/24     15:18                Instance
		#これを抑制するには  "| Out-Null"するのだと。	
		New-Item -ItemType Directory -Path $folder | Out-Null
	}
}



# ------------------------------------------------------------
# Function: DoInitData
#
function DoInitData {
	param (
		[pscustomobject]$setupParam
	)
	Write-Host "システムのデータを初期化します。"
	FnCreateFolder -folder $setupParam.TargetFW
	FnCreateFolder -folder $setupParam.TargetMod
	FnCreateFolder -folder $setupParam.TargetSetup
	if(Test-Path -LiteralPath $setupParam.TargetInst) {
		$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
		$backup = $setupParam.TargetInst + "_" + $timestamp + "_bkini"

		Write-Host ($setupParam.TargetInst + "が存在します。") 
		Write-Host ("   " + $backup + "にリネーム、保存します。") 
		Rename-Item -Path $setupParam.TargetInst -NewName $backup
	}		
	FnCreateFolder -folder $setupParam.TargetInst
	Write-Host "Test"
	$src = $setupParam.pkgInst + "\*"
	Write-Host "Test2"
	Write-Host "$src -> $($setupParam.TargetInst) にコピーします" 
	Copy-Item -Path $src -Destination $setupParam.TargetInst -Recurse -Force	

}

function DoDelData {
	param (
		[pscustomobject]$setupParam
	)
	Write-Host "システムのデータを削除します。"
	# $targetFiles = $setupParam.TargetInst + "\*"

}


# ------------------------------------------------------------
# Function: DoSetup
#
function DoSetup {
	param (
		[pscustomobject]$setupParam
	)
	Write-Host "システムのセットアップを始めます。"	 

	DoCommand_4_FolderDef -commandName "FnCopy_n_SymLink" -setupParam $setupParam -defList $folderDefList

	# Setup.ps1を d:\WebApps\Setup\Setup_verXXX.ps1に
	# Setup_Func.ps1を d:\WebApps\Setup\Setup_Func_verXXX.ps1に
	# コピーする。
	
	$setupMainSrc = $setupParam.pkgDir + "\" + "Setup.ps1"
	$setupFuncSrc = $setupParam.pkgDir + "\" + "Setup_Func.ps1"
	
	$setupMainDst = $setupParam.TargetSetup + "\" + "Setup_" + $setupParam.versionName + ".ps1"
	$setupFuncDst = $setupParam.TargetSetup + "\" + "Setup_" + $setupParam.versionName + "_Func.ps1"
	
	$symSetupSrc  = $setupParam.TargetSetupInst
	$symSetupDst  = $setupParam.TargetSetupSym
	Write-Host ('   $symSetupSrc = ' + $symSetupSrc )
	Write-Host ('   $symSetupDst = ' + $symSetupDst )
	if (Test-Path $setupParam.TargetSetupInst) {
	
	}
	else {
		New-Item -Path $setupParam.TargetSetupInst -ItemType Directory
	}			
	
	# e:\pkg\verXXX\Setup/*.* -> d:\WebApps\Setup\verXXX\*.* にコピー
	$srcSetup = $setupParam.pkgSetup
	Write-Host "   $srcSetup を $($setupParam.TargetSetupInst) にコピーします。"
	
	Get-ChildItem -Path $srcSetup -File | ForEach-Object {
	    Copy-Item $_.FullName -Destination $setupParam.TargetSetupInst
	}
	
	Write-Host "   $setupMainSrc を $setupMainDst にコピーします。"
	Copy-Item $setupMainSrc -Destination $setupMainDst
	
	Write-Host "   $symSetupDst と $symSetupSrc にシンボリックリンクを貼ります。"
	
	if(IsReparsePointFolder -path $symSetupDst) {
		Write-Debug "$symSetupDst は既にシンボリックリンクが貼られています"
	}
	Write-Debug "test test"
	cmd /c mklink /D "$symSetupDst" "$symSetupSrc"
}

# ------------------------------------------------------------
# Function: DoUnInstall
#
function DoUnInstall {
	param (
		[pscustomobject]$setupParam
	)
	Write-Host "システムのアンインストールを行います。"	 
	DoCommand_4_FolderDef -commandName "FnDelFolder" -setupParam $setupParam -defList $folderDefList
	Write-Host "$($setupParam.TargetSetupInst) を削除します。"

	if( Test-Path -LiteralPath $setupParam.TargetSetupInst) {
		# Remove-Item -LiteralPath $setupParam.TargetSetupInst) {
	}
	else {
		Write-Host "   $($setupParam.TargetSetupInst) が存在しません。"
	}
}

#
#
# Function definition end
#################################################################################

switch($command) {
	"help"		{ ShowUsage $sParam.myScriptName $sParam.f_pkgSetup; exit 1}
	"dump"		{ DoDumpParam  -setupParam $sParam;	exit 0}
	"dummy"		{ exit 1}
	"initdata"	{ DoInitData   -setupParam $sParam;	exit 0}
	"deldata"	{ DoDelData    -setupParam $sParam;	exit 0}
	"setup"		{ DoSetup      -setupParam $sParam;	exit 0}
	"setsymlink"{ DoSetSymLink -setupParam $sParam;	exit 0}
	"delsymlink"{ DoDelSymLink -setupParam $sParam;	exit 0}
	"delall"	{ DoUnInstall  -setupParam $sParam;	exit 0}
	default		{ ShowUsage $sParam.myScriptName $sParam.f_pkgSetup; exit 1}
}

exit 0


#------------------------------------------------------------
#$commandが以下の時はここにくる。
#	"setup"		
#	"copyonly"	
#	"setsymlink"
#	"delsymlink"
#	"delall"	
# そして 管理者権限でなければエラーにする。

if( -not (CheckAdmin) ) {
	exit 1
}

#	#--------------------------------------------------------------------------------
#	#すべての Inst***に対しで処理。setup/delallの場合はその後後処理を行う
#	$index = 0
#	foreach ($pair in $pairList) {
#		Write-Host "[$index]"
#		$mod	= $($pair.inst.mod)
#		$fSetup = $($pair.inst.fSetup)
#		if($sParam.f_pkgSetup) {
#			$src    = $sParam.pkgMod + "\" + $($pair.inst.folder)
#		}
#		else {
#			$src    = $null
#		}
#		$dst    = $sParam.TargetMod + "\" + $($pair.inst.folder)
#	
#		# symlinkの元を作成		
#		$symSrc = $dst
#		if($($pair.inst.subfolder) -ne $null) {
#			# subFolderが指定されていたらそれを追加してlink元とする。
#			Write-Host ('    $($pair.inst.subfolder)' + "="  + $($pair.inst.subfolder))
#			$symSrc = $symSrc + "\" + $($pair.inst.subfolder)
#		}
#		if($($pair.inst.symDst) -eq $null) {
#			$symDst = $sParam.TargetFW + "\" + $($pair.inst.mod)
#		}
#		else {
#			$symDst = $($pair.inst.symDst)
#		}
#	
#		Write-Host "    mod   = $mod"
#		# Write-Host "    src   = $src"
#		# Write-Host "    dst   = $dst"
#		# Write-Host "    symSrc= $symSrc"
#		# Write-Host "    symDst= $symDst"
#	
#		if($fSetup ) {
#			& $commandFn -src $src -dst $dst -symSrc $symSrc -symDst $symDst
#		}
#		else {
#			Write-Host ('   ' + $mod  + 'はセットアップ対象になっていないのでスキップします')
#		}
#		$index++
#	}

#あと処理
switch($command) {
	"setup"
		{
			# Setup.ps1を d:\WebApps\Setup\Setup_verXXX.ps1に
			# Setup_Func.ps1を d:\WebApps\Setup\Setup_Func_verXXX.ps1に
			# コピーする。

			$setupMainSrc = $sParam.pkgDir + "\" + "Setup.ps1"
			$setupFuncSrc = $sParam.pkgDir + "\" + "Setup_Func.ps1"

			$setupMainDst = $sParam.TargetSetup + "\" + "Setup_" + $sParam.versionName + ".ps1"
			$setupFuncDst = $sParam.TargetSetup + "\" + "Setup_" + $sParam.versionName + "_Func.ps1"

			$symSetupSrc  = $sParam.TargetSetupInst
			$symSetupDst  = $sParam.TargetSetupSym
			Write-Host ('   $symSetupSrc = ' + $symSetupSrc )
			Write-Host ('   $symSetupDst = ' + $symSetupDst )
			if (Test-Path $sParam.TargetSetupInst) {

			}
			else {
				New-Item -Path $sParam.TargetSetupInst -ItemType Directory
			}			

			# e:\pkg\verXXX\Setup/*.* -> d:\WebApps\Setup\verXXX\*.* にコピー
			$srcSetup = $sParam.pkgSetup
			Write-Host "   $srcSetup を $($sParam.TargetSetupInst) にコピーします。"

			Get-ChildItem -Path $srcSetup -File | ForEach-Object {
			    Copy-Item $_.FullName -Destination $sParam.TargetSetupInst
			}

			Write-Host "   $setupMainSrc を $setupMainDst にコピーします。"
			Copy-Item $setupMainSrc -Destination $setupMainDst

			Write-Host "   $symSetupDst と $symSetupSrc にシンボリックリンクを貼ります。"

			if(IsReparsePointFolder -path $symSetupDst) {
				Write-Debug "$symSetupDst は既にシンボリックリンクが貼られています"
			}
			Write-Debug "test test"
			cmd /c mklink /D "$symSetupDst" "$symSetupSrc"
			break
		}
	"delall"	{
			# d:\WebApps\Setup\verXXXを削除する。
			Write-Host "$($sParam.TargetSetupInst) を削除します。"
			if( Test-Path -LiteralPath $sParam.TargetSetupInst) {
				# Remove-Item -LiteralPath $sParam.TargetSetupInst) {
			}
			else {
				Write-Host "   $($sParam.TargetSetupInst) が存在しません。"
			}
			break

		}
	}

exit 0

