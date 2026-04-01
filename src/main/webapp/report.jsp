<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.expenses.model.Expense" %>
<%@ page import="com.expenses.model.Income" %>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
String period = (String) request.getAttribute("period");
if (period == null) period = "daily";
String selectedDate = (String) request.getAttribute("selectedDate");
String selectedMonth = (String) request.getAttribute("selectedMonth");
Object selectedYearObj = request.getAttribute("selectedYear");
int selectedYear = selectedYearObj == null ? java.time.LocalDate.now().getYear() : (Integer) selectedYearObj;

List<?> expenseList = (List<?>) request.getAttribute("expenseList");
List<?> incomeList = (List<?>) request.getAttribute("incomeList");
int expenseCount = expenseList == null ? 0 : expenseList.size();
int incomeCount = incomeList == null ? 0 : incomeList.size();

double totalExpense = request.getAttribute("totalExpense") == null ? 0.0 : (Double) request.getAttribute("totalExpense");
double totalIncome = request.getAttribute("totalIncome") == null ? 0.0 : (Double) request.getAttribute("totalIncome");
double netAmount = request.getAttribute("netAmount") == null ? 0.0 : (Double) request.getAttribute("netAmount");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Financial Reports</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/css/app.css?v=20260304">
</head>
<body class="app-body">
<header class="site-nav">
    <div class="nav-inner">
        <div class="brand"><span class="brand-mark"></span>AI-Powered Expenses Analyzer</div>
        <nav class="nav-links">
            <a class="nav-link" href="dashboard.jsp">Dashboard</a>
            <a class="nav-link" href="IncomeServlet">Income</a>
            <a class="nav-link" href="ExpenseServlet">Expenses</a>
            <a class="nav-link is-active" href="ReportServlet">Reports</a>
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
            <h2>Report Module</h2>
            <p class="page-sub">Generate daily, monthly, and yearly reports with income-expense comparison.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Switch period instantly and review net savings with live totals.</p>
        <div class="action-row">
            <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
            <a class="btn ghost" href="IncomeServlet">Income</a>
            <a class="btn ghost" href="ExpenseServlet">Expenses</a>
            <a class="btn secondary" href="AnalysisServlet">Open Analysis</a>
        </div>
    </section>

    <section class="panel reveal delay-1" style="margin-bottom:14px;">
        <div class="grid-auto">
            <form class="form-stack" action="ReportServlet" method="get">
                <input type="hidden" name="period" value="daily">
                <label>Daily Report</label>
                <input type="date" name="date" value="<%= selectedDate %>">
                <button type="submit" class="<%= "daily".equals(period) ? "" : "secondary" %>">Generate Daily</button>
            </form>

            <form class="form-stack" action="ReportServlet" method="get">
                <input type="hidden" name="period" value="monthly">
                <label>Monthly Report</label>
                <input type="month" name="month" value="<%= selectedMonth %>">
                <button type="submit" class="<%= "monthly".equals(period) ? "" : "secondary" %>">Generate Monthly</button>
            </form>

            <form class="form-stack" action="ReportServlet" method="get">
                <input type="hidden" name="period" value="yearly">
                <label>Yearly Report</label>
                <input type="number" min="2000" max="2100" name="year" value="<%= selectedYear %>">
                <button type="submit" class="<%= "yearly".equals(period) ? "" : "secondary" %>">Generate Yearly</button>
            </form>
        </div>
    </section>

    <section class="grid-3 reveal delay-2" style="margin-bottom:14px;">
        <article class="metric-card">
            <p class="metric-label">Selected Period</p>
            <p class="metric-value"><%= period.substring(0,1).toUpperCase() + period.substring(1) %></p>
        </article>
        <article class="metric-card">
            <p class="metric-label">Total Income</p>
            <p class="metric-value">Rs <span data-count-up="<%= String.format(java.util.Locale.US, "%.2f", totalIncome) %>"><%= String.format("%.2f", totalIncome) %></span></p>
        </article>
        <article class="metric-card">
            <p class="metric-label">Total Expense</p>
            <p class="metric-value">Rs <span data-count-up="<%= String.format(java.util.Locale.US, "%.2f", totalExpense) %>"><%= String.format("%.2f", totalExpense) %></span></p>
        </article>
    </section>

    <section class="panel reveal delay-3" style="margin-bottom:14px;">
        <div class="tag">Net Savings: Rs <%= String.format("%.2f", netAmount) %></div>
    </section>

    <section class="grid-2 report-entry-grid">
        <article class="panel report-entry-panel reveal delay-2">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Income Entries</h3>
            <p class="page-sub history-meta"><%= incomeCount %> entries in current filter.</p>
            <% if (incomeList != null && !incomeList.isEmpty()) { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr><th>Date</th><th>Source</th><th>Amount</th></tr>
                        </thead>
                        <tbody>
                            <% for (Object obj : incomeList) { Income in = (Income) obj; %>
                                <tr>
                                    <td><%= in.getDate() %></td>
                                    <td><%= in.getSource() %></td>
                                    <td>Rs <%= String.format("%.2f", in.getAmount()) %></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } else { %>
                <div class="empty">
                    No income entries available for selected period.
                    <div style="margin-top:10px;"><a class="btn secondary" href="IncomeServlet">Add Income Entry</a></div>
                </div>
            <% } %>
        </article>

        <article class="panel report-entry-panel reveal delay-3">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Expense Entries</h3>
            <p class="page-sub history-meta"><%= expenseCount %> entries in current filter.</p>
            <% if (expenseList != null && !expenseList.isEmpty()) { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr><th>Date</th><th>Category</th><th>Amount</th></tr>
                        </thead>
                        <tbody>
                            <% for (Object obj : expenseList) { Expense ex = (Expense) obj; %>
                                <tr>
                                    <td><%= ex.getDate() %></td>
                                    <td><%= ex.getCategory() %></td>
                                    <td>Rs <%= String.format("%.2f", ex.getAmount()) %></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } else { %>
                <div class="empty">
                    No expense entries available for selected period.
                    <div style="margin-top:10px;"><a class="btn secondary" href="ExpenseServlet">Add Expense Entry</a></div>
                </div>
            <% } %>
        </article>
    </section>
</main>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
