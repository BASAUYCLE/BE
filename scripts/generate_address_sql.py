"""
Script to download Vietnam administrative data from GitHub
and generate SQL INSERT statements for Provinces + Communes tables.
"""
import json
import urllib.request

PROVINCE_URL = "https://raw.githubusercontent.com/vietmap-company/vietnam_administrative_address/main/admin_new/province.json"
WARD_URL = "https://raw.githubusercontent.com/vietmap-company/vietnam_administrative_address/main/admin_new/ward.json"
OUTPUT_FILE = "address_data.sql"

def escape_sql(s):
    """Escape single quotes for SQL."""
    return s.replace("'", "''") if s else ""

def download_json(url):
    """Download JSON from URL."""
    print(f"Downloading {url} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as response:
        return json.loads(response.read().decode("utf-8"))

def main():
    # Download data
    provinces_data = download_json(PROVINCE_URL)
    wards_data = download_json(WARD_URL)

    print(f"Provinces: {len(provinces_data)}")
    print(f"Wards: {len(wards_data)}")

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        # Header
        f.write("-- ===========================================\n")
        f.write("-- Vietnam Administrative Data (auto-generated)\n")
        f.write("-- Source: github.com/vietmap-company/vietnam_administrative_address\n")
        f.write("-- ===========================================\n\n")

        # Create tables
        f.write("-- Create Provinces Table\n")
        f.write("CREATE TABLE Provinces (\n")
        f.write("    province_code VARCHAR(10) PRIMARY KEY,\n")
        f.write("    name NVARCHAR(100) NOT NULL,\n")
        f.write("    name_with_type NVARCHAR(150) NOT NULL,\n")
        f.write("    type VARCHAR(20) NOT NULL\n")
        f.write(");\n\n")

        f.write("-- Create Communes Table\n")
        f.write("CREATE TABLE Communes (\n")
        f.write("    commune_code VARCHAR(10) PRIMARY KEY,\n")
        f.write("    name NVARCHAR(100) NOT NULL,\n")
        f.write("    name_with_type NVARCHAR(150) NOT NULL,\n")
        f.write("    type VARCHAR(20) NOT NULL,\n")
        f.write("    province_code VARCHAR(10) NOT NULL,\n")
        f.write("    CONSTRAINT FK_Communes_Provinces FOREIGN KEY (province_code) REFERENCES Provinces(province_code)\n")
        f.write(");\n\n")

        # Insert provinces
        f.write("-- Insert Provinces\n")
        sorted_provinces = sorted(provinces_data.values(), key=lambda x: x["code"])
        for p in sorted_provinces:
            code = escape_sql(p["code"])
            name = escape_sql(p["name"])
            name_with_type = escape_sql(p["name_with_type"])
            ptype = escape_sql(p["type"])
            f.write(f"INSERT INTO Provinces (province_code, name, name_with_type, type) ")
            f.write(f"VALUES ('{code}', N'{name}', N'{name_with_type}', '{ptype}');\n")

        f.write(f"\n-- Total provinces: {len(sorted_provinces)}\n\n")

        # Insert wards/communes
        f.write("-- Insert Communes\n")
        sorted_wards = sorted(wards_data.values(), key=lambda x: (x["parent_code"], x["code"]))
        for w in sorted_wards:
            code = escape_sql(w["code"])
            name = escape_sql(w["name"])
            name_with_type = escape_sql(w["name_with_type"])
            wtype = escape_sql(w["type"])
            parent_code = escape_sql(w["parent_code"])
            f.write(f"INSERT INTO Communes (commune_code, name, name_with_type, type, province_code) ")
            f.write(f"VALUES ('{code}', N'{name}', N'{name_with_type}', '{wtype}', '{parent_code}');\n")

        f.write(f"\n-- Total communes: {len(sorted_wards)}\n")

    print(f"\nDone! SQL written to {OUTPUT_FILE}")
    print(f"  {len(sorted_provinces)} provinces")
    print(f"  {len(sorted_wards)} communes")

if __name__ == "__main__":
    main()
