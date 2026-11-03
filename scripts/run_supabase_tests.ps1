Write-Host "Running Supabase Database Tests via pgTAP..."
if (-not (Get-Command "supabase" -ErrorAction SilentlyContinue)) {
    Write-Error "Supabase CLI is not installed or not in PATH."
    exit 1
}

supabase test db
