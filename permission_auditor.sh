#!/bin/bash

LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/audit_$(date '+%Y-%m-%d_%H-%M-%S').log"

BASELINE_FILE="$LOG_DIR/baseline.txt"

CURRENT_FINDINGS=$(mktemp)
trap 'rm -f "$CURRENT_FINDINGS"' EXIT
exec > >(tee "$LOG_FILE") 2>&1

world_writable_count=0
suid_count=0
sgid_count=0

get_package() {
	local file="$1"
	dpkg-query -S "$file" 2>/dev/null | sed 's/: .*//' | head -n 1
}

echo "========================================="
echo " LINUX FILE PERMISSION AUDITOR"
echo "========================================"

scan_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "Scan Time: $scan_time"

echo ""
echo "[+] scanning for world-writable files..."
echo ""

 while read -r file

do
	((world_writable_count++))

	permissions=$(stat -c "%A" "$file")
	owner=$(stat -c "%U" "$file")
	group=$(stat -c "%G" "$file")
	
	echo "[HIGH] World-writable file detected"
	echo "WORLD-WRITABLE:$file" >> "$CURRENT_FINDINGS"
	echo "	File: $file"
	echo "	Permissions: $permissions"
	echo "	Owner: $owner"
	echo "	Group: $group"
	echo "	Risk: Other users can modify this file"
	echo ""
done < <(find "$HOME/file-permission-lab" "$HOME/linux-file-permission-auditor" -type f -perm -002 2>/dev/null)

echo ""
echo "[+] Scanning for SUID files..."
echo""

while read -r file

do
	((suid_count++))

	permissions=$(stat -c "%A" "$file")
	owner=$(stat -c "%U" "$file")
	group=$(stat -c "%G" "$file")

	echo "[REVIEW] SUID file detected"
	echo "SUID:$file" >> "$CURRENT_FINDINGS"
	echo "	File: $file"
	echo "	Permissions: $permissions"
	echo "	Owner: $owner"
	echo "	Group: $group"
	
	package=$(get_package "$file")

	if [ -n "$package" ]; then
		echo "	Package: $package"
		echo "	Status: Package-managed"
	else
		echo "	Package: UNMANAGED / UNKNOWN"
		echo "	Status: Investigate - unmanaged SUID file"
	fi

	echo "	Risk: Program can execute with the file owner's privileges" 
	echo ""
done < <(find /usr/bin /usr/local/bin -type f -perm -4000 2>/dev/null)

echo ""
echo "[+] Scanning for SGID files..."
echo ""

for file in $(find /usr/bin /usr/local/bin -type f -perm -2000 2>/dev/null);

do
	((sgid_count++))

	permissions=$(stat -c "%A" "$file")
	owner=$(stat -c "%U" "$file")
	group=$(stat -c "%G" "$file")

	package=$(get_package "$file")


	echo "[REVIEW] SGID file detected"
	echo "SGID:$file" >> "$CURRENT_FINDINGS"
	echo " 	File: $file"
	echo "	Permissions: $permissions"
	echo "	Owner: $owner"
	echo "	Group: $group"

	if [ -n "$package" ]; then
		echo "	Package: $package"
		echo "	Status: Package-managed"
	else
		echo "	Package: UNMANAGED / UNKNOWN"
		echo "	Status: Investigate - unmanaged SGID file"
	fi

	echo "	Risk: Program can execute with the file group's privileges" 
	echo ""
done< <(find /usr/bin /usr/local/bin -type f -perm -2000 2>/dev/null)



echo "=================================================="
echo "			AUDIT SUMMARY			"
echo "=================================================="
echo "World-writable files: $world_writable_count"
echo "SUID files:		$suid_count"
echo "SGID files:		$sgid_count"
echo "=================================================="


echo
echo "=================================================="
echo "                  CHANGE DETECTION"
echo "=================================================="

if [ ! -f "$BASELINE_FILE" ]; then
    echo "[+] No previous baseline found."
    echo "[+] Creating baseline from current scan..."
    sort -u "$CURRENT_FINDINGS" > "$BASELINE_FILE"
    chmod 600 "$BASELINE_FILE"
    echo "[+] Baseline created."
else
    echo "[+] Comparing current scan with previous baseline..."

    NEW_FINDINGS=$(comm -13 "$BASELINE_FILE" <(sort -u "$CURRENT_FINDINGS"))
    REMOVED_FINDINGS=$(comm -23 "$BASELINE_FILE" <(sort -u "$CURRENT_FINDINGS"))

    if [ -n "$NEW_FINDINGS" ]; then
        echo
        echo "[NEW] New findings detected:"
        echo "$NEW_FINDINGS"
    else
        echo "[+] No new findings detected."
    fi

    if [ -n "$REMOVED_FINDINGS" ]; then
        echo
        echo "[REMOVED] Findings no longer detected:"
        echo "$REMOVED_FINDINGS"
    else
        echo "[+] No findings were removed."
    fi

    sort -u "$CURRENT_FINDINGS" > "$BASELINE_FILE"
fi

echo "=================================================="
