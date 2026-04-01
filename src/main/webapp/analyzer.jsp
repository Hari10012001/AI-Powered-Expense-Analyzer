<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.Map" %>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
Map<?, ?> categoryTotals = (Map<?, ?>) request.getAttribute("categoryTotals");
Map<?, ?> monthlyExpenseMap = (Map<?, ?>) request.getAttribute("monthlyExpenseMap");
Map<?, ?> monthlyIncomeMap = (Map<?, ?>) request.getAttribute("monthlyIncomeMap");
Map<?, ?> yearlyExpenseMap = (Map<?, ?>) request.getAttribute("yearlyExpenseMap");

if (categoryTotals == null || monthlyExpenseMap == null || monthlyIncomeMap == null || yearlyExpenseMap == null) {
    response.sendRedirect("AnalysisServlet");
    return;
}

double dailyIncome = (Double) request.getAttribute("dailyIncome");
double dailyExpense = (Double) request.getAttribute("dailyExpense");
double dailySavings = (Double) request.getAttribute("dailySavings");

double monthlyIncome = (Double) request.getAttribute("monthlyIncome");
double monthlyExpense = (Double) request.getAttribute("monthlyExpense");
double monthlySavings = (Double) request.getAttribute("monthlySavings");

double yearlyIncome = (Double) request.getAttribute("yearlyIncome");
double yearlyExpense = (Double) request.getAttribute("yearlyExpense");
double yearlySavings = (Double) request.getAttribute("yearlySavings");

String highestCategory = (String) request.getAttribute("highestCategory");
double highestCategoryAmount = (Double) request.getAttribute("highestCategoryAmount");
String highestMonth = (String) request.getAttribute("highestMonth");
String lowestMonth = (String) request.getAttribute("lowestMonth");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Analysis &amp; Charts</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="assets/css/app.css?v=20260304">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
            <a class="nav-link is-active" href="AnalysisServlet">Analysis</a>
            <a class="nav-link" href="BillScanServlet">Bill Scan</a>
            <a class="nav-link" href="ProfileServlet">Profile</a>
            <a class="nav-link danger" href="AuthServlet?action=logout">Logout</a>
        </nav>
    </div>
</header>

<main class="page-wrap">
    <section class="page-head reveal">
        <div>
            <h2>Graph &amp; Analysis Module</h2>
            <p class="page-sub">Visual insights for daily, monthly, and yearly financial behavior.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Live chart layer for trend reading, category hotspots, and savings direction.</p>
        <div class="action-row">
            <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
            <a class="btn ghost" href="ReportServlet">View Reports</a>
            <a class="btn secondary" href="ExpenseServlet">Update Expenses</a>
            <a class="btn" href="AnalysisServlet">Refresh</a>
        </div>
    </section>

    <section class="grid-auto reveal delay-1" style="margin-bottom:14px;">
        <article class="metric-card"><p class="metric-label">Daily Savings</p><p class="metric-value">Rs <%= String.format("%.2f", dailySavings) %></p></article>
        <article class="metric-card"><p class="metric-label">Monthly Savings</p><p class="metric-value">Rs <%= String.format("%.2f", monthlySavings) %></p></article>
        <article class="metric-card"><p class="metric-label">Yearly Savings</p><p class="metric-value">Rs <%= String.format("%.2f", yearlySavings) %></p></article>
        <article class="metric-card"><p class="metric-label">Highest Category</p><p class="metric-value" style="font-size:20px;"><%= highestCategory %></p><p class="page-sub">Rs <%= String.format("%.2f", highestCategoryAmount) %></p></article>
        <article class="metric-card"><p class="metric-label">Highest Spend Month</p><p class="metric-value" style="font-size:20px;"><%= highestMonth %></p></article>
        <article class="metric-card"><p class="metric-label">Lowest Spend Month</p><p class="metric-value" style="font-size:20px;"><%= lowestMonth %></p></article>
    </section>

    <section class="grid-3">
        <article class="panel chart-box reveal delay-1">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Category-wise Expense</h3>
            <canvas id="categoryPie"></canvas>
        </article>
        <article class="panel chart-box reveal delay-2">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Monthly Income vs Expense</h3>
            <canvas id="monthlyBar"></canvas>
        </article>
        <article class="panel chart-box reveal delay-3">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Yearly Expense Trend</h3>
            <canvas id="yearlyLine"></canvas>
        </article>
    </section>
</main>

<script>
const categoryLabels = [
<%
boolean first = true;
for (Object keyObj : categoryTotals.keySet()) {
    String key = String.valueOf(keyObj);
    if (!first) out.print(",");
    out.print("'" + key.replace("'", "\\'") + "'");
    first = false;
}
%>
];
const categoryValues = [
<%
first = true;
for (Object valueObj : categoryTotals.values()) {
    double value = valueObj instanceof Number ? ((Number) valueObj).doubleValue() : 0.0;
    if (!first) out.print(",");
    out.print(String.format(java.util.Locale.US, "%.2f", value));
    first = false;
}
%>
];
const monthLabels = [
<%
first = true;
for (Object keyObj : monthlyExpenseMap.keySet()) {
    String key = String.valueOf(keyObj);
    if (!first) out.print(",");
    out.print("'" + key + "'");
    first = false;
}
%>
];
const monthlyExpenseValues = [
<%
first = true;
for (Object valueObj : monthlyExpenseMap.values()) {
    double value = valueObj instanceof Number ? ((Number) valueObj).doubleValue() : 0.0;
    if (!first) out.print(",");
    out.print(String.format(java.util.Locale.US, "%.2f", value));
    first = false;
}
%>
];
const monthlyIncomeValues = [
<%
first = true;
for (Object valueObj : monthlyIncomeMap.values()) {
    double value = valueObj instanceof Number ? ((Number) valueObj).doubleValue() : 0.0;
    if (!first) out.print(",");
    out.print(String.format(java.util.Locale.US, "%.2f", value));
    first = false;
}
%>
];
const yearLabels = [
<%
first = true;
for (Object keyObj : yearlyExpenseMap.keySet()) {
    String key = String.valueOf(keyObj);
    if (!first) out.print(",");
    out.print("'" + key + "'");
    first = false;
}
%>
];
const yearValues = [
<%
first = true;
for (Object valueObj : yearlyExpenseMap.values()) {
    double value = valueObj instanceof Number ? ((Number) valueObj).doubleValue() : 0.0;
    if (!first) out.print(",");
    out.print(String.format(java.util.Locale.US, "%.2f", value));
    first = false;
}
%>
];

var categoryChart;
var monthlyChart;
var yearlyChart;

function getCssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

function getChartTheme() {
    return {
        text: getCssVar('--chart-text') || '#2f435e',
        grid: getCssVar('--chart-grid') || 'rgba(47, 67, 94, 0.16)',
        income: getCssVar('--chart-income') || '#0f7a75',
        expense: getCssVar('--chart-expense') || '#ea580c',
        line: getCssVar('--chart-line') || '#2153c9',
        lineFill: getCssVar('--chart-line-fill') || 'rgba(33, 83, 201, 0.16)',
        tooltipBg: getCssVar('--chart-tooltip-bg') || 'rgba(15, 27, 45, 0.9)',
        tooltipText: getCssVar('--chart-tooltip-text') || '#f3f8ff',
        pie: [
            getCssVar('--chart-palette-1') || '#0f7a75',
            getCssVar('--chart-palette-2') || '#2563eb',
            getCssVar('--chart-palette-3') || '#f97316',
            getCssVar('--chart-palette-4') || '#f43f5e',
            getCssVar('--chart-palette-5') || '#8b5cf6',
            getCssVar('--chart-palette-6') || '#22c55e',
            getCssVar('--chart-palette-7') || '#06b6d4'
        ]
    };
}

function commonChartPlugins(theme) {
    return {
        legend: {
            position: 'bottom',
            labels: {
                color: theme.text,
                boxWidth: 12,
                boxHeight: 12
            }
        },
        tooltip: {
            backgroundColor: theme.tooltipBg,
            titleColor: theme.tooltipText,
            bodyColor: theme.tooltipText,
            borderColor: theme.grid,
            borderWidth: 1
        }
    };
}

function buildCharts() {
    if (!window.Chart) {
        return;
    }

    var theme = getChartTheme();
    Chart.defaults.color = theme.text;

    if (categoryChart) categoryChart.destroy();
    if (monthlyChart) monthlyChart.destroy();
    if (yearlyChart) yearlyChart.destroy();

    categoryChart = new Chart(document.getElementById('categoryPie'), {
        type: 'doughnut',
        data: {
            labels: categoryLabels,
            datasets: [{
                data: categoryValues,
                backgroundColor: theme.pie
            }]
        },
        options: {
            responsive: true,
            plugins: commonChartPlugins(theme)
        }
    });

    monthlyChart = new Chart(document.getElementById('monthlyBar'), {
        type: 'bar',
        data: {
            labels: monthLabels,
            datasets: [
                { label: 'Income', data: monthlyIncomeValues, backgroundColor: theme.income },
                { label: 'Expense', data: monthlyExpenseValues, backgroundColor: theme.expense }
            ]
        },
        options: {
            responsive: true,
            plugins: commonChartPlugins(theme),
            scales: {
                x: { ticks: { color: theme.text }, grid: { color: theme.grid } },
                y: { ticks: { color: theme.text }, grid: { color: theme.grid } }
            }
        }
    });

    yearlyChart = new Chart(document.getElementById('yearlyLine'), {
        type: 'line',
        data: {
            labels: yearLabels,
            datasets: [{
                label: 'Expense',
                data: yearValues,
                borderColor: theme.line,
                backgroundColor: theme.lineFill,
                fill: true,
                tension: 0.25
            }]
        },
        options: {
            responsive: true,
            plugins: commonChartPlugins(theme),
            scales: {
                x: { ticks: { color: theme.text }, grid: { color: theme.grid } },
                y: { ticks: { color: theme.text }, grid: { color: theme.grid } }
            }
        }
    });
}

buildCharts();
document.addEventListener('expense-theme-change', buildCharts);
</script>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
