# AI-Powered Expenses Analyzer (Tanglish README)

Idhu oru Java Web Project. User income + expense manage panna mudiyum, reports generate panna mudiyum, charts-la analysis paakalam, bill OCR text la irundhu expense auto fill pannalam.

## Project Purpose

Daily finance tracking easy aagavum, manual mistakes kuraiyavum, student/demo level full-stack concept clear aagavum indha project build pannirukom.

## Core Features

- Login / Register / Logout
- Income CRUD (Add, Edit, Delete, List)
- Expense CRUD (Add, Edit, Delete, List)
- Daily / Monthly / Yearly report
- Graph analysis (Category pie, Monthly bar, Yearly trend)
- AI-style Bill Scan module (OCR text parse + auto category guess)
- Profile update module

## Tech Stack

- Backend: Java 21, Servlet (Jakarta/Java EE style), JSP
- Server: Apache Tomcat 9.x
- DB: MySQL (primary), H2 in-memory (fallback)
- Frontend: HTML, CSS, JS
- Charts: Chart.js CDN
- OCR (optional image extraction): Tesseract OCR

## High-Level Flow

1. User login pannuvanga (`AuthServlet`).
2. Session create aagum (`userId`, `userName`, `userEmail`).
3. Income/Expense modules DB la data save pannum.
4. Report module selected period-ku totals calculate pannum.
5. Analysis module charts generate pannum.
6. Bill Scan module OCR text la amount/date/category extract panni expense save pannum.

## Project Structure (Important Paths)

- `src/main/java/com/expenses/controller` - Servlets
- `src/main/java/com/expenses/dao` - DB access layer
- `src/main/java/com/expenses/model` - POJO models
- `src/main/java/com/expenses/util` - Session helper
- `src/main/webapp` - JSP pages + assets
- `src/main/webapp/WEB-INF/web.xml` - Servlet mapping
- `src/main/webapp/WEB-INF/lib` - bundled JDBC libraries used by the app
- `db/schema.sql` - DB schema + admin seed
- `samples/bills` - sample OCR text/image files
- `scripts/*.bat` - start / stop / database setup utility scripts
- `.tomcat-base` - local Tomcat runtime base created/used by the scripts

## Prerequisites

- JDK 21
- Apache Tomcat 9
- MySQL 8+ (optional if you use H2 fallback)
- JDBC JARs are already bundled inside `src/main/webapp/WEB-INF/lib`:
  - `mysql-connector-j-8.0.33.jar`
  - `h2-2.2.224.jar` (fallback use case)

## Environment Variables (Optional but Recommended)

`DBConnection.java` defaults use pannum; but production-style setup-ku env vars set pannunga:

- `EXPENSE_MYSQL_URL` (default: `jdbc:mysql://localhost:3306/expense_db?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC`)
- `EXPENSE_MYSQL_USER` (default: `root`)
- `EXPENSE_MYSQL_PASSWORD` (default: `root`)
- `EXPENSE_H2_URL` (default: `jdbc:h2:mem:expense_db;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1`)
- `EXPENSE_H2_USER` (default: `sa`)
- `EXPENSE_H2_PASSWORD` (default: empty)
- `EXPENSE_TESSERACT_CMD` (optional, full path to `tesseract.exe`)

## How to Run (Recommended: Script + Tomcat)

1. Tomcat 9 install pannunga. `CATALINA_HOME` set pannina best.
2. (MySQL use panna) `scripts\DB.bat` run pannunga. Idhu `db/schema.sql` apply pannum.
3. App start panna `scripts\start.bat` run pannunga.
4. Browser la open pannunga:
   - `http://localhost:8080/ExpenseAnalyzer/login.jsp`
5. Stop panna `scripts\stop.bat` run pannunga.

## Easiest Public URL Deployment: Railway

Indha project-ku easiest public deployment path:

- App host: Railway
- Database: Railway MySQL
- Public URL: Railway generated domain

### Why this works well

- Project already single Java web app, separate FE deploy thevai illa
- Railway MySQL env vars-ai app read pannum
- Dockerfile included, so Tomcat app direct deploy panna mudiyum
- App root-la deploy aagum; public URL open panna `login.jsp` welcome page varum

### Files added for deployment

- `Dockerfile`
- `docker/docker-entrypoint.sh`
- Railway-compatible DB env support in `DBConnection.java`

### Railway Steps

1. GitHub-la project push pannunga.
2. Railway-la new project create pannunga.
3. `MySQL` service add pannunga.
4. App service create panni GitHub repo connect pannunga.
5. Root directory same repo root-a irukka confirm pannunga.
6. Railway Dockerfile use panni build/deploy pannum.
7. Deploy mudinja apram generated public domain open pannunga.

### Expected Public URL

- `https://<your-app>.up.railway.app/`

### Database Notes

- Preferred: Railway MySQL
- Fallback: local file-based H2 (`./data/expense_db`) if MySQL unavailable

### Demo Login After Deploy

- Email: `admin@example.com`
- Password: `admin123`

## How to Run (Alternative: Eclipse + Tomcat)

Indha `dist` package-la `.project`, `.classpath`, `.settings` maadhiri Eclipse metadata files illa. So direct `Existing Projects into Workspace` import always work aagathu.

1. Eclipse open pannunga.
2. New Dynamic Web Project create pannunga allathu existing folder-a general project-aa import pannunga.
3. `src/main/java` and `src/main/webapp` paths configure pannunga.
4. Tomcat 9 runtime target pannunga.
5. `src/main/webapp/WEB-INF/lib` la irukkura MySQL + H2 jar files build path-la include pannunga if Eclipse auto-detect panna illa.
6. (MySQL use panna) `db/schema.sql` execute pannunga allathu `scripts\DB.bat` use pannunga.
7. Server start pannitu browser la open pannunga:
   - `http://localhost:8080/ExpenseAnalyzer/login.jsp`

## Demo Login

- Email: `admin@example.com`
- Password: `admin123`

## Bill Scan Quick Test

`samples/bills` folder la sample files irukku:

- `bill_grocery_sample_ocr.txt`
- `bill_restaurant_sample_ocr.txt`
- `bill_fuel_sample_ocr.txt`

Bill Scan module-la `.txt` upload pannina extraction immediate aagum.
Image OCR-ku system la Tesseract install irukkanum.

## Full A-Z Guide

Complete student-friendly deep guide inga irukku:

- `docs/STUDENT_GUIDE_TANGLISH.md`
