<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="com.expenses.model.Expense" %>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
List<?> expenses = (List<?>) request.getAttribute("expenses");
Expense editExpense = (Expense) request.getAttribute("editExpense");
String msg = request.getParameter("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Expense Management</title>
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
            <a class="nav-link is-active" href="ExpenseServlet">Expenses</a>
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
            <h2>Expense Management</h2>
            <p class="page-sub">Record category-based expenses and keep data accurate with edit/delete controls.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Maintain day-to-day spending records and audit every transaction quickly.</p>
        <div class="action-row">
            <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
            <a class="btn secondary" href="BillScanServlet">Open Bill Scan</a>
            <a class="btn" href="AnalysisServlet">Open Analysis</a>
        </div>
    </section>

    <div class="flash-wrap">
        <% if (msg != null) { %><div class="flash ok" data-flash><%= msg %></div><% } %>
        <% if (error != null) { %><div class="flash err" data-flash><%= error %></div><% } %>
    </div>

    <section class="grid-2">
        <article class="panel reveal delay-1">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;"><%= editExpense != null ? "Edit Expense Entry" : "Add Expense Entry" %></h3>
            <form class="form-stack" action="ExpenseServlet" method="post">
                <input type="hidden" name="id" value="<%= editExpense == null ? "" : editExpense.getId() %>">
                <label>Amount</label>
                <input type="number" step="0.01" min="0" name="amount" required value="<%= editExpense == null ? "" : editExpense.getAmount() %>">
                <label>Category</label>
                <input type="text" name="category" placeholder="Food / Travel / Rent / Utilities" required value="<%= editExpense == null ? "" : editExpense.getCategory() %>">
                <label>Date</label>
                <input type="date" name="date" required value="<%= editExpense == null ? "" : editExpense.getDate() %>">
                <button type="submit"><%= editExpense != null ? "Update Expense" : "Save Expense" %></button>
                <% if (editExpense != null) { %>
                    <a class="btn ghost" href="ExpenseServlet">Cancel Edit</a>
                <% } %>
                <a class="btn secondary" href="BillScanServlet">Open AI Bill Scan</a>
            </form>
        </article>

        <article class="panel reveal delay-2">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Expense History</h3>
            <p class="page-sub history-meta">Sorted by latest entry ID (newest first).</p>
            <% if (expenses != null && !expenses.isEmpty()) { %>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Date</th>
                                <th>Category</th>
                                <th>Amount</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Object obj : expenses) { Expense expense = (Expense) obj; %>
                                <tr>
                                    <td><span class="id-pill">#<%= expense.getId() %></span></td>
                                    <td><%= expense.getDate() %></td>
                                    <td><%= expense.getCategory() %></td>
                                    <td class="amount-cell">Rs <%= String.format("%.2f", expense.getAmount()) %></td>
                                    <td class="action-cell">
                                        <a class="btn ghost" href="ExpenseServlet?action=edit&id=<%= expense.getId() %>">Edit</a>
                                        <a class="btn warn" href="ExpenseServlet?action=delete&id=<%= expense.getId() %>" onclick="return confirm('Delete this expense entry?');">Delete</a>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                </div>
            <% } else { %>
                <div class="empty">
                    No expense entries found. Add your first expense record.
                    <div style="margin-top:10px;"><a class="btn secondary" href="BillScanServlet">Extract from Bill</a></div>
                </div>
            <% } %>
        </article>
    </section>
</main>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
