docker compose up -d

# Инициализация CSRS
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate({ _id: "configServerRS", members: [ { _id: 0, host: "configSrv:27017" } ] })
EOF

# Инициализация шардов

docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate({ _id: "shard1RS", members: [ { _id: 0, host: "shard1:27018" } ] })
EOF

docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate({ _id: "shard2RS", members: [ { _id: 0, host: "shard2:27019" } ] })
EOF

# Подключение шардов

docker compose exec -T mongos mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1RS/shard1:27018")
sh.addShard("shard2RS/shard2:27019")
EOF

# Включение шардирования для бд и коллекции

docker compose exec -it mongos mongosh --port 27020 --eval <<EOF
use somedb;
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { user_id: "hashed" });
EOF