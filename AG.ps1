<#
.SYNOPSIS
AG命令 - 网络客户端-服务器时间同步工具

.DESCRIPTION
用于创建TCP服务器和客户端连接，实现时间信息的实时同步

.PARAMETER Server
以服务器模式启动，监听指定端口

.PARAMETER Client
以客户端模式启动，连接到指定服务器

.PARAMETER Port
指定使用的端口号（默认8080）

.PARAMETER Address
指定服务器IPv4地址（客户端模式下使用）

.EXAMPLE
AG -Server -Port 8080
以服务器模式启动，监听8080端口

.EXAMPLE
AG -Client -Address localhost -Port 8080
以客户端模式启动，连接到localhost:8080

.EXAMPLE
AG
启动交互式模式，可选择服务器或客户端模式

.NOTES
命令配置持久有效，系统重启后仍可正常使用
#>

param(
    [switch]$Server,
    [switch]$Client,
    [int]$Port = 8080,
    [string]$Address = "localhost"
)

# 获取脚本所在目录
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ExePath = Join-Path $ScriptPath "ChosEngine.exe"

# 检查可执行文件是否存在
if (-not (Test-Path $ExePath)) {
    Write-Error "找不到ChosEngine.exe可执行文件，路径: $ExePath"
    Write-Error "请确保已编译Go程序并生成可执行文件"
    exit 1
}

# 如果没有指定模式，启动交互式选择
if (-not $Server -and -not $Client) {
    Write-Host "========================================"
    Write-Host "      AG - 网络时间同步工具"
    Write-Host "========================================"
    Write-Host "请选择操作模式："
    Write-Host "1. 启动服务器模式"
    Write-Host "2. 启动客户端模式"
    Write-Host "3. 退出"
    Write-Host ""
    
    $choice = Read-Host -Prompt "请输入选择 (1-3)"
    
    switch ($choice) {
        "1" {
            $Server = $true
            $customPort = Read-Host -Prompt "请输入服务器监听端口 (默认: $Port)"
            if ($customPort -ne "") {
                $Port = [int]$customPort
            }
        }
        "2" {
            $Client = $true
            $customAddress = Read-Host -Prompt "请输入服务器地址 (默认: $Address)"
            if ($customAddress -ne "") {
                $Address = $customAddress
            }
            $customPort = Read-Host -Prompt "请输入服务器端口 (默认: $Port)"
            if ($customPort -ne "") {
                $Port = [int]$customPort
            }
        }
        "3" {
            Write-Host "退出程序"
            exit 0
        }
        default {
            Write-Error "无效的选择，请输入1-3之间的数字"
            exit 1
        }
    }
}

# 执行相应的模式
if ($Server) {
    Write-Host "以服务器模式启动，监听端口: $Port"
    & $ExePath $Port
} elseif ($Client) {
    Write-Host "以客户端模式启动，连接到: $Address:$Port"
    & $ExePath -c $Address $Port
}
