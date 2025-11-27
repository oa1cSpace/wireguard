# down container & wiping all artifacts

echo "Stopping container..."

docker compose -f ../wireguard-compose.yml down -v

echo "Container is down."

echo "Removing artifacts..."

rm -rf ../data

echo "Done!"
