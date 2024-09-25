# Connect to Azure
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Create an array to store the subscription information
$subscriptionInfo = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Retrieve the subscription details
    $subscriptionName = $subscription.Name
    $subscriptionId = $subscription.Id

    # Create a custom object with the subscription information
    $subscriptionObject = [PSCustomObject]@{
        'Subscription Name' = $subscriptionName
        'Subscription ID' = $subscriptionId
    }

    # Add the subscription object to the array
    $subscriptionInfo += $subscriptionObject
}

# Get today's date in "yyyy-MM-dd" format
$date = Get-Date -Format "yyyy-MM-dd"

# Define the export path with the current date in the file name
$exportPath = "C:\path\to\file\SubscriptionInfo_$date.csv"

# Export the subscription information to a CSV file
$subscriptionInfo | Export-Csv -Path $exportPath -NoTypeInformation

# Display the export path
Write-Host "Subscription information exported to: $exportPath"
