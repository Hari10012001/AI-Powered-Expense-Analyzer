<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
Integer userId = (Integer) session.getAttribute("userId");
if (userId == null) {
    response.sendRedirect("login.jsp?error=Please%20login%20first");
    return;
}
String msg = request.getParameter("msg");
if (msg == null) msg = (String) request.getAttribute("msg");
String error = request.getParameter("error");
if (error == null) error = (String) request.getAttribute("error");
String ocrText = (String) request.getAttribute("ocrText");
if (ocrText == null) ocrText = "";
String extractedAmount = (String) request.getAttribute("extractedAmount");
if (extractedAmount == null) extractedAmount = "";
String extractedDate = (String) request.getAttribute("extractedDate");
if (extractedDate == null) extractedDate = java.time.LocalDate.now().toString();
String extractedCategory = (String) request.getAttribute("extractedCategory");
if (extractedCategory == null) extractedCategory = "Misc";
String uploadedImageFile = (String) request.getAttribute("uploadedImageFile");
if (uploadedImageFile == null) uploadedImageFile = "";
String uploadedOcrFile = (String) request.getAttribute("uploadedOcrFile");
if (uploadedOcrFile == null) uploadedOcrFile = "";
String ocrSource = (String) request.getAttribute("ocrSource");
if (ocrSource == null) ocrSource = "";
%>
<!DOCTYPE html>
<html>
<head>
    <title>AI Bill Scan</title>
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
            <a class="nav-link is-active" href="BillScanServlet">Bill Scan</a>
            <a class="nav-link" href="ProfileServlet">Profile</a>
            <a class="nav-link danger" href="AuthServlet?action=logout">Logout</a>
        </nav>
    </div>
</header>

<main class="page-wrap">
    <section class="page-head reveal">
        <div>
            <h2>AI Bill Scanning Module</h2>
            <p class="page-sub">Upload OCR text file or paste OCR content, extract fields, and save as expense entry.</p>
        </div>
        <div class="live-clock">Live <span data-live-clock></span></div>
    </section>

    <section class="page-actions reveal delay-1">
        <p class="page-sub">Capture bill data, validate fields, and push directly into expense history.</p>
        <div class="action-row">
            <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
            <a class="btn ghost" href="ExpenseServlet">Expense List</a>
            <a class="btn secondary" href="ReportServlet">Open Reports</a>
        </div>
    </section>

    <div class="flash-wrap">
        <% if (msg != null) { %><div class="flash ok" data-flash><%= msg %></div><% } %>
        <% if (error != null) { %><div class="flash err" data-flash><%= error %></div><% } %>
    </div>

    <section class="grid-2">
        <article class="panel reveal delay-1">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Step 1: Provide Bill Inputs</h3>
            <form class="form-stack" action="BillScanServlet" method="post" enctype="multipart/form-data">
                <input type="hidden" name="action" value="extract">
                <label>Bill Image (optional reference)</label>
                <input type="file" name="billImage" accept="image/*">
                <label>OCR Text File (.txt)</label>
                <input type="file" name="ocrFile" accept=".txt,text/plain">
                <label>OCR Text (paste extracted text)</label>
                <textarea name="ocrText" rows="10" placeholder="Grand Total Rs 1200 Date 03-03-2026 Grocery"><%= ocrText %></textarea>
                <button type="submit">Extract Bill Fields</button>
            </form>
            <p class="page-sub" style="margin-top:8px;">Tip: Image-only OCR is enabled (Tesseract). For best accuracy, upload clear bill images or paste OCR text.</p>
        </article>

        <article class="panel reveal delay-2">
            <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Step 2: Review &amp; Save</h3>
            <% if (!uploadedImageFile.isEmpty()) { %><div class="tag">Image: <%= uploadedImageFile %></div><% } %>
            <% if (!uploadedOcrFile.isEmpty()) { %><div class="tag">OCR file: <%= uploadedOcrFile %></div><% } %>
            <% if (!ocrSource.isEmpty()) { %><div class="tag">Extracted via: <%= ocrSource %></div><% } %>
            <% if (ocrText.isEmpty()) { %>
                <div class="empty" style="margin-top:10px;">No OCR payload loaded yet. Upload a bill image or OCR text file to continue.</div>
            <% } %>
            <form class="form-stack" action="BillScanServlet" method="post" style="margin-top:10px;">
                <input type="hidden" name="action" value="save">
                <label>Amount</label>
                <input type="number" step="0.01" min="0" name="amount" required value="<%= extractedAmount %>">
                <label>Date</label>
                <input type="date" name="date" required value="<%= extractedDate %>">
                <label>Category</label>
                <input type="text" name="category" required value="<%= extractedCategory %>">
                <button type="submit" class="secondary">Save To Expense List</button>
            </form>
        </article>
    </section>
</main>
<script src="assets/js/app.js?v=20260304"></script>
</body>
</html>
