package com.expenses.controller;

import com.expenses.dao.ExpenseDAO;
import com.expenses.model.Expense;
import com.expenses.util.SessionUtil;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ExpenseServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ExpenseDAO dao = new ExpenseDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Integer userId = SessionUtil.getUserId(request);
        if (userId == null) {
            response.sendRedirect("login.jsp?error=Please%20login%20first");
            return;
        }

        String action = request.getParameter("action");
        if ("delete".equalsIgnoreCase(action)) {
            int id = parseInt(request.getParameter("id"));
            if (id > 0) {
                dao.deleteExpense(id, userId);
            }
            response.sendRedirect("ExpenseServlet?msg=Expense%20deleted");
            return;
        }

        Expense editExpense = null;
        if ("edit".equalsIgnoreCase(action)) {
            int id = parseInt(request.getParameter("id"));
            if (id > 0) {
                editExpense = dao.getExpenseByIdForUser(id, userId);
            }
        }

        List<Expense> expenses = dao.getAllExpenses(userId);
        request.setAttribute("expenses", expenses);
        request.setAttribute("editExpense", editExpense);
        request.getRequestDispatcher("expense.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Integer userId = SessionUtil.getUserId(request);
        if (userId == null) {
            response.sendRedirect("login.jsp?error=Please%20login%20first");
            return;
        }

        int id = parseInt(request.getParameter("id"));
        double amount = parseDouble(request.getParameter("amount"));
        String category = trim(request.getParameter("category"));
        String date = normalizeDate(request.getParameter("date"));

        if (amount <= 0 || category.isEmpty() || date.isEmpty()) {
            response.sendRedirect("ExpenseServlet?error=Please%20enter%20valid%20amount%2C%20category%2C%20and%20date");
            return;
        }

        boolean ok;
        if (id > 0) {
            ok = dao.updateExpense(id, userId, amount, category, date);
        } else {
            ok = dao.addExpense(userId, amount, category, date);
        }

        if (ok) {
            response.sendRedirect("ExpenseServlet?msg=Expense%20saved%20successfully");
        } else {
            response.sendRedirect("ExpenseServlet?error=Unable%20to%20save%20expense");
        }
    }

    private int parseInt(String value) {
        try {
            return Integer.parseInt(value);
        } catch (Exception e) {
            return 0;
        }
    }

    private double parseDouble(String value) {
        try {
            String normalized = value == null ? "" : value.trim().replace(",", "");
            return Double.parseDouble(normalized);
        } catch (Exception e) {
            return 0.0;
        }
    }

    private String normalizeDate(String raw) {
        String value = trim(raw).replace('/', '-');
        if (value.isEmpty()) {
            return "";
        }

        DateTimeFormatter[] formats = new DateTimeFormatter[] {
                DateTimeFormatter.ISO_LOCAL_DATE,
                DateTimeFormatter.ofPattern("dd-MM-yyyy", Locale.ENGLISH),
                DateTimeFormatter.ofPattern("MM-dd-yyyy", Locale.ENGLISH),
                DateTimeFormatter.ofPattern("dd-MM-yy", Locale.ENGLISH),
                DateTimeFormatter.ofPattern("MM-dd-yy", Locale.ENGLISH)
        };

        for (DateTimeFormatter format : formats) {
            try {
                return LocalDate.parse(value, format).toString();
            } catch (DateTimeParseException ignored) {
            }
        }
        return "";
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }
}
