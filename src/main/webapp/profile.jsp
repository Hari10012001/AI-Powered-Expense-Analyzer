<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.expenses.model.User" %>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
User user = (User) request.getAttribute("user");
String msg = request.getParameter("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <title>User Profile</title>
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
            <a class="nav-link" href="ReportServlet">Reports</a>
            <a class="nav-link" href="AnalysisServlet">Analysis</a>
            <a class="nav-link" href="BillScanServlet">Bill Scan</a>
            <a class="nav-link is-active" href="ProfileServlet">Profile</a>
            <a class="nav-link danger" href="AuthServlet?action=logout">Logout</a>
        </nav>
    </div>
</header>

<main class="page-wrap">
    <section class="page-head reveal">
        <div>
            <h2>User Profile Module</h2>
            <p class="page-sub">Maintain account details and secure login credentials.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Keep identity data updated to ensure accurate ownership and secure access.</p>
        <div class="action-row">
            <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
            <a class="btn ghost" href="ReportServlet">Reports</a>
            <a class="btn secondary" href="AuthServlet?action=logout">Logout</a>
        </div>
    </section>

    <div class="flash-wrap">
        <% if (msg != null) { %><div class="flash ok" data-flash><%= msg %></div><% } %>
        <% if (error != null) { %><div class="flash err" data-flash><%= error %></div><% } %>
    </div>

    <section class="panel reveal delay-1" style="max-width:680px;margin:0 auto;">
        <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Profile Details</h3>
        <% if (user == null) { %>
            <div class="empty" style="margin-bottom:10px;">Unable to load profile data. Refresh this page once and try again.</div>
        <% } %>
        <form class="form-stack" action="ProfileServlet" method="post">
            <label>Full Name</label>
            <input type="text" name="name" required value="<%= user == null ? "" : user.getName() %>">
            <label>Email</label>
            <input type="email" name="email" required value="<%= user == null ? "" : user.getEmail() %>">
            <label>New Password (optional)</label>
            <input type="password" name="password" placeholder="Leave blank to keep current password">
            <div class="tag">Password is unchanged if this field is empty.</div>
            <button type="submit">Update Profile</button>
        </form>
    </section>
</main>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
