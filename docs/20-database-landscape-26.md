# 26 Database & Engine — Peta Lab

Daftar 26 engine yang muncul di koneksi DBX / screenshot, dikelompokkan menurut peran. Repo-repo lab yang sesuai ada di akun [@devarent](https://github.com/devarent).

---

## Relational & distributed SQL (7)

| Engine | Karakter | Lab repo |
| --- | --- | --- |
| Firebird | Embedded/server SQL ringan | `firebird-lab` |
| IBM Db2 | Enterprise SQL | `ibm-db2-lab` |
| MariaDB | MySQL-compatible | `mariadb-practicum` |
| SQL Server | T-SQL, sqlcmd | `sql-server-lab` |
| CockroachDB | Distributed SQL, ranges | `cockroachdb-lab` |
| InterSystems IRIS | Multi-model SQL + JDBC | `intersystems-iris-lab` |
| JDBC | Koneksi Java ke PostgreSQL/H2 | `jdbc-lab` |

Termasuk juga MySQL, PostgreSQL, SQLite di badge wall.

## Cloud & analytics (8)

| Engine | Karakter | Lab repo |
| --- | --- | --- |
| Databricks SQL | Serverless warehouse, Delta, medallion | `databricks-sql-lab` |
| Snowflake | Warehouse, `COPY INTO`, time travel | `snowflake-lab` |
| Redshift | Data warehouse AWS | — |
| BigQuery | Serverless warehouse GCP | — |
| Teradata | Enterprise MPP | — |
| Vertica | Columnar MPP | — |
| Databend | Cloud-native warehouse (Rust) | — |
| Apache Kylin | OLAP cube | — |

## NoSQL & search (4)

| Engine | Karakter | Lab repo |
| --- | --- | --- |
| Redis | Key-value, cache, stream | `redis-lab` |
| MongoDB | Document, aggregation | `mongodb-practicum` |
| Cassandra | Wide-column, distributed | — |
| Elasticsearch | Full-text search | — |

## Vector & graph (3)

| Engine | Karakter | Lab repo |
| --- | --- | --- |
| Qdrant | Vector similarity search | `qdrant-lab` |
| ChromaDB | Vector DB untuk LLM/RAG | — |
| Neo4j | Property graph, Cypher | — |

## Streaming & time-series (4)

| Engine | Karakter | Lab repo |
| --- | --- | --- |
| Kafka | Event streaming | `kafka-lab` (jika ada) |
| VictoriaMetrics | Time-series metrik | — |
| InfluxDB | Time-series | — |
| TDengine | Time-series IoT | — |

**Total: 7 + 8 + 4 + 3 + 4 = 26 engine.**

---

## Windows multi-user advantages

- Remote Desktop Services (RDS) memungkinkan banyak user login bersamaan ke satu EC2 Windows.
- Profile per-user, folder redirects, dan quota.
- Untuk lab Linux/WSL2, multi-user diatur lewat `useradd` + `usermod -aG sudo` dan SSH key per-user.

## Pipeline EC2 + Docker

```text
Laptop (WSL2 Ubuntu)
   -> git push
   -> GitHub Actions (build + push image ke GHCR/ECR)
   -> SSH ke EC2 (IP publik / Tailscale)
   -> docker compose pull && docker compose up -d
   -> health check /health
   -> akses http://<PUBLIC_IP>
```

Lihat panduan lengkap:
- [`docs/01-ec2-launch.md`](01-ec2-launch.md)
- [`docs/02-docker-nginx.md`](02-docker-nginx.md)
- [`docs/04-terraform.md`](04-terraform.md)
- [`docs/05-cicd.md`](05-cicd.md)
- [`docs/17-wsl2-ubuntu-public-ip-setup.md`](17-wsl2-ubuntu-public-ip-setup.md)
