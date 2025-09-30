docker compose up -d

# Инициализация CSRS
docker compose exec -T cfg1 mongosh --port 27017 --quiet <<EOF
rs.initiate({ _id: "configServerRS", members: [
  { _id: 0, host: "cfg1:27017" },
  { _id: 1, host: "cfg2:27017" },
  { _id: 2, host: "cfg3:27017"}
] })
EOF

# Инициализация шардов

docker compose exec -T shard1-p mongosh --port 27018 --quiet <<EOF
rs.initiate({ _id: "shard1RS", members: [
  { _id: 0, host: "shard1-p" },
  { _id: 1, host: "shard1-s1" },
  { _id: 2, host: "shard1-s2"}
] })
EOF

docker compose exec -T shard2-p mongosh --port 27019 --quiet <<EOF
rs.initiate({ _id: "shard2RS", members: [
  { _id: 0, host: "shard2-p" },
  { _id: 1, host: "shard2-s1" },
  { _id: 2, host: "shard2-s2"}
] })
EOF

# Подключение шардов

docker compose exec -T mongos mongosh --port 27020 --quiet <<EOF
sh.addShard("shard1RS/shard1-p:27018,shard1-s1:27018,shard1-s2:27018")
sh.addShard("shard2RS/shard2-p:27019,shard2-s1:27019,shard2-s2:27019")
EOF

# Включение шардирования для бд и коллекции

docker compose exec -it mongos mongosh --port 27020 --eval <<EOF
use somedb;
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { user_id: "hashed" });
EOF