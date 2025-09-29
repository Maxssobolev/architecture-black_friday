#!/bin/bash

mongosh --host localhost --port 27020 <<EOF
use somedb
for (let i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({age: i, name: "ly" + i})
}
EOF

