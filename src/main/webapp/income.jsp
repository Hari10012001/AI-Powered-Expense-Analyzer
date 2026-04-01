<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.expenses.model.Income" %>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
List<?> incomes = (List<?>) request.getAttribute("incomes");
Income editIncome = (Income) request.getAttribute("editIncome");
String msg = request.getParameter("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Income Management</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/css/app.css?v=20260304">
</head>
<body class="app-body">
<header class="site-nav">
    <div class="nav-inner">
        <div class="brand"><span class="brand-mark"></span>AI-Powered Expenses Analyzer</div>
        <nav class="nav-links">
            <a class="nav-link" href="dashboard.jsp">Dashboard</a>
            <a class="nav-link is-active" href="IncomeServlet">Income</a>
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
            <h2>Income Management</h2>
            <p class="page-sub">Add and maintain income records with full CRUD workflow.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Track incoming money streams and keep monthly cashflow current.</p>
        <div class="action-row">
            <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
            <a class="btn secondary" href="ReportServlet">View Reports</a>
            <a class="btn" href="ExpenseServlet">Go to Expenses</a>
        </div>
    </section>

    <div class="flash-wrap">
        <% if (msg != null) { %><div class="flash ok" data-flash><%= msg %></div><% } %>
        <% if (error != null) { %><div class="flash err" data-flash><%= error %></div><% } %>
    </div>

    <section class="grid-2">
        <article class="panel reveal delay-1">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;"><%= editIncome != null ? "Edit Income Entry" : "Add Income Entry" %></h3>
            <form class="form-stack" action="IncomeServlet" method="post">
                <input type="hidden" name="id" value="<%= editIncome == null ? "" : editIncome.getId() %>">
                <label>Amount</label>
                <input type="number" step="0.01" min="0" name="amount" required value="<%= editIncome == null ? "" : editIncome.getAmount() %>">
                <label>Source</label>
                <input type="text" name="source" placeholder="Salary / Freelance / Business" required value="<%= editIncome == null ? "" : editIncome.getSource() %>">
                <label>Date</label>
                <input type="date" name="date" required value="<%= editIncome == null ? "" : editIncome.getDate() %>">
                <button type="submit"><%= editIncome != null ? "Update Income" : "Save Income" %></button>
                <% if (editIncome != null) { %>
                    <a class="btn ghost" href="IncomeServlet">Cancel Edit</a>
                <% } %>
            </form>
        </article>

        <article class="panel reveal delay-2">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Income History</h3>
            <p class="page-sub history-meta">Sorted by latest entry ID (newest first).</p>
            <% if (incomes != null && !incomes.isEmpty()) { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Date</th>
                                <th>Source</th>
                                <th>Amount</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Object obj : incomes) { Income income = (Income) obj; %>
                                <tr>
                                    <td><span class="id-pill">#<%= income.getId() %></span></td>
                                    <td><%= income.getDate() %></td>
                                    <td><%= income.getSource() %></td>
                                    <td class="amount-cell">Rs <%= String.format("%.2f", income.getAmount()) %></td>
                                    <td class="action-cell">
                                        <a class="btn ghost" href="IncomeServlet?action=edit&id=<%= income.getId() %>">Edit</a>
                                        <a class="btn warn" href="IncomeServlet?action=delete&id=<%= income.getId() %>" onclick="return confirm('Delete this income entry?');">Delete</a>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } else { %>
                <div class="empty">
                    No income entries found. Add your first income record.
                    <div style="margin-top:10px;"><a class="btn secondary" href="IncomeServlet">Create First Income</a></div>
                </div>
            <% } %>
        </article>
    </section>
</main>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
