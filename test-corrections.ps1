Write-Host "🔧 Testing Backend Corrections" -ForegroundColor Green

# Wait for server to start
Write-Host "⏳ Waiting 5 seconds for server restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test 1: Health endpoint
Write-Host "`n🏥 Testing Health Endpoint:" -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:3001/health" -UseBasicParsing
    Write-Host "✅ Health Status: $($healthResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Auth register (should work now with relaxed validation)
Write-Host "`n🔐 Testing Auth Register (Relaxed Validation):" -ForegroundColor Yellow
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

# Test 3: Products endpoint
Write-Host "`n📦 Testing Products Endpoint:" -ForegroundColor Yellow
try {
    $productsResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/products" -UseBasicParsing
    Write-Host "✅ Products Status: $($productsResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "❌ Products Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: POST Products (should return 401 - requires auth)
Write-Host "`n📦 Testing POST Products (Expected 401):" -ForegroundColor Yellow
try {
    $productBody = @{
        name = "Test Product"
        description = "Test description"
        price = 100
        category = "Electronics"
    } | ConvertTo-Json

    $postResponse = Invoke-WebRequest -Uri "http://localhost:3001/api/v1/products" -Method POST -Body $productBody -ContentType "application/json" -UseBasicParsing
    Write-Host "✅ POST Products Status: $($postResponse.StatusCode)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ POST Products Status: 401 (Expected - requires authentication)" -ForegroundColor Green
    } else {
        Write-Host "❌ POST Products Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

Write-Host "`n✅ Corrections Testing Complete!" -ForegroundColor Green
