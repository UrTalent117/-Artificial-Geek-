<#
.SYNOPSIS
AG Command - Network Client-Server Time Synchronization Tool

.DESCRIPTION
Used to create TCP server and client connections for real-time time information synchronization

.PARAMETER Server
Start in server mode, listen on specified port

.PARAMETER Client
Start in client mode, connect to specified server

.PARAMETER Port
Specify the port number to use (default 8080)

.PARAMETER Address
Specify server IPv4 address (used in client mode)

.EXAMPLE
AG -Server -Port 8080
Start in server mode, listen on port 8080

.EXAMPLE
AG -Client -Address localhost -Port 8080
Start in client mode, connect to localhost:8080

.EXAMPLE
AG
Start interactive mode, can choose server or client mode

.NOTES
Command configuration is persistent and will still work after system restart
#>

function AG {
    param(
        [switch]$Server,
        [switch]$Client,
        [int]$Port = 8080,
        [string]$Address = "localhost"
    )

    # Specify the path to ChosEngine.exe
    $ExePath = "f:\GolangWorkSpace\Snake\AG\ChosEngine.exe"

    # Check if the executable file exists
    if (-not (Test-Path $ExePath)) {
        Write-Error "Cannot find ChosEngine.exe executable, path: $ExePath"
        Write-Error "Please make sure the Go program is compiled and the executable file is generated"
        return
    }

    # If no mode is specified, start interactive selection
    if (-not $Server -and -not $Client) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "      AG - Network Time Sync Tool" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Please select operation mode:" -ForegroundColor White
        Write-Host "1. Start server mode"
        Write-Host "2. Start client mode"
        Write-Host "3. Exit"
        Write-Host ""
        
        $choice = Read-Host -Prompt "Please enter your choice (1-3)"
        
        switch ($choice) {
            "1" {
                $Server = $true
                $customPort = Read-Host -Prompt "Please enter server listening port (default: $Port)"
                if ($customPort -ne "") {
                    $Port = [int]$customPort
                }
            }
            "2" {
                $Client = $true
                $customAddress = Read-Host -Prompt "Please enter server address (default: $Address)"
                if ($customAddress -ne "") {
                    $Address = $customAddress
                }
                $customPort = Read-Host -Prompt "Please enter server port (default: $Port)"
                if ($customPort -ne "") {
                    $Port = [int]$customPort
                }
            }
            "3" {
                Write-Host "Exiting program" -ForegroundColor Green
                return
            }
            default {
                Write-Error "Invalid choice, please enter a number between 1-3"
                return
            }
        }
    }

    # Execute the corresponding mode
    if ($Server) {
        Write-Host "Starting in server mode, listening on port: $Port" -ForegroundColor Green
        & $ExePath $Port
    } elseif ($Client) {
        Write-Host "Starting in client mode, connecting to: ${Address}:${Port}" -ForegroundColor Green
        & $ExePath -c $Address $Port
    }
}

# Export the function
export-modulemember -function AG
