Write-Host "Testing Auth Register" -ForegroundColor Yellow

$body = '{"email":"test@marketplace.dz","password":"TestPassword123!","firstName":"Test","lastName":"User"}'

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/auth/register" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
    Write-Host "SUCCESS - Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR - Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
