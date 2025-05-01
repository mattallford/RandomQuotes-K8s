# Look up the IP address of the NGINX ingress controller
$nginxServiceName = "ingress-nginx-controller"
$nginxNamespace = "ingress-nginx"

# Run kubectl to get the service details
$kubectlOutput = kubectl get svc $nginxServiceName -n $nginxNamespace -o json | ConvertFrom-Json
$nginxIP = $kubectlOutput.spec.clusterIP

if (-not $nginxIP) {
    Write-Host "Failed to retrieve the IP address of the NGINX ingress controller."
    exit 1
}

# Add the hostname to /etc/hosts
$hostEntry = "$nginxIP $($OctopusParameters["spec:rules:0:host"])"
Add-Content -Path "/etc/hosts" -Value $hostEntry
Write-Host "Added the following entry to /etc/hosts: $hostEntry"

# Perform the smoke test
$endpoint = "http://$($OctopusParameters["spec:rules:0:host"])"
Write-Host "Testing endpoint: $endpoint"

try {
    $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "Smoke test passed: Application is responding as expected."
        exit 0
    } else {
        Write-Host "Smoke test failed: Received status code $($response.StatusCode)."
        exit 1
    }
} catch {
    Write-Host "Smoke test failed: Unable to reach the endpoint. Error: $_"
    exit 1
}