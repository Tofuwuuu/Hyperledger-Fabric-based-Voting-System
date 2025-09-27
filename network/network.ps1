# Helper function to run bash commands in Git Bash
function Invoke-BashCommand {
    param(
        [string]$Command
    )
    # Using Git Bash if available, otherwise fallback to WSL
    if (Test-Path "C:\Program Files\Git\bin\bash.exe") {
        & "C:\Program Files\Git\bin\bash.exe" -c $Command
    } else {
        Write-Host "Git Bash not found. Please install Git for Windows or use WSL."
        exit 1
    }
}

# Set environment variables
$env:MSYS_NO_PATHCONV = "1"
$env:COMPOSE_CONVERT_WINDOWS_PATHS = "1"

# Parse command line arguments
$mode = $args[0]
$remainingArgs = $args[1..($args.Length-1)]

# Convert arguments to bash-compatible format
$bashArgs = $remainingArgs -join ' '

# Determine the network script path
$scriptPath = "$PSScriptRoot\network.sh"
$bashScriptPath = $scriptPath.Replace('\', '/')

switch ($mode) {
    "up" {
        Write-Host "Starting the network..."
        Invoke-BashCommand "./network.sh up $bashArgs"
    }
    "down" {
        Write-Host "Stopping the network..."
        Invoke-BashCommand "./network.sh down $bashArgs"
    }
    "createChannel" {
        Write-Host "Creating channel..."
        Invoke-BashCommand "./network.sh createChannel $bashArgs"
    }
    "deployCC" {
        Write-Host "Deploying chaincode..."
        Invoke-BashCommand "./network.sh deployCC $bashArgs"
    }
    default {
        Write-Host "Usage: network.ps1 <mode> [flags]"
        Write-Host "Modes: "
        Write-Host "  up - Bring up the network"
        Write-Host "  down - Bring down the network"
        Write-Host "  createChannel - Create and join a channel"
        Write-Host "  deployCC - Deploy chaincode"
        exit 1
    }
}