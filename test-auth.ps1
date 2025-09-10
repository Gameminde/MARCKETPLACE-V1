Write-Host "🔐 Testing Auth Register Endpoint" -ForegroundColor Yellow

try {
    $body = @{
        email = "test@marketplace.dz"
        password = "TestPassword123!"
        firstName = "Test"
        lastName = "User"
    } | ConvertTo-Json

    Write-Host "Sending request to: http://localhost:3001/api/v1/auth/register" -ForegroundColor Cyan
    Write-Host "Body: $body" -ForegroundColor Cyan

    $response = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/auth/register" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
    
    Write-Host "✅ SUCCESS - Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ ERROR" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "Error Message: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response Body: $responseBody" -ForegroundColor Red
    }
}
