Write-Host "🚀 Testing API with Relaxed Rate Limits" -ForegroundColor Green

# Wait for rate limit reset
Write-Host "⏳ Waiting 30 seconds for rate limit reset..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Test 1: Health endpoint
Write-Host "`n🏥 Testing Health Endpoint:" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing
    Write-Host "✅ Health Status: $($healthResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Products endpoint
Write-Host "`n📦 Testing Products Endpoint:" -ForegroundColor Yellow
try {
    $productsResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/products" -UseBasicParsing
    Write-Host "✅ Products Status: $($productsResponse.StatusCode)" -ForegroundColor Green
    Write-Host "Products Count: $($productsResponse.Content | ConvertFrom-Json | Select-Object -ExpandProperty data | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Products Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Auth register (single attempt)
Write-Host "`n🔐 Testing Auth Register (Single Attempt):" -ForegroundColor Yellow
try {
    $body = @{
        email = "test$(Get-Random)@marketplace.dz"
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
    }
}

# Test 4: Cart endpoint (should return 401 - requires auth)
Write-Host "`n🛒 Testing Cart Endpoint (Expected 401):" -ForegroundColor Yellow
try {
    $cartResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/cart" -UseBasicParsing
    Write-Host "✅ Cart Status: $($cartResponse.StatusCode)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ Cart Status: 401 (Expected - requires authentication)" -ForegroundColor Green
    } else {
        Write-Host "❌ Cart Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n✅ API Testing Complete!" -ForegroundColor Green
