# Azure Subscription Info Export Script

This PowerShell script retrieves all the Azure subscriptions associated with an Azure account and exports the subscription names and IDs to a CSV file. The output file is automatically named with the current date for easy tracking.

## Purpose

The script allows users to:
- Connect to their Azure account.
- Retrieve all available Azure subscriptions (name and ID).
- Export the subscription information into a CSV file.
- Dynamically name the CSV file based on the current date.

## Prerequisites

Before running the script, ensure the following:
- **Azure PowerShell Module** is installed. If not, you can install it using the command:
  ```powershell
  Install-Module -Name Az -AllowClobber -Force
  ```
- You have access to an **Azure account** and are authenticated with the necessary permissions to view subscriptions.

## How to Use

1. **Run the script in PowerShell**:
   Open PowerShell and execute the script to connect to Azure, retrieve the subscriptions, and export them to a CSV file.

2. **The CSV file will be named with today’s date**:
   The output file will be saved in the following directory:
   ```
   C:\path\to\file\directory\
   ```
   The file name will follow this pattern:
   ```
   SubscriptionInfo_yyyy-MM-dd.csv
   ```
   Example: `SubscriptionInfo_2024-09-25.csv`

### Script Breakdown

Here’s an overview of what the script does:

- **Connect to Azure**:
  ```powershell
  Connect-AzAccount
  ```
  This connects to your Azure account to retrieve the necessary subscription details.

- **Retrieve subscriptions**:
  ```powershell
  $subscriptions = Get-AzSubscription
  ```
  This line fetches all subscriptions linked to your account.

- **Loop through subscriptions and store info**:
  The script loops through each subscription, captures the name and ID, and stores it in a custom object.

- **Export to CSV**:
  ```powershell
  $subscriptionInfo | Export-Csv -Path $exportPath -NoTypeInformation
  ```
  This exports the collected subscription information to a CSV file with today’s date in the file name.

## Example Output

The exported CSV file will contain two columns:

| Subscription Name | Subscription ID                        |
|-------------------|----------------------------------------|
| Subscription1     | a1b2c3d4-1234-5678-9101-abcdef123456   |
| Subscription2     | e5f6g7h8-8765-4321-0987-abcdef987654   |

## Notes

- Make sure to adjust the file path in the script if necessary. By default, the CSV will be saved under:
  `C:\path\to\file\directory\`.
- The script dynamically appends today’s date to the file name to prevent overwriting previous files.

## Modifications

If you want to change the format of the date in the output file name, you can modify this line in the script:
```powershell
$date = Get-Date -Format "yyyy-MM-dd"
```
You can use different formats like `MM-dd-yyyy`, `ddMMyyyy`, etc., depending on your preference.

## License

This script is open-source and can be modified as needed. No license restrictions are applied.
