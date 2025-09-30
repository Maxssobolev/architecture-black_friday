#!/usr/bin/env bash
set -e

echo "[1/4] init Config Server RS (configRS)"
docker compose exec -T cfg1 mongosh --port 27017 --quiet <<'EOF'
rs.initiate({
  _id:"configRS",
  configsvr:true,
  members:[
    {_id:0,host:"cfg1:27017"},
    {_id:1,host:"cfg2:27017"},
    {_id:2,host:"cfg3:27017"}
  ]
})
EOF
sleep 5

echo "[2/4] init Shard1 RS (shard1RS)"
docker compose exec -T shard1-p mongosh --port 27018 --quiet <<'EOF'
rs.initiate({
  _id:"shard1RS",
  members:[
    {_id:0,host:"shard1-p:27018",priority:2},
    {_id:1,host:"shard1-s1:27018",priority:1},
    {_id:2,host:"shard1-s2:27018",priority:1}
  ]
})
EOF
sleep 5

echo "[3/4] init Shard2 RS (shard2RS)"
docker compose exec -T shard2-p mongosh --port 27019 --quiet <<'EOF'
rs.initiate({
  _id:"shard2RS",
  members:[
    {_id:0,host:"shard2-p:27019",priority:2},
    {_id:1,host:"shard2-s1:27019",priority:1},
    {_id:2,host:"shard2-s2:27019",priority:1}
  ]
})
EOF
sleep 5

echo "[4/4] add shards, enable sharding, shard somedb.helloDoc"
docker compose exec -T mongos mongosh --port 27020 --quiet <<'EOF'
sh.addShard("shard1RS/shard1-p:27018,shard1-s1:27018,shard1-s2:27018");
sh.addShard("shard2RS/shard2-p:27019,shard2-s1:27019,shard2-s2:27019");
use somedb;
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { user_id: "hashed" });
EOF
sleep 3

echo "DONE."
