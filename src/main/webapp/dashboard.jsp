<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
String userName = (String) session.getAttribute("userName");
String userEmail = (String) session.getAttribute("userEmail");
String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard | Expense Analyzer</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/css/app.css?v=20260304">
</head>
<body class="app-body">
<header class="site-nav">
    <div class="nav-inner">
        <div class="brand"><span class="brand-mark"></span>AI-Powered Expenses Analyzer</div>
        <nav class="nav-links">
            <a class="nav-link is-active" href="dashboard.jsp">Dashboard</a>
            <a class="nav-link" href="IncomeServlet">Income</a>
            <a class="nav-link" href="ExpenseServlet">Expenses</a>
            <a class="nav-link" href="ReportServlet">Reports</a>
            <a class="nav-link" href="AnalysisServlet">Analysis</a>
            <a class="nav-link" href="BillScanServlet">Bill Scan</a>
            <a class="nav-link" href="ProfileServlet">Profile</a>
            <a class="nav-link danger" href="AuthServlet?action=logout">Logout</a>
        </nav>
    </div>
</header>

<main class="page-wrap">
    <section class="page-head reveal">
        <div>
            <h1>Welcome, <%= userName == null ? "User" : userName %></h1>
            <p class="page-sub">Signed in as <strong><%= userEmail == null ? "-" : userEmail %></strong>. Your finance operations workspace is now active.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Quick actions to start your workflow without navigation delay.</p>
        <div class="action-row">
            <a class="btn ghost" href="IncomeServlet">+ Add Income</a>
            <a class="btn ghost" href="ExpenseServlet">+ Add Expense</a>
            <a class="btn secondary" href="ReportServlet">Open Reports</a>
            <a class="btn" href="BillScanServlet">Scan Bill</a>
        </div>
    </section>

    <div class="flash-wrap">
        <% if (msg != null) { %>
            <div class="flash ok" data-flash><%= msg %></div>
        <% } %>
    </div>

    <section class="grid-3 reveal delay-1" style="margin-bottom:16px;">
        <article class="metric-card">
            <p class="metric-label">Environment Status</p>
            <p class="metric-value">Live</p>
            <p class="page-sub">Server, database, and modules are online.</p>
        </article>
        <article class="metric-card">
            <p class="metric-label">Session User ID</p>
            <p class="metric-value"><%= userId %></p>
            <p class="page-sub">Authenticated workflow enabled.</p>
        </article>
        <article class="metric-card">
            <p class="metric-label">Realtime Clock</p>
            <p class="metric-value" style="font-size:19px;"><span data-live-clock></span></p>
            <p class="page-sub">Updates every second.</p>
        </article>
    </section>

    <section class="panel reveal delay-2">
        <h2 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Operational Modules</h2>
        <p class="page-sub" style="margin-bottom:14px;">Choose a module below to run live finance workflows.</p>
        <div class="module-grid">
            <article class="module-card">
                <div class="module-card-head">
                    <span class="module-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <circle cx="12" cy="8" r="3.5" stroke="currentColor" stroke-width="1.8"/>
                            <path d="M5 19c0-3.1 3-5 7-5s7 1.9 7 5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                        </svg>
                    </span>
                    <h3>User Module</h3>
                </div>
                <p>Manage profile details and account security settings.</p>
                <a class="btn" href="ProfileServlet">Open Profile</a>
            </article>
            <article class="module-card">
                <div class="module-card-head">
                    <span class="module-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <rect x="3" y="6" width="18" height="12" rx="2.4" stroke="currentColor" stroke-width="1.8"/>
                            <circle cx="12" cy="12" r="2.2" stroke="currentColor" stroke-width="1.8"/>
                        </svg>
                    </span>
                    <h3>Income Management</h3>
                </div>
                <p>Add, edit, delete, and review all income entries.</p>
                <a class="btn" href="IncomeServlet">Manage Income</a>
            </article>
            <article class="module-card">
                <div class="module-card-head">
                    <span class="module-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M3 7.5A2.5 2.5 0 0 1 5.5 5H19a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5.5A2.5 2.5 0 0 1 3 16.5v-9Z" stroke="currentColor" stroke-width="1.8"/>
                            <path d="M3 10h18" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                        </svg>
                    </span>
                    <h3>Expense Management</h3>
                </div>
                <p>Track categorized expenses with CRUD operations.</p>
                <a class="btn" href="ExpenseServlet">Manage Expenses</a>
            </article>
            <article class="module-card">
                <div class="module-card-head">
                    <span class="module-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M5 20V10m7 10V6m7 14v-8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                            <path d="M3 20h18" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                        </svg>
                    </span>
                    <h3>Report Engine</h3>
                </div>
                <p>Generate daily, monthly, yearly summaries instantly.</p>
                <a class="btn" href="ReportServlet">View Reports</a>
            </article>
            <article class="module-card">
                <div class="module-card-head">
                    <span class="module-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M3.5 18.5h17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                            <path d="M5.5 15 10 10.5l3 3L18.5 8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
                        </svg>
                    </span>
                    <h3>Analytics &amp; Charts</h3>
                </div>
                <p>Monitor savings, top categories, and spending trends.</p>
                <a class="btn" href="AnalysisServlet">Open Analysis</a>
            </article>
            <article class="module-card">
                <div class="module-card-head">
                    <span class="module-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none">
                            <rect x="4" y="3.5" width="16" height="17" rx="2.4" stroke="currentColor" stroke-width="1.8"/>
                            <path d="M8 8h8M8 12h8M8 16h5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                        </svg>
                    </span>
                    <h3>AI Bill Scan</h3>
                </div>
                <p>Extract amount/date/category from OCR text files.</p>
                <a class="btn" href="BillScanServlet">Scan Bills</a>
            </article>
        </div>
    </section>
</main>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
