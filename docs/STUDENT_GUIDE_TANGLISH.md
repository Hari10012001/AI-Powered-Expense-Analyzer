# COMPLETE STUDENT PROJECT GUIDE (TANGLISH)

## Project Basic Details

- Project Title: `AI-Powered Expenses Analyzer`
- Project Domain: `Personal Finance Management / Expense Tracking`
- Technology Used: `Java 21, JSP, Servlet, JDBC, MySQL, H2 (fallback), Tomcat 9, HTML, CSS, JavaScript, Chart.js, Tesseract OCR (optional)`
- Problem Statement: `Manual expense tracking irregular-aa irukku; insights illa; report ready panna kashtam`
- Target Users: `College students, salaried people, family budget track pannura users, demo/learning students`

---

## 1. Project Overview

### Indha project enna?

Indha project oru web application. User login panni:

- income add pannalaam
- expense add/edit/delete pannalaam
- daily/monthly/yearly report generate pannalaam
- chart-la analysis paakalam
- bill text/image la irundhu expense details auto extract pannitu save pannalaam

### Idhu en solve panna try pannudhu?

Namma daily cash flow puriyaama irundha overspending nadakkum.  
Indha app:

- data organized-aa store pannudhu
- spending pattern kaamikudhu
- savings improve panna help pannudhu

### Real world example

Suppose Arun monthly salary 25,000.  
Avan grocery, fuel, rent, snacks-ku selavu panraan but exact amount track pannala.

Problem:

- month end-la "money enga pochu?" nu doubt
- category-wise idea illa
- savings target miss aagudhu

Solution with this project:

- daily entry update
- monthly report paathu category heavy spend identify
- chart-la visual-aa paathu control panna easy

---

## 2. Problem Statement

### Current problem enna?

- Neraya per expense notebook-la note pannave maataanga
- Noted pannina kooda regular-aa update panna maataanga
- Month end total calculate panna time edukkum
- Data split/compare panna difficult

### Existing system la issues

- Excel/manual method use panna human error adhigam
- Ready-made apps la paid features irukkum
- OCR support illa na bill details type panna time waste
- Data analysis (top category, trend) clear-aa kidaikkaadhu

---

## 3. Proposed Solution

Namma project simple-aa and practical-aa problem solve pannudhu:

- centralized web portal
- user-wise secure session
- income + expense CRUD
- automatic report generation
- analysis charts
- bill scan extraction support

### Simple scenario

1. User login pannuvaar
2. Salary entry add pannuvaar
3. Grocery/Fuel/Rent expense add pannuvaar
4. Report page-la monthly total paarpaar
5. Analysis page-la highest category identify pannuvaar
6. Next month budget set pannuvaar

---

## 4. Project Architecture

### High level architecture

```text
[User Browser]
    |
    v
[JSP UI Pages]
    |
    v
[Servlet Controllers]
    |
    v
[DAO Layer - JDBC]
    |
    v
[DBConnection]
   |----> [MySQL] (Primary)
   |
   +----> [H2 In-Memory] (Fallback)
```

Bill scan extra flow:

```text
Bill Image/Text --> BillScanServlet --> OCR/Parser --> Extracted Fields --> Expense Table
```

### Components epdi interact aagudhu?

- JSP: form collect pannum, data display pannum
- Servlet: business flow handle pannum
- DAO: DB query execute pannum
- DBConnection: connection create pannum
- Database: permanent/in-memory data store pannum

### Data flow simple explanation

1. User form submit pannuvaar
2. Servlet request receive pannum
3. Session user check pannum
4. DAO database query run pannum
5. Result servlet-ku varum
6. Servlet attribute set pannitu JSP forward/redirect pannum
7. User screen-la updated data paapaar

---

## 5. Technology Explanation

Ippo project-la use pannirukkura ovvoru technology-yum clear-aa paapom.

### Java 21

- Why use pannom:
  - robust backend coding
  - OOP clean structure
  - enterprise-level standard
- Alternative:
  - Java 17, Python (Django/Flask), Node.js

### Servlet

- Why:
  - HTTP request/response direct control
  - form data process panna suitable
- Alternative:
  - Spring Boot controllers
  - Node Express routes

### JSP

- Why:
  - server-side dynamic HTML render easy
  - Java web learning-ku direct
- Alternative:
  - Thymeleaf
  - React/Angular frontend + REST backend

### JDBC

- Why:
  - direct database operation
  - PreparedStatement use panni safe query
- Alternative:
  - Hibernate/JPA
  - MyBatis

### MySQL

- Why:
  - relational DB
  - stable, common, easy
- Alternative:
  - PostgreSQL
  - MariaDB

### H2 (Fallback)

- Why:
  - MySQL fail aana project stop aaga koodadhu
  - quick demo/testing-ku useful
- Alternative:
  - SQLite embedded DB

### Apache Tomcat 9

- Why:
  - JSP/Servlet run panna container venum
  - project facet matching (web 4.0)
- Alternative:
  - Jetty
  - WildFly

### HTML + CSS + JavaScript

- Why:
  - UI build panna basic stack
  - responsive and interactive behavior

### Chart.js

- Why:
  - easy chart rendering
  - pie/bar/line chart fast setup
- Alternative:
  - ApexCharts
  - ECharts

### Tesseract OCR (optional)

- Why:
  - bill image la text extract panna
- Alternative:
  - Google Vision OCR API
  - Azure OCR

### Eclipse / Project packaging note

- Original workspace-la Eclipse metadata files irukkalaam.
- Aana indha `dist` package-la `.project`, `.classpath`, `.settings` include pannala.
- Why:
  - package lightweight-aa irukkanum
  - source + webapp + docs + scripts mattum distribute panna easy
  - runtime setup scripts separate-aa manage panna easy

---

## 6. Folder Structure / Project Structure

```text
ExpenseAnalyzer/
  +- src/main/java/com/expenses/
  |  +- controller/      (Servlets)
  |  +- dao/             (DB logic)
  |  +- model/           (POJO classes)
  |  +- util/            (Session helper)
  +- src/main/webapp/
  |  +- assets/css/      (UI styles)
  |  +- assets/js/       (client JS)
  |  +- WEB-INF/lib      (bundled JDBC jars)
  |  +- WEB-INF/web.xml  (Servlet mappings)
  |  +- *.jsp            (UI pages)
  +- db/schema.sql        (DB schema + seed user)
  +- scripts/             (start/stop/DB utility scripts)
  +- docs/                (student guide + presentation inputs)
  +- samples/bills/       (OCR sample files)
  +- .tomcat-base/        (local Tomcat runtime base used by scripts)
```

### Important controller files

- `AuthServlet.java`
- `IncomeServlet.java`
- `ExpenseServlet.java`
- `ReportServlet.java`
- `AnalysisServlet.java`
- `BillScanServlet.java`
- `ProfileServlet.java`

### Important DAO files

- `DBConnection.java`
- `UserDAO.java`
- `IncomeDAO.java`
- `ExpenseDAO.java`

---

## 7. Step-by-Step Working Flow

### User app open pannumbodhu enna nadakkum?

1. URL open: `login.jsp`
2. Already login session irundha dashboard-ku redirect
3. Login/register success na session set aagum

### Backend la enna nadakkum?

1. Request servlet-ku varum
2. `SessionUtil.getUserId()` check pannum
3. Unauthorized na login page-ku anuppum
4. Valid request na DAO call pannum
5. DB result varum
6. JSP render aagum

### Database interaction flow

Example: Expense add

1. User amount/category/date fill pannuvaar
2. `ExpenseServlet.doPost`
3. `ExpenseDAO.addExpense(...)`
4. SQL insert execute
5. success message-oda list page refresh

---

## 8. Database Design

### Table 1: users

| Column | Type | Purpose |
|---|---|---|
| id | INT PK AUTO_INCREMENT | user unique ID |
| name | VARCHAR(100) | user name |
| email | VARCHAR(100) UNIQUE | login email |
| password | VARCHAR(255) | login password (current project-la plain text) |

### Table 2: income

| Column | Type | Purpose |
|---|---|---|
| id | INT PK AUTO_INCREMENT | income record ID |
| user_id | INT FK | user-oda income record |
| amount | DOUBLE | income amount |
| source | VARCHAR(255) | salary/freelance/business etc |
| date | DATE | income date |

### Table 3: expense

| Column | Type | Purpose |
|---|---|---|
| id | INT PK AUTO_INCREMENT | expense record ID |
| user_id | INT FK | user-oda expense record |
| amount | DOUBLE | expense amount |
| category | VARCHAR(255) | food/travel/rent etc |
| date | DATE | expense date |

### Relationships

- `users.id` one-to-many `income.user_id`
- `users.id` one-to-many `expense.user_id`
- `ON DELETE CASCADE` irukku

### Seed user

- `admin@example.com / admin123`

---

## 9. Key Modules

### 9.1 Login Module

- Files: `login.jsp`, `AuthServlet`, `LoginServlet`
- Function:
  - login
  - registration
  - logout
  - session creation

### 9.2 Admin Module

Current project-la separate admin dashboard illa.  
But demo-level default admin account seed pannirukkom (`admin@example.com`).  
Itha first login-ku use panna mudiyum.

### 9.3 User Module

- Profile view/update
- name/email/password modify
- duplicate email prevent pannum

### 9.4 Income Module

- add income
- edit income
- delete income
- list income history

### 9.5 Expense Module

- add expense
- edit expense
- delete expense
- category-wise tracking

### 9.6 Processing Module (Bill Scan)

- OCR text collect pannum
- amount/date/category parse pannum
- expense table-la save pannum

### 9.7 Report Module

- daily report
- monthly report
- yearly report
- net savings calculation

### 9.8 Analysis Module

- savings metrics
- highest category
- monthly comparison bar chart
- yearly trend line chart

---

## 10. Important Algorithms / Logic

### 10.1 Authentication logic

1. email + password edukkum
2. DB match paakum
3. match na session set
4. mismatch na error message

### 10.2 Report period logic

1. `period` param read pannum
2. daily na selected date range
3. monthly na month first day -> next month first day
4. yearly na year start -> next year start
5. income total + expense total compute
6. `net = income - expense`

### 10.3 Bill amount extraction logic

1. OCR text line by line scan
2. `grand total/net payable/amount due` line values high priority
3. `total/amount/inr/rs` line fallback
4. still nothing na max numeric value use

### 10.4 Date extraction logic

1. regex match various date formats
2. parse try in multiple format
3. success na ISO date convert
4. fail na today date set

### 10.5 Category guess logic

1. text lowercase pannum
2. category keywords compare pannum
3. each category-ku score assign
4. highest score category choose
5. none na `Misc`

### 10.6 Analysis highest/lowest month logic

1. 12 months map normalize pannum (missing month = 0)
2. loop panni max month find
3. loop panni min month find

---

## 11. API / Backend Logic

Request -> Processing -> Response model-la purinjukonga.

### Example 1: Login API flow

- Request:
  - `POST /AuthServlet`
  - params: `action=login`, `email`, `password`
- Processing:
  - `UserDAO.authenticate()`
  - user kidaitha session set
- Response:
  - success -> `dashboard.jsp`
  - fail -> `login.jsp?error=...`

### Example 2: Save expense flow

- Request:
  - `POST /ExpenseServlet`
  - params: `id`, `amount`, `category`, `date`
- Processing:
  - `id > 0` na update
  - illana insert
- Response:
  - success -> `ExpenseServlet?msg=...`
  - fail -> `ExpenseServlet?error=...`

### Endpoint summary

- `/AuthServlet` (login/register/logout)
- `/IncomeServlet` (income CRUD)
- `/ExpenseServlet` (expense CRUD)
- `/ReportServlet` (period reports)
- `/AnalysisServlet` (metrics + chart data)
- `/ProfileServlet` (profile read/update)
- `/BillScanServlet` (OCR extract + save)

---

## 12. UI Explanation

### login.jsp

- Login + Register tabs
- flash success/error message
- demo account info

### dashboard.jsp

- welcome user
- navigation all modules
- module cards

### income.jsp

- add/edit form
- income table
- edit/delete buttons

### expense.jsp

- add/edit expense form
- expense table
- bill scan shortcut button

### report.jsp

- daily/monthly/yearly filter forms
- total income/expense/net cards
- period entries tables

### analyzer.jsp

- savings cards
- highest category/month details
- 3 charts (pie/bar/line)

### billscan.jsp

- step 1 input (image/txt/paste)
- step 2 extracted fields review
- save button to expense

### profile.jsp

- user details update
- optional password change

---

## 13. Installation Guide

### System Requirements

- OS: Windows 10/11 (mac/linux-um possible)
- RAM: 8 GB recommended
- JDK: 21
- IDE: Eclipse Enterprise Java
- Server: Apache Tomcat 9
- DB: MySQL 8+ (recommended)
- Browser: Chrome/Edge

### Setup steps

1. JDK 21 install pannunga
2. Tomcat 9 install pannunga
3. MySQL install pannunga
4. Optional-aa Eclipse install pannunga
5. `scripts\DB.bat` allathu `db/schema.sql` use panni DB ready pannunga
6. `scripts\start.bat` use panni Tomcat-la app deploy/start pannunga
7. Browser-la project open pannunga

---

## 14. How to Run the Project

### Method A: Script-based run + MySQL (Best for this dist package)

1. Tomcat 9 install pannunga
2. `CATALINA_HOME` set panna best
3. MySQL-la `db/schema.sql` execute pannunga allathu `scripts\DB.bat` run pannunga
4. `scripts\start.bat` run pannunga
5. URL open:
   - `http://localhost:8080/ExpenseAnalyzer/login.jsp`
6. login panni modules test pannunga
7. stop panna `scripts\stop.bat` run pannunga

### Method B: Eclipse + MySQL

1. Eclipse open
2. New Dynamic Web Project create pannunga allathu folder-a general project-aa import pannunga
3. `src/main/java` and `src/main/webapp` paths configure pannunga
4. Project properties-la Tomcat runtime select pannunga
5. `src/main/webapp/WEB-INF/lib` la irukkura MySQL + H2 jars add pannunga if required
6. MySQL-la `db/schema.sql` execute pannunga
7. Server start
8. URL open:
   - `http://localhost:8080/ExpenseAnalyzer/login.jsp`

### Method B: Fallback run (MySQL illa)

1. H2 jar compulsory include pannunga
2. app start pannunga
3. MySQL connect fail aana auto H2 use aagum
4. note: server stop aana data reset aagum

### Optional env variable setup (PowerShell sample)

```powershell
$env:EXPENSE_MYSQL_URL="jdbc:mysql://localhost:3306/expense_db?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC"
$env:EXPENSE_MYSQL_USER="root"
$env:EXPENSE_MYSQL_PASSWORD="root"
$env:EXPENSE_TESSERACT_CMD="C:\Program Files\Tesseract-OCR\tesseract.exe"
```

---

## 15. Demo Explanation (for Presentation)

Review time-la neenga follow panna ready-made demo flow:

1. Project intro 30 sec
2. Login screen show panni register/login explain
3. Dashboard la modules list show
4. Income entry add live
5. Expense entry add live
6. One expense edit + delete demo
7. Report module-la daily -> monthly -> yearly switch panni totals explain
8. Analysis module charts show panni highest category explain
9. Bill scan module-la sample OCR text upload panni auto extract show
10. Extracted result save panni expense table-la reflect aagiradhu show
11. Profile update show
12. Logout show

### Presentation la solla use panna line

"Indha system manual expense notebook method-a replace pannudhu.  
User data structured-aa store pannudhu, reports and charts moolama spending decision smart-aa edukka help pannudhu."

---

## 16. Viva Questions and Answers

### Q1. Indha project main objective enna?
A: Income-expense tracking simple pannitu report + analysis kudukkardhu.

### Q2. Domain enna?
A: Personal finance management.

### Q3. Why Servlet + JSP use pannineenga?
A: Core Java web concepts direct-aa implement panna easy and educational clarity high.

### Q4. MVC pattern use pannirukeengala?
A: Yes. JSP = View, Servlet = Controller, DAO/Model = Data layer.

### Q5. Database enna use pannirukeenga?
A: MySQL primary, H2 fallback.

### Q6. H2 fallback en use pannineenga?
A: MySQL unavailable irundhaalum app run aaganum.

### Q7. Authentication epdi pannineenga?
A: email/password DB validate panni session attributes set pannrom.

### Q8. Session attributes enna?
A: `userId`, `userName`, `userEmail`.

### Q9. Unauthorized access epdi prevent pannineenga?
A: `SessionUtil.getUserId()` check pannitu login redirect pannrom.

### Q10. Income/Expense CRUD epdi work aagudhu?
A: GET list/edit/delete, POST add/update pattern use pannrom.

### Q11. Report module enna pannudhu?
A: Daily/monthly/yearly filter panni totals + net savings calculate pannudhu.

### Q12. Net savings formula?
A: `totalIncome - totalExpense`.

### Q13. Analysis module data source enna?
A: ExpenseDAO & IncomeDAO aggregation queries.

### Q14. Charts enna library?
A: Chart.js CDN.

### Q15. Bill scan la AI part enna?
A: OCR text extraction + heuristic parsing (amount/date/category).

### Q16. OCR image extraction epdi?
A: Tesseract command run panni text read pannrom.

### Q17. Category guess epdi?
A: Keyword score-based matching.

### Q18. SQL injection avoid pannineengala?
A: Aam, PreparedStatement use pannirukkom.

### Q19. Password security strong-aa?
A: Current version-la plain text; future version-la hash implement panna plan.

### Q20. Biggest limitation enna?
A: Dedicated admin panel illa, password hashing illa, OCR heuristic accuracy limited.

### Q21. Future enhancement onnu sollunga?
A: Mobile app + bank SMS auto import + ML-based prediction.

### Q22. This project real world-la use aaguma?
A: Aam, especially student/small family budget tracking-ku immediate-aa use panna mudiyum.

---

## 17. Advantages

- Beginner-friendly architecture
- full CRUD coverage
- report automation
- visual analytics
- OCR-assisted bill entry
- MySQL + fallback resilience
- demo-ready UI
- modular code separation (controller/dao/model)

---

## 18. Limitations

- password hashing illa
- role-based access control illa
- API token/security hardening minimal
- OCR heuristic ellaa bill format-ukum perfect illa
- Chart.js CDN internet dependency
- deployment process IDE-oriented (Maven/Gradle build script illa)

---

## 19. Future Enhancements

- BCrypt password hashing
- Admin dashboard with user management
- Budget alert + overspending notification
- Export PDF/Excel reports
- Email monthly summary
- Mobile responsive improvements
- Multi-language UI
- AI/ML spend prediction
- UPI/SMS/bank statement integration
- REST API layer + React mobile/web frontend

---

## 20. Real World Use Cases

- College hostel students monthly cash control
- PG/flat share friends shared expense planning
- Salaried user personal budget control
- Small shop daily inflow-outflow tracking
- Family grocery/fuel/rent monthly planning
- Financial literacy training demo tool

---

## 21. Interview Explanation

Interview-la project explain panna 3-level format use pannunga.

### 30-second version

"Naan build pannadhu AI-Powered Expenses Analyzer. Idhu Java Servlet-JSP based web app. User income/expense manage pannuvanga, report generate pannuvanga, chart analysis paapanga, bill OCR text la irundhu expense auto extract pannalam."

### 2-minute version

"Project objective manual expense tracking issue solve pannradhu.  
Architecture-la JSP frontend, servlet controller, DAO JDBC layer, MySQL DB use pannirukken.  
Authentication session-based. Income/expense full CRUD implement pannirukken.  
Report module daily/monthly/yearly totals and net savings calculate pannudhu.  
Analysis module category pie, monthly comparison bar, yearly trend line chart render pannudhu.  
BillScan module OCR text la amount/date/category extract panni expense-a save pannudhu.  
MySQL fail aana H2 fallback kuduthirukken so demo reliable-aa run aagum."

### Interview follow-up ready points

- Challenge solved: DB fallback + OCR parsing
- Clean design: controller/dao/model split
- Improvement plan: hash password, REST API, notifications

---

## 22. Quick Revision Section (2-minute summary)

### Ultra short memory map

- What: Expense tracking + analysis web app
- Why: Manual tracking problems solve panna
- Stack: Java + JSP/Servlet + JDBC + MySQL + Tomcat
- Features: Login, income/expense CRUD, report, analysis, bill scan, profile
- Logic: Session auth, aggregation reports, OCR text parsing
- Output: Better spending visibility + savings decision

### 2-minute speaking script

"Indha project title AI-Powered Expenses Analyzer.  
Namma domain personal finance management.  
Main problem manual expense tracking and no proper insights.  
Namma solution web-based system where user login panni income/expense add pannalaam.  
Backend Java servlet, frontend JSP, database MySQL use pannirukkom.  
Income and expense-ku full CRUD irukku.  
Report module daily, monthly, yearly totals and net savings calculate pannudhu.  
Analysis module charts moolama top spending areas clear-aa kaamikudhu.  
BillScan module OCR text/image la irundhu amount-date-category extract panni direct expense save pannudhu.  
Overall-a indha project user-ku spending control, clarity, and financial planning confidence kudukkudhu."

---

## Final Confidence Note

Indha full guide-a revise pannina:

- project architecture puriyum
- module-by-module explain panna theriyum
- demo smooth-aa conduct panna mudiyum
- viva questions handle panna mudiyum
- interview-la strong-aa present panna mudiyum

So next time yaaravadhu "project pathi sollu" nu sonna, nee full confident-aa explain panna ready.
