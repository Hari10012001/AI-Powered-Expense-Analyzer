<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId != null) {
    response.sendRedirect("dashboard.jsp");
    return;
}
String msg = request.getParameter("msg");
String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <title>AI-Powered Expenses Analyzer</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/css/app.css?v=20260304">
</head>
<body class="app-body">
<div class="auth-shell">
    <section class="auth-hero reveal">
        <span class="tag">Personal Finance Workspace</span>
        <h1>Expense Analyzer</h1>
        <p>Professional workspace for capturing daily transactions, monitoring spend behavior, and taking confident monthly money decisions.</p>
        <ul class="auth-list">
            <li>Reliable income and expense operations with full edit/delete flow</li>
            <li>Daily, monthly, yearly report engine with net savings visibility</li>
            <li>Dashboard-grade charts: category split, monthly comparison, yearly trend</li>
            <li>AI-assisted bill extraction via OCR text and image parsing</li>
        </ul>
        <p><span class="tag">Live Project UI</span> <span class="tag">Tomcat + JSP + Servlet</span> <span class="tag">MySQL + H2 Fallback</span></p>
    </section>

    <section class="auth-card reveal delay-1">
        <h2 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Account Access</h2>
        <p class="page-sub" style="margin-top:6px;margin-bottom:14px;">Sign in to continue with your personalized finance dashboard.</p>

        <div class="flash-wrap">
            <% if (msg != null) { %>
                <div class="flash ok" data-flash><%= msg %></div>
            <% } %>
            <% if (error != null) { %>
                <div class="flash err" data-flash><%= error %></div>
            <% } %>
        </div>

        <div class="auth-tabs">
            <button type="button" class="tab-btn is-active" data-tab-target="loginPane">Login</button>
            <button type="button" class="tab-btn" data-tab-target="registerPane">Register</button>
        </div>

        <div id="loginPane" class="tab-pane is-active" data-tab-pane>
            <form class="form-stack" action="AuthServlet" method="post">
                <input type="hidden" name="action" value="login">
                <label>Email</label>
                <input type="email" name="email" placeholder="you@example.com" required>
                <label>Password</label>
                <input type="password" name="password" placeholder="Enter password" required>
                <button type="submit">Login to Dashboard</button>
            </form>
            <p class="page-sub" style="margin-top:10px;">Demo account: <span class="kbd">admin@example.com</span> / <span class="kbd">admin123</span></p>
        </div>

        <div id="registerPane" class="tab-pane" data-tab-pane>
            <form class="form-stack" action="AuthServlet" method="post">
                <input type="hidden" name="action" value="register">
                <label>Full Name</label>
                <input type="text" name="name" placeholder="Your name" required>
                <label>Email</label>
                <input type="email" name="email" placeholder="you@example.com" required>
                <label>Password</label>
                <input type="password" name="password" placeholder="Create password" required>
                <button type="submit" class="secondary">Create Account</button>
            </form>
        </div>
    </section>
</div>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
