#!/usr/bin/env pwsh
# Move-UsersToEST.ps1
# Script to move all Microsoft 365 users and mailboxes to Eastern Standard Time (EST) timezone
# For use on macOS with PowerShell Core, Exchange Online module, and Microsoft Graph PowerShell SDK

# Parameters that can be adjusted if needed
param(
    [string]$TargetTimeZone = "Eastern Standard Time",
    [switch]$WhatIf = $false,
    [switch]$SkipMailboxes = $false,
    [switch]$SkipUsers = $false,
    [string[]]$ExcludeUsers = @(),  # Users to exclude from processing
    [switch]$ContinueOnError = $true,  # Continue processing even if errors occur
    [switch]$ExportFailedUsersOnly = $false  # Only export users that couldn't be updated
)

# Function to ensure required modules are available
function Ensure-ModulesAvailable {
    $requiredModules = @(
        @{Name = "ExchangeOnlineManagement"; MinimumVersion = "2.0.5"},
        @{Name = "Microsoft.Graph.Users"; MinimumVersion = "1.0.0"},
        @{Name = "Microsoft.Graph.Authentication"; MinimumVersion = "1.0.0"}
    )
    
    foreach ($module in $requiredModules) {
        if (!(Get-Module -ListAvailable -Name $module.Name | Where-Object {$_.Version -ge $module.MinimumVersion})) {
            Write-Host "Installing $($module.Name) module..." -ForegroundColor Yellow
            Install-Module -Name $module.Name -Scope CurrentUser -Force -AllowClobber
        }
        else {
            Write-Host "$($module.Name) module is already installed." -ForegroundColor Green
        }
    }
}

# Function to connect to Microsoft 365 services
function Connect-ToMicrosoft365 {
    # Connect to Exchange Online
    try {
        Get-EXOMailbox -ResultSize 1 -ErrorAction Stop | Out-Null
        Write-Host "Already connected to Exchange Online." -ForegroundColor Green
    }
    catch {
        Write-Host "Connecting to Exchange Online..." -ForegroundColor Yellow
        Connect-ExchangeOnline -ShowBanner:$false
    }
    
    # Connect to Microsoft Graph (Entra ID)
    try {
        Get-MgUser -Top 1 -ErrorAction Stop | Out-Null
        Write-Host "Already connected to Microsoft Entra ID via Graph API." -ForegroundColor Green
    }
    catch {
        Write-Host "Connecting to Microsoft Entra ID via Graph API..." -ForegroundColor Yellow
        # Ensure we're using beta profile for mailbox settings
        Select-MgProfile -Name "beta"
        Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "MailboxSettings.ReadWrite" -NoWelcome
    }
}

# Function to process mailboxes in Exchange Online
function Process-Mailboxes {
    Write-Host "Processing Microsoft 365 mailboxes..." -ForegroundColor Cyan
    
    # Get all mailboxes
    $mailboxes = Get-EXOMailbox -ResultSize Unlimited
    $mailboxCount = $mailboxes.Count
    $processed = 0
    $changed = 0
    
    Write-Host "Found $mailboxCount mailboxes to process." -ForegroundColor Cyan
    
    foreach ($mailbox in $mailboxes) {
        $processed++
        Write-Progress -Activity "Processing Microsoft 365 Mailboxes" -Status "Processing $($mailbox.DisplayName) ($processed of $mailboxCount)" -PercentComplete (($processed / $mailboxCount) * 100)
        
        # Get current timezone
        $config = Get-MailboxRegionalConfiguration -Identity $mailbox.Identity
        $currentTimeZone = $config.TimeZone
        
        if ($currentTimeZone -eq $TargetTimeZone) {
            Write-Host "Mailbox '$($mailbox.DisplayName)' already set to $TargetTimeZone. Skipping." -ForegroundColor Green
        }
        else {
            try {
                if ($WhatIf) {
                    Write-Host "WhatIf: Would change mailbox '$($mailbox.DisplayName)' from '$currentTimeZone' to '$TargetTimeZone'" -ForegroundColor Yellow
                }
                else {
                    Set-MailboxRegionalConfiguration -Identity $mailbox.Identity -TimeZone $TargetTimeZone -ErrorAction Stop
                    Write-Host "Changed mailbox '$($mailbox.DisplayName)' from '$currentTimeZone' to '$TargetTimeZone'" -ForegroundColor Yellow
                }
                $changed++
            }
            catch {
                Write-Host "Error changing timezone for mailbox '$($mailbox.DisplayName)': $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "Mailbox processing complete. Total: $mailboxCount, Changed: $changed" -ForegroundColor Cyan
}

# Function to process Microsoft Entra ID user accounts
function Process-EntraUsers {
    Write-Host "Processing Microsoft Entra ID user accounts..." -ForegroundColor Cyan
    
    try {
        # Get all users from Microsoft Entra ID (fixing the property selection)
        $users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName
        $userCount = $users.Count
        $processed = 0
        $changed = 0
        
        Write-Host "Found $userCount user accounts to process." -ForegroundColor Cyan
        
        foreach ($user in $users) {
            $processed++
            Write-Progress -Activity "Processing Microsoft Entra ID Users" -Status "Processing $($user.DisplayName) ($processed of $userCount)" -PercentComplete (($processed / $userCount) * 100)
            
            # Initialize currentTimeZone variable
            $currentTimeZone = $null
            
            # Attempt to get current timezone
            try {
                $userMailboxSettings = Get-MgUserMailboxSetting -UserId $user.Id -ErrorAction SilentlyContinue
                $currentTimeZone = $userMailboxSettings.TimeZone
            }
            catch {
                Write-Host "Could not retrieve timezone for user '$($user.DisplayName)': $_" -ForegroundColor Yellow
                continue
            }
            
            if ([string]::IsNullOrEmpty($currentTimeZone)) {
                Write-Host "User '$($user.DisplayName)' has no timezone setting. Will set to $TargetTimeZone." -ForegroundColor Yellow
            }
            elseif ($currentTimeZone -eq $TargetTimeZone) {
                Write-Host "User '$($user.DisplayName)' already set to $TargetTimeZone. Skipping." -ForegroundColor Green
                continue
            }
            
            # Update the timezone if needed
            try {
                if ($WhatIf) {
                    Write-Host "WhatIf: Would change user '$($user.DisplayName)' from '$currentTimeZone' to '$TargetTimeZone'" -ForegroundColor Yellow
                }
                else {
                    $params = @{
                        TimeZone = $TargetTimeZone
                    }
                    
                    Update-MgUserMailboxSetting -UserId $user.Id -BodyParameter $params -ErrorAction Stop
                    Write-Host "Changed user '$($user.DisplayName)' from '$currentTimeZone' to '$TargetTimeZone'" -ForegroundColor Yellow
                }
                $changed++
            }
            catch {
                Write-Host "Error changing timezone for user '$($user.DisplayName)': $_" -ForegroundColor Red
            }
        }
        
        Write-Host "Microsoft Entra ID user processing complete. Total: $userCount, Changed: $changed" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error retrieving users from Microsoft Entra ID: $_" -ForegroundColor Red
    }
}

# Generate a report of users and their timezones
function Generate-Report {
    $reportPath = Join-Path -Path $PWD -ChildPath "TimeZoneReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    
    Write-Host "Generating timezone report to $reportPath..." -ForegroundColor Cyan
    
    try {
        $report = @()
        
        # Get all mailboxes (excluding guests)
        $mailboxes = Get-EXOMailbox -ResultSize Unlimited | Where-Object {$_.RecipientTypeDetails -ne "GuestMailUser"}
        
        foreach ($mailbox in $mailboxes) {
            # Get mailbox timezone
            $mailboxTimezone = "N/A"
            try {
                $config = Get-MailboxRegionalConfiguration -Identity $mailbox.Identity -ErrorAction SilentlyContinue
                if ($config) {
                    $mailboxTimezone = $config.TimeZone
                }
            }
            catch {
                # Just continue if we can't get mailbox info
            }
            
            # Add to report
            $report += [PSCustomObject]@{
                DisplayName = $mailbox.DisplayName
                UserPrincipalName = $mailbox.UserPrincipalName
                Email = $mailbox.PrimarySmtpAddress
                MailboxTimeZone = $mailboxTimezone
                IsEST = ($mailboxTimezone -eq $TargetTimeZone)
            }
        }
        
        # Export to CSV
        $report | Export-Csv -Path $reportPath -NoTypeInformation
        
        Write-Host "Report generated successfully at $reportPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Error generating report: $_" -ForegroundColor Red
    }
}

# Main script execution
function Main {
    Write-Host "Starting Microsoft 365 timezone synchronization process..." -ForegroundColor Cyan
    Write-Host "Target Timezone: $TargetTimeZone" -ForegroundColor Cyan
    
    # Check if we're running on macOS
    if ($IsMacOS) {
        Write-Host "Running on macOS." -ForegroundColor Green
    }
    else {
        Write-Host "Warning: This script was intended for macOS. Current OS: $($PSVersionTable.OS)" -ForegroundColor Yellow
    }
    
    # Ensure modules are available
    Ensure-ModulesAvailable
    
    # Connect to Microsoft 365 services
    Connect-ToMicrosoft365
    
    # Process mailboxes if not skipped
    if (!$SkipMailboxes) {
        Process-Mailboxes
    }
    
    # Process users if not skipped
    if (!$SkipUsers) {
        Process-EntraUsers
    }
    
    # Generate report
    Generate-Report
    
    # Export failed users to CSV
    if ($global:PermissionErrorMailboxes -and $global:PermissionErrorMailboxes.Count -gt 0) {
        $failedUsersPath = Join-Path -Path $PWD -ChildPath "FailedUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $global:PermissionErrorMailboxes | Export-Csv -Path $failedUsersPath -NoTypeInformation
        
        Write-Host "`nThe following mailboxes could not be updated due to errors:" -ForegroundColor Red
        $global:PermissionErrorMailboxes | ForEach-Object {
            Write-Host " - $($_.DisplayName) ($($_.UserPrincipalName)): $($_.ErrorMessage)" -ForegroundColor Red
        }
        
        Write-Host "`nExclusion list for next run (copy to clipboard):" -ForegroundColor Yellow
        $exclusionList = $global:PermissionErrorMailboxes | ForEach-Object { "'$($_.UserPrincipalName)'" }
        $exclusionString = "@(" + ($exclusionList -join ", ") + ")"
        Write-Host $exclusionString -ForegroundColor Yellow
        
        Write-Host "`nTo update these mailboxes, you may need to:" -ForegroundColor Yellow
        Write-Host " 1. Use an account with higher privileges (e.g., Global Admin)" -ForegroundColor Yellow
        Write-Host " 2. Add these users to the -ExcludeUsers parameter in your next run" -ForegroundColor Yellow
        Write-Host " 3. Check if these mailboxes have special configurations or policies" -ForegroundColor Yellow
        Write-Host " 4. Consider using Exchange Admin Center to manually update these mailboxes" -ForegroundColor Yellow
        Write-Host "`nA CSV file with failed users has been saved to: $failedUsersPath" -ForegroundColor Yellow
    }
    
    Write-Host "Microsoft 365 timezone synchronization complete!" -ForegroundColor Green
    Write-Host "A report of all users and their timezone settings has been saved to the current directory." -ForegroundColor Green
}

# Execute the main function
Main