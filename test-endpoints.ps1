Write-Host "🚀 Testing Backend API Endpoints" -ForegroundColor Green

# Test 1: Health endpoint
Write-Host "`n🏥 Testing Health Endpoint:" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing
    Write-Host "✅ Health Status: $($healthResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($healthResponse.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Health Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Auth register endpoint
Write-Host "`n🔐 Testing Auth Register Endpoint:" -ForegroundColor Yellow
try {
    $body = @{
        email = "test@marketplace.dz"
        password = "TestPassword123!"
        firstName = "Test"
        lastName = "User"
    } | ConvertTo-Json

    $authResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/auth/register" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
    Write-Host "✅ Auth Register Status: $($authResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($authResponse.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Auth Register Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Error Response: $responseBody" -ForegroundColor Red
    }
}

# Test 3: Products endpoint
Write-Host "`n📦 Testing Products Endpoint:" -ForegroundColor Yellow
try {
    $productsResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/products" -UseBasicParsing
    Write-Host "✅ Products Status: $($productsResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($productsResponse.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Products Error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

Write-Host "`n✅ API Testing Complete!" -ForegroundColor Green
