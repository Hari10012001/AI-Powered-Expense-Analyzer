package com.expenses.controller;

import com.expenses.dao.ExpenseDAO;
import com.expenses.dao.IncomeDAO;
import com.expenses.util.SessionUtil;
import java.io.IOException;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class AnalysisServlet extends HttpServlet {
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

        LocalDate today = LocalDate.now();
        YearMonth currentMonth = YearMonth.from(today);
        int currentYear = today.getYear();

        double dailyIncome = incomeDAO.getTotalByDate(userId, today);
        double dailyExpense = expenseDAO.getTotalByDate(userId, today);
        double monthlyIncome = incomeDAO.getTotalByMonth(userId, currentMonth);
        double monthlyExpense = expenseDAO.getTotalByMonth(userId, currentMonth);
        double yearlyIncome = incomeDAO.getTotalByYear(userId, currentYear);
        double yearlyExpense = expenseDAO.getTotalByYear(userId, currentYear);

        Map<String, Double> categoryTotals = expenseDAO.getCategoryTotals(userId);
        Map<String, Double> monthlyExpenseRaw = expenseDAO.getMonthlyTotals(userId, currentYear);
        Map<String, Double> monthlyIncomeRaw = incomeDAO.getMonthlyTotals(userId, currentYear);
        Map<Integer, Double> yearlyExpenseMap = expenseDAO.getYearlyTotals(userId);

        Map<String, Double> monthlyExpenseMap = normalizeMonthMap(monthlyExpenseRaw);
        Map<String, Double> monthlyIncomeMap = normalizeMonthMap(monthlyIncomeRaw);

        String highestCategory = "-";
        double highestCategoryAmount = 0;
        for (Map.Entry<String, Double> entry : categoryTotals.entrySet()) {
            if (entry.getValue() > highestCategoryAmount) {
                highestCategory = entry.getKey();
                highestCategoryAmount = entry.getValue();
            }
        }

        String highestMonth = "-";
        String lowestMonth = "-";
        double highestMonthValue = -1;
        double lowestMonthValue = Double.MAX_VALUE;

        for (Map.Entry<String, Double> entry : monthlyExpenseMap.entrySet()) {
            double value = entry.getValue();
            if (value > highestMonthValue) {
                highestMonthValue = value;
                highestMonth = entry.getKey();
            }
            if (value < lowestMonthValue) {
                lowestMonthValue = value;
                lowestMonth = entry.getKey();
            }
        }

        request.setAttribute("today", today.toString());
        request.setAttribute("currentYear", currentYear);

        request.setAttribute("dailyIncome", dailyIncome);
        request.setAttribute("dailyExpense", dailyExpense);
        request.setAttribute("dailySavings", dailyIncome - dailyExpense);

        request.setAttribute("monthlyIncome", monthlyIncome);
        request.setAttribute("monthlyExpense", monthlyExpense);
        request.setAttribute("monthlySavings", monthlyIncome - monthlyExpense);

        request.setAttribute("yearlyIncome", yearlyIncome);
        request.setAttribute("yearlyExpense", yearlyExpense);
        request.setAttribute("yearlySavings", yearlyIncome - yearlyExpense);

        request.setAttribute("highestCategory", highestCategory);
        request.setAttribute("highestCategoryAmount", highestCategoryAmount);
        request.setAttribute("highestMonth", highestMonth);
        request.setAttribute("lowestMonth", lowestMonth);

        request.setAttribute("categoryTotals", categoryTotals);
        request.setAttribute("monthlyExpenseMap", monthlyExpenseMap);
        request.setAttribute("monthlyIncomeMap", monthlyIncomeMap);
        request.setAttribute("yearlyExpenseMap", yearlyExpenseMap);

        request.getRequestDispatcher("analyzer.jsp").forward(request, response);
    }

    private Map<String, Double> normalizeMonthMap(Map<String, Double> raw) {
        Map<String, Double> out = new LinkedHashMap<>();
        for (int i = 1; i <= 12; i++) {
            String key = String.format("%02d", i);
            double value = raw.containsKey(key) ? raw.get(key) : 0.0;
            String label = YearMonth.of(2000, i).getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH);
            out.put(label, value);
        }
        return out;
    }
}
