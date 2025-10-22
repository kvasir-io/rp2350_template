# get-host-ip.ps1
# Detects and prints the host machine's IPv4 address.
# Exits with code 0 (success) if an IP found, otherwise prints 127.0.0.1 and exits 1.

try {
    # Find the default route(s) with a usable NextHop (exclude routes where NextHop is 0.0.0.0)
    $route = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
             Where-Object { $_.NextHop -and $_.NextHop -ne "0.0.0.0" } |
             Sort-Object -Property RouteMetric, ifIndex |
             Select-Object -First 1

    if ($null -ne $route) {
        $ifIndex = $route.InterfaceIndex

        # Try to get an IPv4 from that interface
        $addr = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.IPAddress -and
                    ($_.IPAddress -notlike "169.254.*") -and
                    ($_.IPAddress -ne "127.0.0.1")
                } |
                Select-Object -ExpandProperty IPAddress -First 1

        if ($addr) {
            Write-Output $addr
            exit 0
        }
    }

    # Fallback 1: pick any IPv4 address on an 'Up' adapter excluding virtual/link-local/loopback
    $addr = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -and
                ($_.IPAddress -notlike "169.254.*") -and
                ($_.IPAddress -ne "127.0.0.1")
            } |
            Where-Object {
                # get adapter status from index
                $ad = Get-NetAdapter -InterfaceIndex $_.InterfaceIndex -ErrorAction SilentlyContinue
                $ad -and $ad.Status -eq "Up"
            } |
            Select-Object -ExpandProperty IPAddress -First 1

    if ($addr) {
        Write-Output $addr
        exit 0
    }

    # Last resort: try any non-loopback IPv4 (even if adapter Down)
    $addr = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.IPAddress -and ($_.IPAddress -notlike "169.254.*") -and ($_.IPAddress -ne "127.0.0.1") } |
            Select-Object -ExpandProperty IPAddress -First 1

    if ($addr) {
        Write-Output $addr
        exit 0
    }
}
catch {
    # ignore and fall through to fallback
}

# Fallback to loopback if everything failed
Write-Output "127.0.0.1"
exit 1
