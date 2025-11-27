# create requered directories and start container

echo "Creating 'data/' dir structure..."

mkdir -p ../data/{wireguard,keys,configs}

chmod +x ../scripts/*.sh

echo "'data/' dir is created."

echo "Startinng container..."

docker compose -f ../wireguard-compose.yml up -d
