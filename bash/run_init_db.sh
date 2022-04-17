#!/bin/bash
docker pull postgres
docker run --name psql_container -e POSTGRES_USER=test_sde -e POSTGRES_PASSWORD=@sde_password012 -e POSTGRES_DB=demo -v /$(pwd)/sql/init_db:/psql_container/scripts/ -p 5432:5432 -d postgres
sleep 20
docker exec psql_container bin/sh -c "psql -f /psql_container/scripts/demo.sql demo test_sde"
