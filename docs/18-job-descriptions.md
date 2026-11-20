# Job Descriptions — Target Role (DevOps · Backend · QA)

Kumpulan deskripsi pekerjaan yang jadi acuan lab ini. Dipakai untuk memetakan skill yang dilatih di repo `aws-ec2-web-hosting-part-1` dan repo lab lainnya.

---

## 1. DevOps Engineer

**Key responsibilities**
- Design, implement, dan maintain pipeline CI/CD (integrasi, build, test, deploy, release).
- Automate build, testing, deployment, dan release process.
- Manage cloud infrastructure (AWS, Azure, GCP).
- Monitor system performance, availability, reliability; troubleshooting insiden.
- Implement IaC dengan Terraform / CloudFormation.
- Manage containerization & orchestration (Docker, Kubernetes EKS/ACK/GKE/vanilla, Helm).
- Security, compliance, best practice di dev & production.
- Configure monitoring & logging (Prometheus, Grafana, ELK/OpenSearch, Datadog).
- Optimize infrastructure untuk scalability, performance, cost efficiency.
- Maintenance, upgrade, backup, disaster recovery.
- Documentation, incident response, RCA, post-incident improvement.
- Continuously evaluate & adopt DevOps tools.

**Minimum qualifications**
- Pengalaman 3–6 tahun.
- Sarjana (S1).
- CI/CD: GitLab CI, Jenkins, GitHub.
- Cloud: Alibaba Cloud, AWS, GCP.
- Container: Docker, Kubernetes, Helm.
- IaC: Terraform, Ansible.
- Networking & security: VPC, IAM, Security Groups, Load Balancer, NATGW, VPN.
- Observability: Prometheus, TIG, Grafana, ELK/OpenSearch, Datadog.
- DevSecOps: SAST/DAST, image scanning, secrets management.
- Database operasional: MySQL, PostgreSQL.
- Performance monitoring, capacity planning, HA, scalability.

---

## 2. Backend / Fullstack Engineer

**Key responsibilities**
- Design & maintain arsitektur aplikasi/service beserta integrasi sistem lain.
- Design, build, evaluasi model data yang skalabel & performant.
- Tulis kode bersih, efisien, aman; lakukan code/performance/security review.
- Pastikan kode bekerja sesuai desain & optimal secara teknis/fungsional.
- Bangun automated testing framework (unit, integration, regression).
- Susun dokumentasi teknis (kamus data, API doc, arsitektur sistem).
- Definisikan spesifikasi teknis & kebutuhan infrastruktur operasional.
- Handle eskalasi dari support/helpdesk.
- Knowledge sharing, mentoring, evaluasi teknologi baru (AI-driven SDLC, programming language, database).

**Minimum qualifications**
- S1, IPK minimal 3.0 (CS/Informatics/Information Systems/IT/Statistics/Math).
- Analytical, solution-oriented, detail-focused, komunikatif.
- Backend Python atau C# + SQL (PostgreSQL); frontend JavaScript + responsive HTML/CSS/SCSS.
- Git, DevOps (Docker, CI/CD, Azure DevOps), SOLID.
- Vue.js + Nuxt.js, Node.js, Odoo adalah plus.
- Web services, REST API, JSON, HTTP, web architecture.
- AI-driven tools & LLM integration adalah plus.

---

## 3. QA Engineer (Banking)

**Key responsibilities**
- End-to-end QA throughout SDLC.
- Design test strategy, scenario, case, plan dari requirement bisnis & teknis.
- Develop, execute, maintain automated test scripts/frameworks.
- Functional, Integration, Regression, System, E2E, API testing.
- Validasi proses perbankan, transaksi, integrasi, data integrity.
- API validation via RESTful APIs & distributed environments.
- Database validation pakai SQL.
- Identify, analyze, document, manage defects.
- Improve test coverage, automation coverage, QA process.
- Integrate automated testing ke CI/CD (continuous testing).

**Minimum qualifications**
- 1–5 tahun SQA / QA Engineering.
- Pengalaman project banking (digital banking, core banking, payment).
- Test automation (JMeter, Katalon, Selenium, Cypress, Playwright, Appium).
- API testing (Postman, Swagger, REST Assured).
- STLC/SDLC, functional/integration/regression/E2E.
- SQL & database validation.
- Agile/Scrum; exposure CI/CD & DevOps adalah nilai plus.

---

## 4. Backend Engineer (Java Quarkus + C# .NET)

**Key responsibilities**
- Design & maintain backend services scalable & high-performance (Java Quarkus, C# .NET).
- Develop & manage RESTful APIs, koordinasi API contracts.
- Full SDLC dari requirement sampai deployment & support.
- Architecture review & diskusi desain service baru.
- Debugging & integrasi frontend client (Vue.js, React).
- Monitor, troubleshoot, optimasi performa & reliability.
- Containerize services untuk Kubernetes, deploy/debug/optimize bareng DevOps.
- Implement secure & efficient database interactions.
- Code review, unit & integration test.

**Minimum qualifications**
- 4+ tahun pengalaman Java, C#, atau serupa.
- 2+ tahunREST API design.
- 1+ tahun microservices.
- Relational SQL (PostgreSQL) & NoSQL (MongoDB, Redis).
- OOP & design patterns, SQL query kompleks.
- Go, Elixir, PHP adalah plus; Protobuf/gRPC plus.
- Message queue/broker: Kafka, NATS.IO.
- Unit test, Git, microservices, Docker, Kubernetes.
- Cloud (AWS/Azure/GCP), HTML/CSS/JS, Vue/React.
- English, AI-assisted development, agentic workflow.

---

## Pemetaan ke lab repo

| Skill JD | Lab di repo ini |
| --- | --- |
| CI/CD GitLab/Jenkins/GitHub | `.github/workflows/{ci,deploy-ec2,deploy-k8s}.yml` |
| IaC Terraform | `terraform/` + `docs/04-terraform.md` |
| Docker/Kubernetes/Helm | `app/Dockerfile`, `docker-compose.yml`, `k8s/`, `helm/nextjs-app/` |
| AWS VPC/IAM/SG/ALB | `docs/01-ec2-launch.md`, `docs/08-aws-architecture-notes.md` |
| Monitoring Prometheus/Grafana | `docs/08`, `scripts/monitor.sh` (jika tersedia) |
| SQL PostgreSQL | `db/init/001-schema.sql`, `docs/10-database.md` |
| Testing | `app/` unit test, `.github/workflows/ci.yml` |
| AI-assisted development | `app/app/api/ai/route.ts` |
| Banking QA | `qa-automation-2026` (repo terpisah) |
