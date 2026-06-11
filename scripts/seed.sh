#!/bin/bash
# Vaulted — Dev Seed Script
# Creates realistic test data: 2 properties, floors, rooms, and items.
# Usage: ./seed.sh

set -e

BASE_URL="http://localhost:3000/api"
EMAIL="owner@test.com"
PASSWORD="Test1234abcDEF"

echo "🔐 Logging in..."
LOGIN_RESP=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  --data-raw "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data']['accessToken'])")

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed:"
  echo "$LOGIN_RESP"
  exit 1
fi

echo "✅ Token obtained"

AUTH="-H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\""

api() {
  local method=$1
  local path=$2
  local data=$3
  curl -s -X "$method" "$BASE_URL$path" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    ${data:+--data-raw "$data"}
}

echo ""
echo "🏠 Creating Property 1: Miami Mansion..."
PROP1=$(api POST /properties '{
  "name": "Miami Mansion",
  "type": "primary",
  "address": {
    "street": "1000 Ocean Drive",
    "city": "Miami Beach",
    "state": "FL",
    "zip": "33139",
    "country": "USA"
  }
}')
PROP1_ID=$(echo "$PROP1" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['_id'])")
echo "  ✅ Property 1 ID: $PROP1_ID"

echo ""
echo "🏢 Adding floors to Miami Mansion..."
FLOOR1=$(api POST "/properties/$PROP1_ID/floors" '{"name": "Ground Floor"}')
FLOOR1_ID=$(echo "$FLOOR1" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; f=[f for f in d['floors'] if f['name']=='Ground Floor'][-1]; print(f['floorId'])")
echo "  ✅ Ground Floor ID: $FLOOR1_ID"

FLOOR2=$(api POST "/properties/$PROP1_ID/floors" '{"name": "Second Floor"}')
FLOOR2_ID=$(echo "$FLOOR2" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; f=[f for f in d['floors'] if f['name']=='Second Floor'][-1]; print(f['floorId'])")
echo "  ✅ Second Floor ID: $FLOOR2_ID"

echo ""
echo "🚪 Adding rooms to Ground Floor..."
ROOM_LIVING=$(api POST "/properties/$PROP1_ID/floors/$FLOOR1_ID/rooms" '{"name": "Living Room", "type": "living_room"}')
ROOM_LIVING_ID=$(echo "$ROOM_LIVING" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Living Room'][-1]; print(rooms['roomId'])")
echo "  ✅ Living Room ID: $ROOM_LIVING_ID"

ROOM_DINING=$(api POST "/properties/$PROP1_ID/floors/$FLOOR1_ID/rooms" '{"name": "Dining Room", "type": "dining_room"}')
ROOM_DINING_ID=$(echo "$ROOM_DINING" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Dining Room'][-1]; print(rooms['roomId'])")
echo "  ✅ Dining Room ID: $ROOM_DINING_ID"

ROOM_KITCHEN=$(api POST "/properties/$PROP1_ID/floors/$FLOOR1_ID/rooms" '{"name": "Kitchen", "type": "kitchen"}')
ROOM_KITCHEN_ID=$(echo "$ROOM_KITCHEN" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Kitchen'][-1]; print(rooms['roomId'])")
echo "  ✅ Kitchen ID: $ROOM_KITCHEN_ID"

ROOM_WINE=$(api POST "/properties/$PROP1_ID/floors/$FLOOR1_ID/rooms" '{"name": "Wine Cellar", "type": "wine_cellar"}')
ROOM_WINE_ID=$(echo "$ROOM_WINE" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Wine Cellar'][-1]; print(rooms['roomId'])")
echo "  ✅ Wine Cellar ID: $ROOM_WINE_ID"

echo ""
echo "🚪 Adding rooms to Second Floor..."
ROOM_MASTER=$(api POST "/properties/$PROP1_ID/floors/$FLOOR2_ID/rooms" '{"name": "Master Bedroom", "type": "bedroom"}')
ROOM_MASTER_ID=$(echo "$ROOM_MASTER" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Master Bedroom'][-1]; print(rooms['roomId'])")
echo "  ✅ Master Bedroom ID: $ROOM_MASTER_ID"

ROOM_OFFICE=$(api POST "/properties/$PROP1_ID/floors/$FLOOR2_ID/rooms" '{"name": "Home Office", "type": "office"}')
ROOM_OFFICE_ID=$(echo "$ROOM_OFFICE" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Home Office'][-1]; print(rooms['roomId'])")
echo "  ✅ Home Office ID: $ROOM_OFFICE_ID"

echo ""
echo "📦 Creating items in Living Room..."

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_LIVING_ID\",
  \"name\": \"Chesterfield Sofa\",
  \"category\": \"furniture\",
  \"subcategory\": \"living room\",
  \"status\": \"active\",
  \"serialNumber\": \"CHEST-001\",
  \"valuation\": { \"purchasePrice\": 18000, \"currentValue\": 15000, \"currency\": \"USD\" },
  \"tags\": [\"leather\", \"victorian\", \"antique\"]
}" > /dev/null && echo "  ✅ Chesterfield Sofa"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_LIVING_ID\",
  \"name\": \"Picasso Lithograph — Femme au Chapeau\",
  \"category\": \"art\",
  \"subcategory\": \"prints\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 85000, \"currentValue\": 110000, \"currency\": \"USD\" },
  \"tags\": [\"picasso\", \"lithograph\", \"1962\"]
}" > /dev/null && echo "  ✅ Picasso Lithograph"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_LIVING_ID\",
  \"name\": \"Bösendorfer Imperial Grand Piano\",
  \"category\": \"other\",
  \"subcategory\": \"musical instruments\",
  \"status\": \"active\",
  \"serialNumber\": \"BOS-97423\",
  \"valuation\": { \"purchasePrice\": 220000, \"currentValue\": 195000, \"currency\": \"USD\" },
  \"tags\": [\"piano\", \"bosendorfer\", \"concert\"]
}" > /dev/null && echo "  ✅ Bösendorfer Grand Piano"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_LIVING_ID\",
  \"name\": \"Samsung 98\\\" The Wall MicroLED\",
  \"category\": \"technology\",
  \"subcategory\": \"displays\",
  \"status\": \"active\",
  \"serialNumber\": \"SAM-WALL-2024\",
  \"valuation\": { \"purchasePrice\": 130000, \"currentValue\": 95000, \"currency\": \"USD\" },
  \"tags\": [\"tv\", \"microled\", \"samsung\"]
}" > /dev/null && echo "  ✅ Samsung MicroLED TV"

echo ""
echo "📦 Creating items in Dining Room..."

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_DINING_ID\",
  \"name\": \"Hermès Limoges Dinnerware Set (24 pcs)\",
  \"category\": \"other\",
  \"subcategory\": \"tableware\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 28000, \"currentValue\": 32000, \"currency\": \"USD\" },
  \"tags\": [\"hermes\", \"porcelain\", \"limoges\"]
}" > /dev/null && echo "  ✅ Hermès Dinnerware"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_DINING_ID\",
  \"name\": \"Christofle Malmaison Silver Flatware (12 pcs)\",
  \"category\": \"other\",
  \"subcategory\": \"flatware\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 12500, \"currentValue\": 14000, \"currency\": \"USD\" },
  \"tags\": [\"christofle\", \"silver\", \"sterling\"]
}" > /dev/null && echo "  ✅ Christofle Flatware"

echo ""
echo "📦 Creating items in Wine Cellar..."

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_WINE_ID\",
  \"name\": \"Château Pétrus 2015 (6 bottles)\",
  \"category\": \"wine\",
  \"subcategory\": \"bordeaux\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 18000, \"currentValue\": 24000, \"currency\": \"USD\" },
  \"tags\": [\"petrus\", \"pomerol\", \"2015\", \"bordeaux\"]
}" > /dev/null && echo "  ✅ Château Pétrus 2015"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_WINE_ID\",
  \"name\": \"Opus One 2019 (12 bottles)\",
  \"category\": \"wine\",
  \"subcategory\": \"napa valley\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 4800, \"currentValue\": 5400, \"currency\": \"USD\" },
  \"tags\": [\"opus-one\", \"napa\", \"2019\", \"cabernet\"]
}" > /dev/null && echo "  ✅ Opus One 2019"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_WINE_ID\",
  \"name\": \"Macallan 30 Year Single Malt (3 bottles)\",
  \"category\": \"wine\",
  \"subcategory\": \"whisky\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 9000, \"currentValue\": 11500, \"currency\": \"USD\" },
  \"tags\": [\"macallan\", \"scotch\", \"30yr\", \"whisky\"]
}" > /dev/null && echo "  ✅ Macallan 30 Year"

echo ""
echo "📦 Creating items in Master Bedroom..."

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_MASTER_ID\",
  \"name\": \"Patek Philippe Nautilus 5711 (Steel)\",
  \"category\": \"wardrobe\",
  \"subcategory\": \"watches\",
  \"status\": \"active\",
  \"serialNumber\": \"PP-5711-4521\",
  \"valuation\": { \"purchasePrice\": 35000, \"currentValue\": 120000, \"currency\": \"USD\" },
  \"tags\": [\"patek\", \"nautilus\", \"5711\", \"watch\"]
}" > /dev/null && echo "  ✅ Patek Philippe Nautilus"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_MASTER_ID\",
  \"name\": \"Rolex Daytona 116500LN White Dial\",
  \"category\": \"wardrobe\",
  \"subcategory\": \"watches\",
  \"status\": \"active\",
  \"serialNumber\": \"RLX-DAY-8832\",
  \"valuation\": { \"purchasePrice\": 14000, \"currentValue\": 38000, \"currency\": \"USD\" },
  \"tags\": [\"rolex\", \"daytona\", \"watch\", \"panda\"]
}" > /dev/null && echo "  ✅ Rolex Daytona"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_MASTER_ID\",
  \"name\": \"Hermès Birkin 35 Togo Gold\",
  \"category\": \"wardrobe\",
  \"subcategory\": \"bags\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 12000, \"currentValue\": 28000, \"currency\": \"USD\" },
  \"tags\": [\"hermes\", \"birkin\", \"togo\", \"bag\"]
}" > /dev/null && echo "  ✅ Hermès Birkin"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_MASTER_ID\",
  \"name\": \"Van Cleef & Arpels Alhambra Necklace\",
  \"category\": \"wardrobe\",
  \"subcategory\": \"jewelry\",
  \"status\": \"active\",
  \"serialNumber\": \"VCA-ALH-2022\",
  \"valuation\": { \"purchasePrice\": 8500, \"currentValue\": 11000, \"currency\": \"USD\" },
  \"tags\": [\"van-cleef\", \"alhambra\", \"gold\", \"necklace\"]
}" > /dev/null && echo "  ✅ Van Cleef Necklace"

echo ""
echo "📦 Creating items in Home Office..."

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_OFFICE_ID\",
  \"name\": \"Apple Mac Pro M3 Ultra\",
  \"category\": \"technology\",
  \"subcategory\": \"computers\",
  \"status\": \"active\",
  \"serialNumber\": \"APL-MP-M3U-001\",
  \"valuation\": { \"purchasePrice\": 9999, \"currentValue\": 8500, \"currency\": \"USD\" },
  \"tags\": [\"apple\", \"mac-pro\", \"m3\"]
}" > /dev/null && echo "  ✅ Mac Pro M3 Ultra"

api POST /items "{
  \"propertyId\": \"$PROP1_ID\",
  \"roomId\": \"$ROOM_OFFICE_ID\",
  \"name\": \"Herman Miller Embody Chair (Logitech Edition)\",
  \"category\": \"furniture\",
  \"subcategory\": \"office\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 2200, \"currentValue\": 1800, \"currency\": \"USD\" },
  \"tags\": [\"herman-miller\", \"ergonomic\", \"chair\"]
}" > /dev/null && echo "  ✅ Herman Miller Chair"

echo ""
echo "🏠 Creating Property 2: Aspen Chalet..."
PROP2=$(api POST /properties '{
  "name": "Aspen Chalet",
  "type": "vacation",
  "address": {
    "street": "500 Mountain Road",
    "city": "Aspen",
    "state": "CO",
    "zip": "81611",
    "country": "USA"
  }
}')
PROP2_ID=$(echo "$PROP2" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['_id'])")
echo "  ✅ Property 2 ID: $PROP2_ID"

echo ""
echo "🏢 Adding floor to Aspen Chalet..."
FLOOR_ASPEN=$(api POST "/properties/$PROP2_ID/floors" '{"name": "Main Level"}')
FLOOR_ASPEN_ID=$(echo "$FLOOR_ASPEN" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; f=[f for f in d['floors'] if f['name']=='Main Level'][-1]; print(f['floorId'])")
echo "  ✅ Main Level ID: $FLOOR_ASPEN_ID"

echo ""
echo "🚪 Adding rooms to Aspen Main Level..."
ROOM_CHALET=$(api POST "/properties/$PROP2_ID/floors/$FLOOR_ASPEN_ID/rooms" '{"name": "Great Room", "type": "living_room"}')
ROOM_CHALET_ID=$(echo "$ROOM_CHALET" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Great Room'][-1]; print(rooms['roomId'])")
echo "  ✅ Great Room ID: $ROOM_CHALET_ID"

ROOM_GARAGE=$(api POST "/properties/$PROP2_ID/floors/$FLOOR_ASPEN_ID/rooms" '{"name": "Garage", "type": "garage"}')
ROOM_GARAGE_ID=$(echo "$ROOM_GARAGE" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; floors=d['floors']; rooms=[r for f in floors for r in f['rooms'] if r['name']=='Garage'][-1]; print(rooms['roomId'])")
echo "  ✅ Garage ID: $ROOM_GARAGE_ID"

echo ""
echo "📦 Creating items in Aspen Great Room..."

api POST /items "{
  \"propertyId\": \"$PROP2_ID\",
  \"roomId\": \"$ROOM_CHALET_ID\",
  \"name\": \"Restoration Hardware Cloud Sectional\",
  \"category\": \"furniture\",
  \"subcategory\": \"living room\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 22000, \"currentValue\": 18000, \"currency\": \"USD\" },
  \"tags\": [\"rh\", \"sectional\", \"cloud\", \"sofa\"]
}" > /dev/null && echo "  ✅ RH Cloud Sectional"

echo ""
echo "📦 Creating items in Aspen Garage..."

api POST /items "{
  \"propertyId\": \"$PROP2_ID\",
  \"roomId\": \"$ROOM_GARAGE_ID\",
  \"name\": \"Ferrari SF90 Stradale\",
  \"category\": \"vehicles\",
  \"subcategory\": \"sports cars\",
  \"status\": \"active\",
  \"serialNumber\": \"ZFF90SFA000280001\",
  \"valuation\": { \"purchasePrice\": 510000, \"currentValue\": 580000, \"currency\": \"USD\" },
  \"tags\": [\"ferrari\", \"sf90\", \"hybrid\", \"supercar\"]
}" > /dev/null && echo "  ✅ Ferrari SF90"

api POST /items "{
  \"propertyId\": \"$PROP2_ID\",
  \"roomId\": \"$ROOM_GARAGE_ID\",
  \"name\": \"Range Rover Autobiography LWB\",
  \"category\": \"vehicles\",
  \"subcategory\": \"SUVs\",
  \"status\": \"active\",
  \"serialNumber\": \"SALGA2RE5PA001234\",
  \"valuation\": { \"purchasePrice\": 185000, \"currentValue\": 162000, \"currency\": \"USD\" },
  \"tags\": [\"range-rover\", \"autobiography\", \"suv\"]
}" > /dev/null && echo "  ✅ Range Rover Autobiography"

api POST /items "{
  \"propertyId\": \"$PROP2_ID\",
  \"roomId\": \"$ROOM_GARAGE_ID\",
  \"name\": \"Ski Equipment Set — Blizzard Bonafide 97\",
  \"category\": \"sports\",
  \"subcategory\": \"skiing\",
  \"status\": \"active\",
  \"valuation\": { \"purchasePrice\": 3200, \"currentValue\": 2400, \"currency\": \"USD\" },
  \"tags\": [\"ski\", \"blizzard\", \"winter\", \"sports\"]
}" > /dev/null && echo "  ✅ Ski Equipment"

echo ""
echo "🎉 Seed complete!"
echo ""
echo "Summary:"
echo "  🏠 Miami Mansion ($PROP1_ID)"
echo "     • Ground Floor: Living Room, Dining Room, Kitchen, Wine Cellar"
echo "     • Second Floor: Master Bedroom, Home Office"
echo "     • 15 items (~\$800k total value)"
echo ""
echo "  🏔️  Aspen Chalet ($PROP2_ID)"
echo "     • Main Level: Great Room, Garage"
echo "     • 4 items (~\$762k total value)"
echo ""
echo "  Login: owner@test.com / Test1234abcDEF"
