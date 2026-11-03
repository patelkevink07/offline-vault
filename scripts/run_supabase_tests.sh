#!/usr/bin/env bash
set -euo pipefail

echo "Running Supabase Database Tests via pgTAP..."
if ! command -v supabase &> /dev/null; then
    echo "Supabase CLI is not installed or not in PATH."
    exit 1
fi

supabase test db
