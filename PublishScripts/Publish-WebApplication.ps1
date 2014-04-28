#Requires -Version 3.0

<#
.SYNOPSIS
Visual Studio Web プロジェクト用の Windows Azure Web サイト、仮想マシン、SQL データベース、およびストレージ アカウントを作成して配置します。

.DESCRIPTION
Publish-WebApplication.ps1 スクリプトは、Visual Studio Web プロジェクトで指定した Windows Azure リソースを作成し、(オプションで) 配置します。Windows Azure Web サイト、仮想マシン、SQL データベース、およびストレージ アカウントを作成できます。

To manage the entire application lifecycle of your web application in this script, implement the placeholder functions New-WebDeployPackage and Test-WebApplication.

有効な Web 配置パッケージ ZIP ファイルを使用して WebDeployPackage パラメーターを指定する場合、Publish-WebApplication.ps1 は作成した Web ページまたは仮想マシンも配置します。

このスクリプトには、Windows PowerShell 3.0 以降および Windows Azure PowerShell バージョン 0.7.4 以降が必要です。Windows Azure PowerShell とその Azure モジュールのインストール方法の詳細については、http://go.microsoft.com/fwlink/?LinkID=350552 を参照してください。使用している Azure モジュールのバージョンを確認するには、(Get-Module -Name Azure -ListAvailable).version と入力します。Windows PowerShell のバージョンを確認するには、$PSVersionTable.PSVersion と入力します

このスクリプトを実行する前に、Add-AzureAccount コマンドレットを実行して、Windows Azure アカウントの資格情報を Windows PowerShell に提供してください。また、SQL データベースを作成する場合は、既存の Windows Azure SQL データベース サーバーが必要です。SQL データベースを作成するには、Azure モジュールの New-AzureSqlDatabaseServer コマンドレットを使用します。

Also, if you have never run a script, use the Set-ExecutionPolicy cmdlet to an execution policy that allows you to run scripts. To run this cmdlet, start Windows PowerShell with the 'Run as administrator' option.

この Publish-WebApplication.ps1 スクリプトは、Web プロジェクトの作成時に Visual Studio によって生成される JSON 構成ファイルを使用します。JSON ファイルは、Visual Studio ソリューションの PublishScripts フォルダーにあります。

JSON 構成ファイルでは 'databases' オブジェクトを削除または編集できます。'website' オブジェクト、'cloudservice' オブジェクト、またはこれらの属性は削除しないでください。ただし、'databases' オブジェクト全体を削除することや、データベースを表す属性を削除することはできます。SQL データベースを作成し、配置しない場合は、"connectionStringName" 属性またはその値を削除してください。

また、AzureWebAppPublishModule.psm1 Windows PowerShell スクリプト モジュールの関数を使用して、Windows Azure サブスクリプションにリソースを作成します。スクリプト モジュールのコピーは、Visual Studio ソリューションの PublishScripts フォルダーにあります。

Publish-WebApplication.ps1 は、そのまま使用することも、ニーズを満たすよう編集することもできます。また、スクリプトとは別に、AzureWebAppPublishModule.psm1 モジュールの関数を使用および編集することもできます。たとえば、Invoke-AzureWebRequest 関数を使用して、Windows Azure Web サービスの任意の REST API を呼び出すことができます。

必要な Windows Azure リソースを作成するスクリプトを所有していれば、そのスクリプトを繰り返し使用して、Windows Azure に環境とリソースを作成できます。

このスクリプトの最新情報については、http://go.microsoft.com/fwlink/?LinkId=391217 を参照してください。
Web アプリケーション プロジェクトの構築について追加サポートを受けるには、次の MSBuild ドキュメントを参照してください: http://go.microsoft.com/fwlink/?LinkId=391339 
Web アプリケーション プロジェクトでの単体テストの実行について追加サポートを受けるには、次の VSTest.Console ドキュメントを参照してください: http://go.microsoft.com/fwlink/?LinkId=391340 

WebDeploy のライセンス条項については、次を参照してください: http://go.microsoft.com/fwlink/?LinkID=389744 

.PARAMETER Configuration
Visual Studio によって生成される JSON 構成ファイルのパスとファイル名を指定します。このパラメーターは必須です。このファイルは、Visual Studio ソリューションの PublishScripts フォルダーにあります。ユーザーは、属性値の変更や省略可能な SQL データベース オブジェクトの削除によって、JSON 構成ファイルをカスタマイズできます。スクリプトが正常に実行されるよう、Web サイト構成ファイルおよび仮想マシン構成ファイルの SQL データベース オブジェクトを削除することもできます。Web サイトおよびクラウド サービスのオブジェクトと属性は、削除できません。発行時に SQL データベースを作成したり接続文字列に適用したりしない場合は、SQL データベース オブジェクトの "connectionStringName" 属性を空にするか、SQL データベース オブジェクト全体を削除します。

注意: このスクリプトでは、仮想マシンに対して Windows 仮想ハード ディスク (VHD) ファイルのみをサポートしています。Linux VHD を使用するには、スクリプトで Linux パラメーターを含むコマンドレット (New-AzureQuickVM、New-WAPackVM など) を呼び出すように、スクリプトを変更してください。

.PARAMETER SubscriptionName
Windows Azure アカウントのサブスクリプションの名前を指定します。このパラメーターは省略可能です。既定値は現在のサブスクリプション (Get-AzureSubscription -Current) です。現在のサブスクリプションではないサブスクリプションを指定する場合、スクリプトは指定のサブスクリプションを現在のサブスクリプションに一時的に変更しますが、スクリプトの完了前に現在のサブスクリプション ステータスを復元します。スクリプトの完了前にエラーが発生した場合は、指定のサブスクリプションが現在のサブスクリプションとして設定されたままになる場合があります。

.PARAMETER WebDeployPackage
Visual Studio によって生成される Web 配置パッケージ ZIP ファイルのパスとファイル名を指定します。このパラメーターは省略可能です。

有効な Web 配置パッケージを指定した場合、このスクリプトは MsDeploy.exe と Web 配置パッケージを使用して、Web サイトを配置します。

Web 配置パッケージ ZIP ファイルを作成するには、「How to: Create a Web Deployment Package in Visual Studio (方法: Visual Studio で Web 配置パッケージを作成する)」(http://go.microsoft.com/fwlink/?LinkId=391353) を参照してください。

MSDeploy.exe の詳細については、「Web 配置コマンド ライン リファレンス」(http://go.microsoft.com/fwlink/?LinkId=391354) を参照してください 

.PARAMETER AllowUntrusted
仮想マシンで Web 配置エンドポイントへの信頼されていない SSL 接続を許可します。このパラメーターは MSDeploy.exe の呼び出しで使用されます。このパラメーターは省略可能です。既定値は False です。このパラメーターは、有効な ZIP ファイル値の WebDeployPackage パラメーターを含めている場合にのみ有効です。MSDeploy.exe の詳細については、「Web 配置コマンド ライン リファレンス」(http://go.microsoft.com/fwlink/?LinkId=391354) を参照してください 

.PARAMETER VMPassword
スクリプトで作成する Windows Azure 仮想マシンの管理者のユーザー名とパスワードを指定します。このパラメーターは、Name キーと Password キーを含むハッシュ テーブルを受け取ります。例:
@{Name = "admin"; Password = "pa$$word"}

このパラメーターは省略可能です。省略した場合の既定値は、JSON 構成ファイルに含まれている仮想マシンのユーザー名とパスワードです。

このパラメーターは、仮想マシンを含んでいるクラウド サービスを JSON 構成ファイルが対象としている場合にのみ有効です。

.PARAMETER DatabaseServerPassword
Sets the password for a Windows Azure SQL database server. This parameter takes an array of hash tables with Name (SQL database server name) and Password keys. Enter one hash table for each database server that your SQL databases use.

このパラメーターは省略可能です。既定値は、Visual Studio によって生成される JSON 構成ファイルの SQL データベース サーバー パスワードです。

この値は、JSON 構成ファイルに databases 属性と serverName 属性が含まれていて、ハッシュ テーブルの Name キーが serverName の値と一致している場合に有効です。

.INPUTS
なし。このスクリプトにはパラメーター値をパイプできません。

.OUTPUTS
なし。このスクリプトはオブジェクトを返しません。スクリプトのステータスについては、Verbose パラメーターを使用してください。

.EXAMPLE
PS C:\> C:\Scripts\Publish-WebApplication.ps1 -Configuration C:\Documents\Azure\WebProject-WAWS-dev.json

.EXAMPLE
PS C:\> C:\Scripts\Publish-WebApplication.ps1 `
-Configuration C:\Documents\Azure\ADWebApp-VM-prod.json `
-Subscription Contoso '
-WebDeployPackage C:\Documents\Azure\ADWebApp.zip `
-AllowUntrusted `
-DatabaseServerPassword @{Name='dbServerName';Password='adminPassword'} `
-Verbose

.EXAMPLE
PS C:\> $admin = @{name="admin";password="Test123"}
PS C:\> C:\Scripts\Publish-WebApplication.ps1 `
-Configuration C:\Documents\Azure\ADVM-VM-test.json `
-SubscriptionName Contoso `
-WebDeployPackage C:\Documents\Azure\ADVM.zip `
-VMPaassword = @{name = "vmAdmin"; password = "pa$$word"} `
-DatabaseServerPassword = @{Name='server1';Password='adminPassword1'}, @{Name='server2';Password='adminPassword2'} `
-Verbose

.LINK
New-AzureVM

.LINK
New-AzureStorageAccount

.LINK
New-AzureWebsite

.LINK
Add-AzureEndpoint
#>
[CmdletBinding(DefaultParameterSetName = 'None', HelpUri = 'http://go.microsoft.com/fwlink/?LinkID=391696')]
param
(
    [Parameter(Mandatory = $true)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $Configuration,

    [Parameter(Mandatory = $false)]
    [String]
    $SubscriptionName,

    [Parameter(Mandatory = $false)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [String]
    $WebDeployPackage,

    [Parameter(Mandatory = $false)]
    [Switch]
    $AllowUntrusted,

    [Parameter(Mandatory = $false, ParameterSetName = 'VM')]
    [ValidateScript( { $_.Contains('Name') -and $_.Contains('Password') } )]
    [Hashtable]
    $VMPassword,

    [Parameter(Mandatory = $false, ParameterSetName = 'WebSite')]
    [ValidateScript({ !($_ | Where-Object { !$_.Contains('Name') -or !$_.Contains('Password')}) })]
    [Hashtable[]]
    $DatabaseServerPassword,

    [Parameter(Mandatory = $false)]
    [Switch]
    $SendHostMessagesToOutput = $false
)


function New-WebDeployPackage
{
    #Web アプリケーションのビルドとパッケージ化を行う関数を作成します

    #Web アプリケーションをビルドするには、MsBuild.exe を使用します。詳細については、次の「MSBuild Command-Line Reference (MSBuild コマンド ライン リファレンス)」を参照してください: http://go.microsoft.com/fwlink/?LinkId=391339
}

function Test-WebApplication
{
    #この関数を編集して、Web アプリケーションで単体テストを実行します

    #Web アプリケーションで単体テストを実行する関数を作成するには、VSTest.Console.exe を使用します。詳細については、「VSTest.Console Command-Line Reference (VSTest.Console コマンド ライン リファレンス)」(http://go.microsoft.com/fwlink/?LinkId=391340) を参照してください
}

function New-AzureWebApplicationEnvironment
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Config,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMPassword,

        [Parameter (Mandatory = $false)]
        [AllowNull()]
        [Hashtable[]]
        $DatabaseServerPassword
    )
   
    $VMInfo = $null

    # JSON ファイルに 'webSite' 要素がある場合
    if ($Config.IsAzureWebSite)
    {
        Add-AzureWebsite -Name $Config.name -Location $Config.location | Out-String | Write-HostWithTime
        # SQL データベースを作成します。接続文字列は配置に使用されます。
    }
    else
    {
        $VMInfo = New-AzureVMEnvironment `
            -CloudServiceConfiguration $Config.cloudService `
            -VMPassword $VMPassword
    } 

    $connectionString = New-Object -TypeName Hashtable
    
    if ($Config.Contains('databases'))
    {
        @($Config.databases) |
            Where-Object {$_.connectionStringName -ne ''} |
            Add-AzureSQLDatabases -DatabaseServerPassword $DatabaseServerPassword -CreateDatabase:$Config.IsAzureWebSite |
            ForEach-Object { $connectionString.Add($_.Name, $_.ConnectionString) }           
    }
    
    return @{ConnectionString = $connectionString; VMInfo = $VMInfo}   
}

function Publish-AzureWebApplication
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [Object]
        $Config,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $ConnectionString,

        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [String]
        $WebDeployPackage,
        
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [Hashtable]
        $VMInfo           
    )

    if ($Config.IsAzureWebSite)
    {
        if ($ConnectionString -and $ConnectionString.Count -gt 0)
        {
            Publish-AzureWebsiteProject `
                -Name $Config.name `
                -Package $WebDeployPackage `
                -ConnectionString $ConnectionString
        }
        else
        {
            Publish-AzureWebsiteProject `
                -Name $Config.name `
                -Package $WebDeployPackage
        }
    }
    else
    {
        $waitingTime = $VMWebDeployWaitTime

        $result = $null
        $attempts = 0
        $allAttempts = 60
        do 
        {
            $result = Publish-WebPackageToVM `
                -VMDnsName $VMInfo.VMUrl `
                -IisWebApplicationName $Config.webDeployParameters.IisWebApplicationName `
                -WebDeployPackage $WebDeployPackage `
                -UserName $VMInfo.UserName `
                -UserPassword $VMInfo.Password `
                -AllowUntrusted:$AllowUntrusted `
                -ConnectionString $ConnectionString
             
            if ($result)
            {
                Write-VerboseWithTime ($scriptName + ' VM に発行できました。')
            }
            elseif ($VMInfo.IsNewCreatedVM -and !$Config.cloudService.virtualMachine.enableWebDeployExtension)
            {
                Write-VerboseWithTime ($scriptName + ' "enableWebDeployExtension" を $true に設定する必要があります。')
            }
            elseif (!$VMInfo.IsNewCreatedVM)
            {
                Write-VerboseWithTime ($scriptName + ' 既存の VM では Web Deploy をサポートしていません。')
            }
            else
            {
                Write-VerboseWithTime ($scriptName + " VM に発行できませんでした。$allAttempts 回中 $($attempts + 1) 回の試行です。")
                Write-VerboseWithTime ($scriptName + " $waitingTime 秒後に VM への発行を開始します。")
                
                Start-Sleep -Seconds $waitingTime
            }
             
             $attempts++
        
             #新しく作成し、Web Deploy をインストールしている仮想マシンにのみ再発行してください。 
        } While( !$result -and $VMInfo.IsNewCreatedVM -and $attempts -lt $allAttempts -and $Config.cloudService.virtualMachine.enableWebDeployExtension)
        
        if (!$result)
        {                    
            Write-Warning 'Publishing to the virtual machine failed. This can be caused by an untrusted or invalid certificate.  You can specify �AllowUntrusted to accept untrusted or invalid certificates.'
            throw ($scriptName + ' VM に発行できませんでした。')
        }
    }
}


# スクリプト メイン ルーチン
Set-StrictMode -Version 3

# 現在のバージョンの AzureWebAppPublishModule.psm1 モジュールをインポートします
Remove-Module AzureWebAppPublishModule -ErrorAction SilentlyContinue
$scriptDirectory = Split-Path -Parent $PSCmdlet.MyInvocation.MyCommand.Definition
Import-Module ($scriptDirectory + '\AzureWebAppPublishModule.psm1') -Scope Local -Verbose:$false

New-Variable -Name VMWebDeployWaitTime -Value 30 -Option Constant -Scope Script 
New-Variable -Name AzureWebAppPublishOutput -Value @() -Scope Global -Force
New-Variable -Name SendHostMessagesToOutput -Value $SendHostMessagesToOutput -Scope Global -Force

try
{
    $originalErrorActionPreference = $Global:ErrorActionPreference
    $originalVerbosePreference = $Global:VerbosePreference
    
    if ($PSBoundParameters['Verbose'])
    {
        $Global:VerbosePreference = 'Continue'
    }
    
    $scriptName = $MyInvocation.MyCommand.Name + ':'
    
    Write-VerboseWithTime ($scriptName + ' 開始')
    
    $Global:ErrorActionPreference = 'Stop'
    Write-VerboseWithTime ('{0} $ErrorActionPreference は {1} に設定されます' -f $scriptName, $ErrorActionPreference)
    
    Write-Debug ('{0}: $PSCmdlet.ParameterSetName = {1}' -f $scriptName, $PSCmdlet.ParameterSetName)

    # 現在のサブスクリプションを保存します。このスクリプトでは、後でサブスクリプションを Current ステータスに復元します
    Backup-Subscription -UserSpecifiedSubscription $SubscriptionName
    
    # Azure モジュール バージョン 0.7.4 以降があることを検証します。
    if (-not (Test-AzureModule))
    {
         throw '旧バージョンの Windows Azure PowerShell を使用しています。最新バージョンをインストールするには、http://go.microsoft.com/fwlink/?LinkID=320552 を参照してください。'
    }
    
    if ($SubscriptionName)
    {

        # サブスクリプション名を指定した場合は、アカウントにサブスクリプションが存在することを検証します。
        if (!(Get-AzureSubscription -SubscriptionName $SubscriptionName))
        {
            throw ("{0}: サブスクリプション名 $SubscriptionName が見つかりません" -f $scriptName)

        }

        # 指定されたサブスクリプションを現在のサブスクリプションに設定します。
        Select-AzureSubscription -SubscriptionName $SubscriptionName | Out-Null

        Write-VerboseWithTime ('{0}: サブスクリプションは {1} に設定されます' -f $scriptName, $SubscriptionName)
    }

    $Config = Read-ConfigFile $Configuration -HasWebDeployPackage:([Bool]$WebDeployPackage)

    #Web アプリケーションをビルドしてパッケージ化します
    #New-WebDeployPackage

    #Web アプリケーションで単体テストを実行します
    #Test-WebApplication

    #JSON 構成ファイルに示されている Azure 環境を作成します
    $newEnvironmentResult = New-AzureWebApplicationEnvironment -Config $Config -DatabaseServerPassword $DatabaseServerPassword -VMPassword $VMPassword

    #$WebDeployPackage がユーザーによって指定されている場合、Web アプリケーション パッケージを配置します 
    if($WebDeployPackage)
    {
        Publish-AzureWebApplication `
            -Config $Config `
            -ConnectionString $newEnvironmentResult.ConnectionString `
            -WebDeployPackage $WebDeployPackage `
            -VMInfo $newEnvironmentResult.VMInfo
    }
}
finally
{
    $Global:ErrorActionPreference = $originalErrorActionPreference
    $Global:VerbosePreference = $originalVerbosePreference

    # 元の現在のサブスクリプションを Current ステータスに復元します
    Restore-Subscription

    Write-Output $Global:AzureWebAppPublishOutput    
    $Global:AzureWebAppPublishOutput = @()
}
