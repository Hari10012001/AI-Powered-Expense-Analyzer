package com.expenses.controller;

import com.expenses.dao.IncomeDAO;
import com.expenses.model.Income;
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

public class IncomeServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final IncomeDAO dao = new IncomeDAO();

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
                dao.deleteIncome(id, userId);
            }
            response.sendRedirect("IncomeServlet?msg=Income%20deleted");
            return;
        }

        Income editIncome = null;
        if ("edit".equalsIgnoreCase(action)) {
            int id = parseInt(request.getParameter("id"));
            if (id > 0) {
                editIncome = dao.getIncomeByIdForUser(id, userId);
            }
        }

        List<Income> incomes = dao.getAllIncomes(userId);
        request.setAttribute("incomes", incomes);
        request.setAttribute("editIncome", editIncome);
        request.getRequestDispatcher("income.jsp").forward(request, response);
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
        String source = trim(request.getParameter("source"));
        String date = normalizeDate(request.getParameter("date"));

        if (amount <= 0 || source.isEmpty() || date.isEmpty()) {
            response.sendRedirect("IncomeServlet?error=Please%20enter%20valid%20amount%2C%20source%2C%20and%20date");
            return;
        }

        boolean ok;
        if (id > 0) {
            ok = dao.updateIncome(id, userId, amount, source, date);
        } else {
            ok = dao.addIncome(userId, amount, source, date);
        }

        if (ok) {
            response.sendRedirect("IncomeServlet?msg=Income%20saved%20successfully");
        } else {
            response.sendRedirect("IncomeServlet?error=Unable%20to%20save%20income");
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
