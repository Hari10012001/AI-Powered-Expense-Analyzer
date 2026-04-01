package com.expenses.controller;

import com.expenses.dao.ExpenseDAO;
import com.expenses.dao.IncomeDAO;
import com.expenses.model.Expense;
import com.expenses.model.Income;
import com.expenses.util.SessionUtil;
import java.io.IOException;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ReportServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ExpenseDAO expenseDAO = new ExpenseDAO();
    private final IncomeDAO incomeDAO = new IncomeDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        Integer userId = SessionUtil.getUserId(request);
        if (userId == null) {
            response.sendRedirect("login.jsp?error=Please%20login%20first");
            return;
        }

        String period = valueOrDefault(request.getParameter("period"), "daily").toLowerCase();
        LocalDate selectedDate = LocalDate.now();
        YearMonth selectedMonth = YearMonth.now();
        int selectedYear = LocalDate.now().getYear();

        List<Expense> expenseList;
        List<Income> incomeList;
        double totalExpense;
        double totalIncome;

        if ("monthly".equals(period)) {
            String monthParam = request.getParameter("month");
            if (monthParam != null && !monthParam.trim().isEmpty()) {
                try {
                    selectedMonth = YearMonth.parse(monthParam.trim());
                } catch (Exception ignored) {
                    selectedMonth = YearMonth.now();
                }
            }
            expenseList = expenseDAO.getExpensesByMonth(userId, selectedMonth);
            incomeList = incomeDAO.getIncomesByMonth(userId, selectedMonth);
            totalExpense = expenseDAO.getTotalByMonth(userId, selectedMonth);
            totalIncome = incomeDAO.getTotalByMonth(userId, selectedMonth);
        } else if ("yearly".equals(period)) {
            String yearParam = request.getParameter("year");
            if (yearParam != null && !yearParam.trim().isEmpty()) {
                try {
                    selectedYear = Integer.parseInt(yearParam.trim());
                } catch (NumberFormatException ignored) {
                    selectedYear = LocalDate.now().getYear();
                }
            }
            expenseList = expenseDAO.getExpensesByYear(userId, selectedYear);
            incomeList = incomeDAO.getIncomesByYear(userId, selectedYear);
            totalExpense = expenseDAO.getTotalByYear(userId, selectedYear);
            totalIncome = incomeDAO.getTotalByYear(userId, selectedYear);
        } else {
            period = "daily";
            String dateParam = request.getParameter("date");
            if (dateParam != null && !dateParam.trim().isEmpty()) {
                try {
                    selectedDate = LocalDate.parse(dateParam.trim());
                } catch (Exception ignored) {
                    selectedDate = LocalDate.now();
                }
            }
            expenseList = expenseDAO.getExpensesByDate(userId, selectedDate);
            incomeList = incomeDAO.getIncomesByDate(userId, selectedDate);
            totalExpense = expenseDAO.getTotalByDate(userId, selectedDate);
            totalIncome = incomeDAO.getTotalByDate(userId, selectedDate);
        }

        request.setAttribute("period", period);
        request.setAttribute("selectedDate", selectedDate.toString());
        request.setAttribute("selectedMonth", selectedMonth.toString());
        request.setAttribute("selectedYear", selectedYear);
        request.setAttribute("expenseList", expenseList);
        request.setAttribute("incomeList", incomeList);
        request.setAttribute("totalExpense", totalExpense);
        request.setAttribute("totalIncome", totalIncome);
        request.setAttribute("netAmount", totalIncome - totalExpense);
        request.getRequestDispatcher("report.jsp").forward(request, response);
    }

    private String valueOrDefault(String value, String defaultValue) {
        return value == null ? defaultValue : value;
    }
}
