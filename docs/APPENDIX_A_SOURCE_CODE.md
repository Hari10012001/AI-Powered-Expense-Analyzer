    # APPENDIX A - SOURCE CODE

    This appendix contains the full text-based project source code used by the AI-Powered Expenses Analyzer application.

    ## src/main/java/com/expenses/controller/AuthServlet.java

    ```java
    package com.expenses.controller;

    import com.expenses.dao.UserDAO;
    import com.expenses.model.User;
    import java.io.IOException;
    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;
    import javax.servlet.http.HttpSession;

    public class AuthServlet extends HttpServlet {
        private static final long serialVersionUID = 1L;
        private final UserDAO userDAO = new UserDAO();

        @Override
        protected void doGet(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            String action = valueOrDefault(request.getParameter("action"), "");
            if ("logout".equalsIgnoreCase(action)) {
                HttpSession session = request.getSession(false);
                if (session != null) {
                    session.invalidate();
                }
                response.sendRedirect("login.jsp?msg=Logged%20out%20successfully");
                return;
            }
            response.sendRedirect("login.jsp");
        }

        @Override
        protected void doPost(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            String action = valueOrDefault(request.getParameter("action"), "login");
            if ("register".equalsIgnoreCase(action)) {
                register(request, response);
            } else {
                login(request, response);
            }
        }

        private void login(HttpServletRequest request, HttpServletResponse response) throws IOException {
            String email = valueOrDefault(request.getParameter("email"), request.getParameter("EmailId")).trim();
            String password = valueOrDefault(request.getParameter("password"), "").trim();

            User user = userDAO.authenticate(email, password);
            if (user == null) {
                response.sendRedirect("login.jsp?error=Invalid%20email%20or%20password");
                return;
            }

            HttpSession session = request.getSession(true);
            session.setAttribute("userId", user.getId());
            session.setAttribute("userName", user.getName());
            session.setAttribute("userEmail", user.getEmail());
            response.sendRedirect("dashboard.jsp");
        }

        private void register(HttpServletRequest request, HttpServletResponse response) throws IOException {
            String name = valueOrDefault(request.getParameter("name"), "").trim();
            String email = valueOrDefault(request.getParameter("email"), "").trim();
            String password = valueOrDefault(request.getParameter("password"), "").trim();

            if (name.isEmpty() || email.isEmpty() || password.isEmpty()) {
                response.sendRedirect("login.jsp?error=Please%20fill%20all%20registration%20fields");
                return;
            }

            boolean created = userDAO.registerUser(new User(name, email, password));
            if (!created) {
                response.sendRedirect("login.jsp?error=Registration%20failed%2C%20email%20may%20already%20exist");
                return;
            }

            User user = userDAO.authenticate(email, password);
            HttpSession session = request.getSession(true);
            session.setAttribute("userId", user.getId());
            session.setAttribute("userName", user.getName());
            session.setAttribute("userEmail", user.getEmail());
            response.sendRedirect("dashboard.jsp?msg=Registration%20successful");
        }

        private String valueOrDefault(String value, String defaultValue) {
            return value == null ? defaultValue : value;
        }
    }

    ```

    ## src/main/java/com/expenses/controller/LoginServlet.java

    ```java
    package com.expenses.controller;

    import java.io.IOException;
    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;
    import javax.servlet.http.HttpSession;
    import com.expenses.dao.UserDAO;
    import com.expenses.model.User;

    public class LoginServlet extends HttpServlet {
        private static final long serialVersionUID = 1L;

        protected void doPost(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {

            String email = request.getParameter("EmailId");
            if (email == null || email.trim().isEmpty()) {
                email = request.getParameter("email");
            }
            String password = request.getParameter("password");

            UserDAO dao = new UserDAO();
            User user = dao.authenticate(email == null ? "" : email.trim(), password == null ? "" : password.trim());

            if (user != null) {
                HttpSession session = request.getSession(true);
                session.setAttribute("userId", user.getId());
                session.setAttribute("userName", user.getName());
                session.setAttribute("userEmail", user.getEmail());
                response.sendRedirect("dashboard.jsp");
            } else {
                response.sendRedirect("login.jsp?error=Invalid%20login%20credentials");
            }
        }
    }

    ```

    ## src/main/java/com/expenses/controller/IncomeServlet.java

    ```java
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

    ```

    ## src/main/java/com/expenses/controller/ExpenseServlet.java

    ```java
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

    ```

    ## src/main/java/com/expenses/controller/ReportServlet.java

    ```java
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

    ```

    ## src/main/java/com/expenses/controller/AnalysisServlet.java

    ```java
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

    ```

    ## src/main/java/com/expenses/controller/BillScanServlet.java

    ```java
    package com.expenses.controller;

    import com.expenses.dao.ExpenseDAO;
    import com.expenses.util.SessionUtil;
    import java.io.IOException;
    import java.nio.charset.StandardCharsets;
    import java.nio.file.Files;
    import java.nio.file.Path;
    import java.nio.file.StandardCopyOption;
    import java.time.LocalDate;
    import java.time.format.DateTimeFormatter;
    import java.time.format.DateTimeParseException;
    import java.util.ArrayList;
    import java.util.Arrays;
    import java.util.LinkedHashMap;
    import java.util.List;
    import java.util.Locale;
    import java.util.Map;
    import java.util.concurrent.TimeUnit;
    import java.util.regex.Matcher;
    import java.util.regex.Pattern;
    import javax.servlet.ServletException;
    import javax.servlet.annotation.MultipartConfig;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;
    import javax.servlet.http.Part;

    @MultipartConfig
    public class BillScanServlet extends HttpServlet {
        private static final long serialVersionUID = 1L;
        private final ExpenseDAO expenseDAO = new ExpenseDAO();

        @Override
        protected void doGet(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            Integer userId = SessionUtil.getUserId(request);
            if (userId == null) {
                response.sendRedirect("login.jsp?error=Please%20login%20first");
                return;
            }
            request.getRequestDispatcher("billscan.jsp").forward(request, response);
        }

        @Override
        protected void doPost(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            Integer userId = SessionUtil.getUserId(request);
            if (userId == null) {
                response.sendRedirect("login.jsp?error=Please%20login%20first");
                return;
            }

            String action = param(request, "action", "extract");
            if ("save".equalsIgnoreCase(action)) {
                saveExtractedExpense(request, response, userId);
            } else {
                extract(request, response);
            }
        }

        private void extract(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            String ocrText = param(request, "ocrText", "");
            String ocrSource = "";
            String uploadedImageFile = "";
            String uploadedOcrFile = "";
            String contentType = request.getContentType();
            Part billImage = null;
            Part ocrFile = null;

            if (contentType != null && contentType.toLowerCase().startsWith("multipart/")) {
                billImage = request.getPart("billImage");
                ocrFile = request.getPart("ocrFile");
                uploadedImageFile = billImage == null ? "" : safeFileName(billImage.getSubmittedFileName());
                uploadedOcrFile = ocrFile == null ? "" : safeFileName(ocrFile.getSubmittedFileName());
            }

            if (ocrText.isEmpty() && ocrFile != null && ocrFile.getSize() > 0) {
                ocrText = readPartAsString(ocrFile);
                ocrSource = "OCR text file";
            }

            // If user accidentally uploads .txt in bill image field, treat it as OCR text.
            if (ocrText.isEmpty() && billImage != null && billImage.getSize() > 0 && isTextFilePart(billImage)) {
                ocrText = readPartAsString(billImage);
                ocrSource = "Text file uploaded in bill image field";
            }

            if (ocrText.isEmpty() && billImage != null && billImage.getSize() > 0 && isImageFilePart(billImage)) {
                ocrText = extractTextFromImage(billImage);
                if (!ocrText.isEmpty()) {
                    ocrSource = "Image OCR";
                }
            }

            if (!ocrText.isEmpty() && ocrSource.isEmpty()) {
                ocrSource = "Text area";
            }

            double amount = extractAmount(ocrText);
            String date = extractDate(ocrText);
            String category = guessCategory(ocrText);

            if (ocrText.isEmpty()) {
                request.setAttribute("error",
                        "Unable to extract text. Paste OCR text or install/check Tesseract OCR for image extraction.");
            } else {
                request.setAttribute("msg", "AI-style OCR parser extracted bill fields. Review and save.");
                request.setAttribute("ocrSource", ocrSource);
            }

            request.setAttribute("ocrText", ocrText);
            request.setAttribute("uploadedImageFile", uploadedImageFile);
            request.setAttribute("uploadedOcrFile", uploadedOcrFile);
            request.setAttribute("extractedAmount", amount > 0 ? String.format("%.2f", amount) : "");
            request.setAttribute("extractedDate", date);
            request.setAttribute("extractedCategory", category);
            request.getRequestDispatcher("billscan.jsp").forward(request, response);
        }

        private void saveExtractedExpense(HttpServletRequest request, HttpServletResponse response, int userId)
                throws IOException {
            double amount = parseDouble(param(request, "amount", "0"));
            String date = normalizeDate(param(request, "date", ""));
            String category = param(request, "category", "Misc");
            if (category.isEmpty()) {
                category = "Misc";
            }

            if (amount <= 0 || date.isEmpty()) {
                response.sendRedirect("BillScanServlet?error=Please%20provide%20valid%20date%20and%20amount");
                return;
            }

            boolean saved = expenseDAO.addExpense(userId, amount, category, date);
            if (saved) {
                response.sendRedirect("ExpenseServlet?msg=Bill%20expense%20saved%20successfully");
            } else {
                response.sendRedirect("BillScanServlet?error=Failed%20to%20save%20bill%20expense");
            }
        }

        private double extractAmount(String text) {
            if (text == null || text.trim().isEmpty()) {
                return 0.0;
            }

            String normalizedText = text.replace(",", "");
            List<Double> priority = new ArrayList<>();
            List<Double> fallback = new ArrayList<>();

            Pattern linePattern = Pattern.compile("(?im)^.*$");
            Matcher lines = linePattern.matcher(normalizedText);
            while (lines.find()) {
                String line = lines.group();
                String lower = line.toLowerCase(Locale.ENGLISH);
                Matcher amountMatcher = Pattern.compile("(\\d+(?:\\.\\d{1,2})?)").matcher(line);
                while (amountMatcher.find()) {
                    double value = parseDouble(amountMatcher.group(1));
                    if (value <= 0) {
                        continue;
                    }
                    if (lower.contains("grand total") || lower.contains("net payable") || lower.contains("amount due")) {
                        priority.add(value);
                    } else if (lower.contains("total") || lower.contains("amount") || lower.contains("inr")
                            || lower.contains("rs")) {
                        fallback.add(value);
                    }
                }
            }

            if (!priority.isEmpty()) {
                return max(priority);
            }
            if (!fallback.isEmpty()) {
                return max(fallback);
            }

            Matcher genericMatcher = Pattern.compile("(\\d+(?:\\.\\d{1,2})?)").matcher(normalizedText);
            double candidate = 0.0;
            while (genericMatcher.find()) {
                candidate = Math.max(candidate, parseDouble(genericMatcher.group(1)));
            }
            return candidate;
        }

        private String extractDate(String text) {
            Pattern datePattern = Pattern.compile("(\\d{4}-\\d{2}-\\d{2}|\\d{2}[-/]\\d{2}[-/]\\d{4}|\\d{2}[-/]\\d{2}[-/]\\d{2})");
            Matcher matcher = datePattern.matcher(text);
            if (!matcher.find()) {
                return LocalDate.now().toString();
            }

            String raw = matcher.group(1);
            if (raw.matches("\\d{4}-\\d{2}-\\d{2}")) {
                return raw;
            }

            String normalized = raw.replace('/', '-');
            for (DateTimeFormatter format : new DateTimeFormatter[] {
                    DateTimeFormatter.ofPattern("dd-MM-yyyy"),
                    DateTimeFormatter.ofPattern("MM-dd-yyyy"),
                    DateTimeFormatter.ofPattern("dd-MM-yy"),
                    DateTimeFormatter.ofPattern("MM-dd-yy")
            }) {
                try {
                    return LocalDate.parse(normalized, format).toString();
                } catch (DateTimeParseException ignored) {
                }
            }
            return LocalDate.now().toString();
        }

        private String guessCategory(String text) {
            String lower = text.toLowerCase();
            Map<String, Integer> scores = new LinkedHashMap<>();
            scores.put("Travel", score(lower, "fuel", "petrol", "diesel", "taxi", "uber", "bus", "station"));
            scores.put("Rent", score(lower, "rent", "lease", "landlord", "house rent"));
            scores.put("Groceries", score(lower, "grocery", "supermarket", "market", "mart", "rice", "milk",
                    "oil", "vegetable", "fruit", "apple", "wheat", "sugar", "dal"));
            scores.put("Food", score(lower, "restaurant", "hotel", "food", "snacks", "meal", "fried", "tikka"));
            scores.put("Utilities", score(lower, "electric", "electricity", "water", "internet", "wifi", "gas"));
            scores.put("Shopping", score(lower, "shopping", "mall", "cloth", "fashion", "apparel", "store"));

            String bestCategory = "Misc";
            int bestScore = 0;
            for (Map.Entry<String, Integer> entry : scores.entrySet()) {
                if (entry.getValue() > bestScore) {
                    bestScore = entry.getValue();
                    bestCategory = entry.getKey();
                }
            }
            return bestCategory;
        }

        private String param(HttpServletRequest request, String key, String defaultValue) {
            String value = request.getParameter(key);
            return value == null ? defaultValue : value.trim();
        }

        private boolean isTextFilePart(Part part) {
            String name = safeFileName(part.getSubmittedFileName()).toLowerCase(Locale.ENGLISH);
            String type = part.getContentType() == null ? "" : part.getContentType().toLowerCase(Locale.ENGLISH);
            return name.endsWith(".txt") || type.startsWith("text/");
        }

        private boolean isImageFilePart(Part part) {
            String name = safeFileName(part.getSubmittedFileName()).toLowerCase(Locale.ENGLISH);
            String type = part.getContentType() == null ? "" : part.getContentType().toLowerCase(Locale.ENGLISH);
            return type.startsWith("image/")
                    || name.endsWith(".png")
                    || name.endsWith(".jpg")
                    || name.endsWith(".jpeg")
                    || name.endsWith(".bmp")
                    || name.endsWith(".tif")
                    || name.endsWith(".tiff");
        }

        private String readPartAsString(Part part) throws IOException {
            byte[] bytes = part.getInputStream().readAllBytes();
            if (bytes.length > 1024 * 1024) {
                return "";
            }
            return new String(bytes, StandardCharsets.UTF_8).trim();
        }

        private String extractTextFromImage(Part imagePart) {
            Path tempFile = null;
            try {
                String ext = fileExtension(safeFileName(imagePart.getSubmittedFileName()));
                tempFile = Files.createTempFile("expense-bill-", ext.isEmpty() ? ".png" : ext);
                Files.copy(imagePart.getInputStream(), tempFile, StandardCopyOption.REPLACE_EXISTING);
                return runTesseract(tempFile);
            } catch (Exception e) {
                return "";
            } finally {
                if (tempFile != null) {
                    try {
                        Files.deleteIfExists(tempFile);
                    } catch (IOException ignored) {
                    }
                }
            }
        }

        private String runTesseract(Path imagePath) {
            for (String command : tesseractCandidates()) {
                String output = runTesseractCommand(command, imagePath, "6");
                if (!output.isEmpty()) {
                    return output;
                }
                output = runTesseractCommand(command, imagePath, "11");
                if (!output.isEmpty()) {
                    return output;
                }
            }
            return "";
        }

        private String runTesseractCommand(String command, Path imagePath, String psmMode) {
            try {
                ProcessBuilder pb = new ProcessBuilder(
                        command,
                        imagePath.toString(),
                        "stdout",
                        "--oem",
                        "1",
                        "--psm",
                        psmMode,
                        "-l",
                        "eng");
                pb.redirectErrorStream(true);
                Process process = pb.start();
                boolean finished = process.waitFor(18, TimeUnit.SECONDS);
                if (!finished) {
                    process.destroyForcibly();
                    return "";
                }
                String text = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8).trim();
                if (process.exitValue() == 0 && !text.isEmpty()) {
                    return text;
                }
            } catch (Exception ignored) {
            }
            return "";
        }

        private List<String> tesseractCandidates() {
            List<String> list = new ArrayList<>();
            String env = System.getenv("EXPENSE_TESSERACT_CMD");
            if (env != null && !env.trim().isEmpty()) {
                list.add(env.trim());
            }
            list.addAll(Arrays.asList(
                    "C:\\Program Files\\Tesseract-OCR\\tesseract.exe",
                    "C:\\Program Files (x86)\\Tesseract-OCR\\tesseract.exe",
                    "tesseract"));
            return list;
        }

        private String fileExtension(String name) {
            int idx = name.lastIndexOf('.');
            if (idx < 0) {
                return "";
            }
            return name.substring(idx);
        }

        private String safeFileName(String fileName) {
            if (fileName == null) {
                return "";
            }
            int idx = Math.max(fileName.lastIndexOf('/'), fileName.lastIndexOf('\\'));
            return idx >= 0 ? fileName.substring(idx + 1) : fileName;
        }

        private double max(List<Double> values) {
            double out = 0.0;
            for (Double value : values) {
                out = Math.max(out, value);
            }
            return out;
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
            String value = raw == null ? "" : raw.trim().replace('/', '-');
            if (value.isEmpty()) {
                return "";
            }

            DateTimeFormatter[] formats = new DateTimeFormatter[] {
                    DateTimeFormatter.ISO_LOCAL_DATE,
                    DateTimeFormatter.ofPattern("dd-MM-yyyy"),
                    DateTimeFormatter.ofPattern("MM-dd-yyyy"),
                    DateTimeFormatter.ofPattern("dd-MM-yy"),
                    DateTimeFormatter.ofPattern("MM-dd-yy")
            };

            for (DateTimeFormatter format : formats) {
                try {
                    return LocalDate.parse(value, format).toString();
                } catch (DateTimeParseException ignored) {
                }
            }
            return "";
        }

        private int score(String text, String... keywords) {
            int points = 0;
            for (String keyword : keywords) {
                if (text.contains(keyword)) {
                    points++;
                }
            }
            return points;
        }
    }

    ```

    ## src/main/java/com/expenses/controller/ProfileServlet.java

    ```java
    package com.expenses.controller;

    import com.expenses.dao.UserDAO;
    import com.expenses.model.User;
    import com.expenses.util.SessionUtil;
    import java.io.IOException;
    import javax.servlet.ServletException;
    import javax.servlet.http.HttpServlet;
    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpServletResponse;
    import javax.servlet.http.HttpSession;

    public class ProfileServlet extends HttpServlet {
        private static final long serialVersionUID = 1L;
        private final UserDAO userDAO = new UserDAO();

        @Override
        protected void doGet(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            Integer userId = SessionUtil.getUserId(request);
            if (userId == null) {
                response.sendRedirect("login.jsp?error=Please%20login%20first");
                return;
            }

            User user = userDAO.getUserById(userId);
            request.setAttribute("user", user);
            request.getRequestDispatcher("profile.jsp").forward(request, response);
        }

        @Override
        protected void doPost(HttpServletRequest request, HttpServletResponse response)
                throws ServletException, IOException {
            Integer userId = SessionUtil.getUserId(request);
            if (userId == null) {
                response.sendRedirect("login.jsp?error=Please%20login%20first");
                return;
            }

            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            boolean updated = userDAO.updateProfile(
                    userId,
                    name == null ? "" : name.trim(),
                    email == null ? "" : email.trim(),
                    password == null ? "" : password.trim());

            if (!updated) {
                response.sendRedirect("ProfileServlet?error=Profile%20update%20failed%20or%20email%20already%20exists");
                return;
            }

            User updatedUser = userDAO.getUserById(userId);
            HttpSession session = request.getSession(false);
            if (session != null && updatedUser != null) {
                session.setAttribute("userName", updatedUser.getName());
                session.setAttribute("userEmail", updatedUser.getEmail());
            }
            response.sendRedirect("ProfileServlet?msg=Profile%20updated%20successfully");
        }
    }

    ```

    ## src/main/java/com/expenses/dao/DBConnection.java

    ```java
    package com.expenses.dao;

    import java.sql.Connection;
    import java.sql.DriverManager;
    import java.sql.PreparedStatement;
    import java.sql.SQLException;
    import java.sql.Statement;

    public class DBConnection {

        private static final String MYSQL_URL = System.getenv().getOrDefault(
                "EXPENSE_MYSQL_URL",
                "jdbc:mysql://localhost:3306/expense_db?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC");
        private static final String MYSQL_USER = System.getenv().getOrDefault("EXPENSE_MYSQL_USER", "root");
        private static final String MYSQL_PASSWORD = System.getenv().getOrDefault("EXPENSE_MYSQL_PASSWORD", "root");

        private static final String H2_URL = System.getenv().getOrDefault(
                "EXPENSE_H2_URL",
                "jdbc:h2:mem:expense_db;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1");
        private static final String H2_USER = System.getenv().getOrDefault("EXPENSE_H2_USER", "sa");
        private static final String H2_PASSWORD = System.getenv().getOrDefault("EXPENSE_H2_PASSWORD", "");

        private static volatile boolean schemaInitialized = false;

        public static Connection getConnection() {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection con = DriverManager.getConnection(MYSQL_URL, MYSQL_USER, MYSQL_PASSWORD);
                initializeSchemaIfNeeded(con);
                return con;
            } catch (Exception ignored) {
                try {
                    Class.forName("org.h2.Driver");
                    Connection con = DriverManager.getConnection(H2_URL, H2_USER, H2_PASSWORD);
                    initializeSchemaIfNeeded(con);
                    return con;
                } catch (Exception e) {
                    throw new IllegalStateException("Unable to connect to MySQL or fallback H2 database", e);
                }
            }
        }

        private static synchronized void initializeSchemaIfNeeded(Connection con) throws SQLException {
            if (schemaInitialized) {
                return;
            }

            try (Statement st = con.createStatement()) {
                st.executeUpdate(
                        "CREATE TABLE IF NOT EXISTS users ("
                                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                                + "name VARCHAR(100) NOT NULL,"
                                + "email VARCHAR(100) NOT NULL UNIQUE,"
                                + "password VARCHAR(255) NOT NULL)");

                st.executeUpdate(
                        "CREATE TABLE IF NOT EXISTS income ("
                                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                                + "user_id INT NOT NULL,"
                                + "amount DOUBLE NOT NULL,"
                                + "source VARCHAR(255) NOT NULL,"
                                + "date DATE NOT NULL,"
                                + "FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE)");

                st.executeUpdate(
                        "CREATE TABLE IF NOT EXISTS expense ("
                                + "id INT AUTO_INCREMENT PRIMARY KEY,"
                                + "user_id INT NOT NULL,"
                                + "amount DOUBLE NOT NULL,"
                                + "category VARCHAR(255) NOT NULL,"
                                + "date DATE NOT NULL,"
                                + "FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE)");
            }

            String seedSql = "INSERT INTO users (id, name, email, password) "
                    + "SELECT 1, ?, ?, ? WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1)";
            try (PreparedStatement ps = con.prepareStatement(seedSql)) {
                ps.setString(1, "Admin");
                ps.setString(2, "admin@example.com");
                ps.setString(3, "admin123");
                ps.executeUpdate();
            }

            schemaInitialized = true;
        }
    }

    ```

    ## src/main/java/com/expenses/dao/UserDAO.java

    ```java
    package com.expenses.dao;

    import com.expenses.model.User;
    import java.sql.Connection;
    import java.sql.PreparedStatement;
    import java.sql.ResultSet;
    import java.sql.SQLException;

    public class UserDAO {

        public boolean validateUser(String username, String email, String password) {
            User user = authenticate(email, password);
            return user != null && user.getName().equalsIgnoreCase(username);
        }

        public User authenticate(String email, String password) {
            String sql = "SELECT id, name, email, password FROM users WHERE email=? AND password=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, email);
                ps.setString(2, password);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return new User(
                                rs.getInt("id"),
                                rs.getString("name"),
                                rs.getString("email"),
                                rs.getString("password"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return null;
        }

        public boolean registerUser(User user) {
            if (emailExists(user.getEmail())) {
                return false;
            }

            String sql = "INSERT INTO users(name, email, password) VALUES(?,?,?)";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, user.getName());
                ps.setString(2, user.getEmail());
                ps.setString(3, user.getPassword());
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public User getUserById(int userId) {
            String sql = "SELECT id, name, email, password FROM users WHERE id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return new User(
                                rs.getInt("id"),
                                rs.getString("name"),
                                rs.getString("email"),
                                rs.getString("password"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return null;
        }

        public boolean updateProfile(int userId, String name, String email, String password) {
            User existing = getUserById(userId);
            if (existing == null) {
                return false;
            }

            if (!existing.getEmail().equalsIgnoreCase(email) && emailExists(email)) {
                return false;
            }

            String finalPassword = (password == null || password.trim().isEmpty())
                    ? existing.getPassword()
                    : password.trim();

            String sql = "UPDATE users SET name=?, email=?, password=? WHERE id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, name);
                ps.setString(2, email);
                ps.setString(3, finalPassword);
                ps.setInt(4, userId);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        private boolean emailExists(String email) {
            String sql = "SELECT id FROM users WHERE email=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    return rs.next();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return false;
        }
    }

    ```

    ## src/main/java/com/expenses/dao/IncomeDAO.java

    ```java
    package com.expenses.dao;

    import com.expenses.model.Income;
    import java.sql.Connection;
    import java.sql.Date;
    import java.sql.PreparedStatement;
    import java.sql.ResultSet;
    import java.sql.SQLException;
    import java.time.LocalDate;
    import java.time.YearMonth;
    import java.util.ArrayList;
    import java.util.LinkedHashMap;
    import java.util.List;
    import java.util.Map;

    public class IncomeDAO {

        public boolean addIncome(int userId, double amount, String source, String date) {
            String sql = "INSERT INTO income(user_id,amount,source,date) VALUES(?,?,?,?)";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDouble(2, amount);
                ps.setString(3, source);
                ps.setString(4, date);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public List<Income> getAllIncomes(int userId) {
            String sql = "SELECT id, user_id, amount, source, date FROM income WHERE user_id=? ORDER BY id DESC";
            List<Income> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Income(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("source"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public Income getIncomeByIdForUser(int incomeId, int userId) {
            String sql = "SELECT id, user_id, amount, source, date FROM income WHERE id=? AND user_id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, incomeId);
                ps.setInt(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return new Income(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("source"),
                                rs.getString("date"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return null;
        }

        public boolean updateIncome(int incomeId, int userId, double amount, String source, String date) {
            String sql = "UPDATE income SET amount=?, source=?, date=? WHERE id=? AND user_id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setDouble(1, amount);
                ps.setString(2, source);
                ps.setString(3, date);
                ps.setInt(4, incomeId);
                ps.setInt(5, userId);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public boolean deleteIncome(int incomeId, int userId) {
            String sql = "DELETE FROM income WHERE id=? AND user_id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, incomeId);
                ps.setInt(2, userId);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public List<Income> getIncomesByDate(int userId, LocalDate date) {
            String sql = "SELECT id, user_id, amount, source, date FROM income WHERE user_id=? AND date=? ORDER BY id DESC";
            List<Income> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(date));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Income(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("source"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public List<Income> getIncomesByMonth(int userId, YearMonth month) {
            String sql = "SELECT id, user_id, amount, source, date FROM income "
                    + "WHERE user_id=? AND date >= ? AND date < ? ORDER BY date DESC, id DESC";
            List<Income> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(month.atDay(1)));
                ps.setDate(3, Date.valueOf(month.plusMonths(1).atDay(1)));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Income(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("source"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public List<Income> getIncomesByYear(int userId, int year) {
            String sql = "SELECT id, user_id, amount, source, date FROM income "
                    + "WHERE user_id=? AND date >= ? AND date < ? ORDER BY date DESC, id DESC";
            List<Income> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(LocalDate.of(year, 1, 1)));
                ps.setDate(3, Date.valueOf(LocalDate.of(year + 1, 1, 1)));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Income(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("source"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public double getTotalByDate(int userId, LocalDate date) {
            return getTotalByRange(userId, date, date.plusDays(1));
        }

        public double getTotalByMonth(int userId, YearMonth month) {
            return getTotalByRange(userId, month.atDay(1), month.plusMonths(1).atDay(1));
        }

        public double getTotalByYear(int userId, int year) {
            return getTotalByRange(userId, LocalDate.of(year, 1, 1), LocalDate.of(year + 1, 1, 1));
        }

        public Map<String, Double> getMonthlyTotals(int userId, int year) {
            String sql = "SELECT EXTRACT(MONTH FROM date) AS month_no, SUM(amount) AS total "
                    + "FROM income WHERE user_id=? AND date >= ? AND date < ? GROUP BY EXTRACT(MONTH FROM date) "
                    + "ORDER BY month_no";

            Map<String, Double> out = new LinkedHashMap<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(LocalDate.of(year, 1, 1)));
                ps.setDate(3, Date.valueOf(LocalDate.of(year + 1, 1, 1)));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        int monthNo = rs.getInt("month_no");
                        out.put(String.format("%02d", monthNo), rs.getDouble("total"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return out;
        }

        private double getTotalByRange(int userId, LocalDate fromInclusive, LocalDate toExclusive) {
            String sql = "SELECT COALESCE(SUM(amount), 0) AS total FROM income "
                    + "WHERE user_id=? AND date >= ? AND date < ?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(fromInclusive));
                ps.setDate(3, Date.valueOf(toExclusive));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return rs.getDouble("total");
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return 0.0;
        }
    }

    ```

    ## src/main/java/com/expenses/dao/ExpenseDAO.java

    ```java
    package com.expenses.dao;

    import com.expenses.model.Expense;
    import java.sql.Connection;
    import java.sql.Date;
    import java.sql.PreparedStatement;
    import java.sql.ResultSet;
    import java.sql.SQLException;
    import java.time.LocalDate;
    import java.time.YearMonth;
    import java.util.ArrayList;
    import java.util.LinkedHashMap;
    import java.util.List;
    import java.util.Map;

    public class ExpenseDAO {

        public List<Expense> getAllExpenses(int userId) {
            String sql = "SELECT id, user_id, amount, category, date FROM expense WHERE user_id=? ORDER BY id DESC";
            List<Expense> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Expense(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("category"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public boolean addExpense(int userId, double amount, String category, String date) {
            String sql = "INSERT INTO expense(user_id,amount,category,date) VALUES(?,?,?,?)";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDouble(2, amount);
                ps.setString(3, category);
                ps.setString(4, date);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public Expense getExpenseByIdForUser(int expenseId, int userId) {
            String sql = "SELECT id, user_id, amount, category, date FROM expense WHERE id=? AND user_id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, expenseId);
                ps.setInt(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return new Expense(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("category"),
                                rs.getString("date"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return null;
        }

        public boolean updateExpense(int expenseId, int userId, double amount, String category, String date) {
            String sql = "UPDATE expense SET amount=?, category=?, date=? WHERE id=? AND user_id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setDouble(1, amount);
                ps.setString(2, category);
                ps.setString(3, date);
                ps.setInt(4, expenseId);
                ps.setInt(5, userId);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public boolean deleteExpense(int expenseId, int userId) {
            String sql = "DELETE FROM expense WHERE id=? AND user_id=?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, expenseId);
                ps.setInt(2, userId);
                return ps.executeUpdate() > 0;
            } catch (SQLException e) {
                e.printStackTrace();
                return false;
            }
        }

        public List<Expense> getExpensesByDate(int userId, LocalDate date) {
            String sql = "SELECT id, user_id, amount, category, date FROM expense WHERE user_id=? AND date=? ORDER BY id DESC";
            List<Expense> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(date));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Expense(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("category"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public List<Expense> getExpensesByMonth(int userId, YearMonth month) {
            String sql = "SELECT id, user_id, amount, category, date FROM expense "
                    + "WHERE user_id=? AND date >= ? AND date < ? ORDER BY date DESC, id DESC";
            List<Expense> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(month.atDay(1)));
                ps.setDate(3, Date.valueOf(month.plusMonths(1).atDay(1)));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Expense(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("category"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public List<Expense> getExpensesByYear(int userId, int year) {
            String sql = "SELECT id, user_id, amount, category, date FROM expense "
                    + "WHERE user_id=? AND date >= ? AND date < ? ORDER BY date DESC, id DESC";
            List<Expense> list = new ArrayList<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(LocalDate.of(year, 1, 1)));
                ps.setDate(3, Date.valueOf(LocalDate.of(year + 1, 1, 1)));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        list.add(new Expense(
                                rs.getInt("id"),
                                rs.getInt("user_id"),
                                rs.getDouble("amount"),
                                rs.getString("category"),
                                rs.getString("date")));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return list;
        }

        public double getTotalByDate(int userId, LocalDate date) {
            return getTotalByRange(userId, date, date.plusDays(1));
        }

        public double getTotalByMonth(int userId, YearMonth month) {
            return getTotalByRange(userId, month.atDay(1), month.plusMonths(1).atDay(1));
        }

        public double getTotalByYear(int userId, int year) {
            return getTotalByRange(userId, LocalDate.of(year, 1, 1), LocalDate.of(year + 1, 1, 1));
        }

        public Map<String, Double> getCategoryTotals(int userId) {
            String sql = "SELECT category, COALESCE(SUM(amount),0) AS total "
                    + "FROM expense WHERE user_id=? GROUP BY category ORDER BY total DESC";
            Map<String, Double> out = new LinkedHashMap<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        out.put(rs.getString("category"), rs.getDouble("total"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return out;
        }

        public Map<String, Double> getMonthlyTotals(int userId, int year) {
            String sql = "SELECT EXTRACT(MONTH FROM date) AS month_no, SUM(amount) AS total "
                    + "FROM expense WHERE user_id=? AND date >= ? AND date < ? GROUP BY EXTRACT(MONTH FROM date) "
                    + "ORDER BY month_no";

            Map<String, Double> out = new LinkedHashMap<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(LocalDate.of(year, 1, 1)));
                ps.setDate(3, Date.valueOf(LocalDate.of(year + 1, 1, 1)));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        int monthNo = rs.getInt("month_no");
                        out.put(String.format("%02d", monthNo), rs.getDouble("total"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return out;
        }

        public Map<Integer, Double> getYearlyTotals(int userId) {
            String sql = "SELECT EXTRACT(YEAR FROM date) AS year_no, SUM(amount) AS total "
                    + "FROM expense WHERE user_id=? GROUP BY EXTRACT(YEAR FROM date) ORDER BY year_no";

            Map<Integer, Double> out = new LinkedHashMap<>();
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        out.put(rs.getInt("year_no"), rs.getDouble("total"));
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return out;
        }

        private double getTotalByRange(int userId, LocalDate fromInclusive, LocalDate toExclusive) {
            String sql = "SELECT COALESCE(SUM(amount), 0) AS total FROM expense "
                    + "WHERE user_id=? AND date >= ? AND date < ?";
            try (Connection con = DBConnection.getConnection();
                    PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setDate(2, Date.valueOf(fromInclusive));
                ps.setDate(3, Date.valueOf(toExclusive));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        return rs.getDouble("total");
                    }
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return 0.0;
        }
    }

    ```

    ## src/main/java/com/expenses/model/User.java

    ```java
    package com.expenses.model;

    public class User {
        private int id;
        private String name;
        private String email;
        private String password;

        public User(String name, String email, String password) {
            this.name = name;
            this.email = email;
            this.password = password;
        }

        public User(int id, String name, String email, String password) {
            this.id = id;
            this.name = name;
            this.email = email;
            this.password = password;
        }

        public User(int id, String name, String email) {
            this.id = id;
            this.name = name;
            this.email = email;
        }

        public int getId() {
            return id;
        }

        public String getName() {
            return name;
        }

        public String getEmail() {
            return email;
        }

        public String getPassword() {
            return password;
        }
    }

    ```

    ## src/main/java/com/expenses/model/Income.java

    ```java
    package com.expenses.model;

    public class Income {
        private int id;
        private int userId;
        private double amount;
        private String source;
        private String date;

        public Income(int userId, double amount, String source, String date) {
            this.userId = userId;
            this.amount = amount;
            this.source = source;
            this.date = date;
        }

        public Income(int id, int userId, double amount, String source, String date) {
            this.id = id;
            this.userId = userId;
            this.amount = amount;
            this.source = source;
            this.date = date;
        }

        public int getId() {
            return id;
        }

        public int getUserId() {
            return userId;
        }

        public double getAmount() {
            return amount;
        }

        public String getSource() {
            return source;
        }

        public String getDate() {
            return date;
        }
    }

    ```

    ## src/main/java/com/expenses/model/Expense.java

    ```java
    package com.expenses.model;

    public class Expense {
        private int id;
        private int userId;
        private double amount;
        private String category;
        private String date;

        public Expense(int userId, double amount, String category, String date) {
            this.userId = userId;
            this.amount = amount;
            this.category = category;
            this.date = date;
        }

        public Expense(int id, int userId, double amount, String category, String date) {
            this.id = id;
            this.userId = userId;
            this.amount = amount;
            this.category = category;
            this.date = date;
        }

        public int getId() {
            return id;
        }

        public void setId(int id) {
            this.id = id;
        }

        public int getUserId() {
            return userId;
        }

        public void setUserId(int userId) {
            this.userId = userId;
        }

        public double getAmount() {
            return amount;
        }

        public void setAmount(double amount) {
            this.amount = amount;
        }

        public String getCategory() {
            return category;
        }

        public void setCategory(String category) {
            this.category = category;
        }

        public String getDate() {
            return date;
        }

        public void setDate(String date) {
            this.date = date;
        }
    }

    ```

    ## src/main/java/com/expenses/util/SessionUtil.java

    ```java
    package com.expenses.util;

    import javax.servlet.http.HttpServletRequest;
    import javax.servlet.http.HttpSession;

    public class SessionUtil {
        private SessionUtil() {
        }

        public static Integer getUserId(HttpServletRequest request) {
            HttpSession session = request.getSession(false);
            if (session == null) {
                return null;
            }
            Object value = session.getAttribute("userId");
            if (value instanceof Integer) {
                return (Integer) value;
            }
            return null;
        }

        public static boolean isLoggedIn(HttpServletRequest request) {
            return getUserId(request) != null;
        }
    }

    ```

    ## src/main/webapp/login.jsp

    ```jsp
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

    ```

    ## src/main/webapp/dashboard.jsp

    ```jsp
    <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
    <%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp?error=Please%20login%20first");
        return;
    }
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    String msg = request.getParameter("msg");
    %>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Dashboard | Expense Analyzer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="assets/css/app.css?v=20260304">
    </head>
    <body class="app-body">
    <header class="site-nav">
        <div class="nav-inner">
            <div class="brand"><span class="brand-mark"></span>AI-Powered Expenses Analyzer</div>
            <nav class="nav-links">
                <a class="nav-link is-active" href="dashboard.jsp">Dashboard</a>
                <a class="nav-link" href="IncomeServlet">Income</a>
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
                <h1>Welcome, <%= userName == null ? "User" : userName %></h1>
                <p class="page-sub">Signed in as <strong><%= userEmail == null ? "-" : userEmail %></strong>. Your finance operations workspace is now active.</p>
            </div>
            <div class="live-clock">Live <span data-live-clock></span></div>
        </section>

        <section class="page-actions reveal delay-1">
            <p class="page-sub">Quick actions to start your workflow without navigation delay.</p>
            <div class="action-row">
                <a class="btn ghost" href="IncomeServlet">+ Add Income</a>
                <a class="btn ghost" href="ExpenseServlet">+ Add Expense</a>
                <a class="btn secondary" href="ReportServlet">Open Reports</a>
                <a class="btn" href="BillScanServlet">Scan Bill</a>
            </div>
        </section>

        <div class="flash-wrap">
            <% if (msg != null) { %>
                <div class="flash ok" data-flash><%= msg %></div>
            <% } %>
        </div>

        <section class="grid-3 reveal delay-1" style="margin-bottom:16px;">
            <article class="metric-card">
                <p class="metric-label">Environment Status</p>
                <p class="metric-value">Live</p>
                <p class="page-sub">Server, database, and modules are online.</p>
            </article>
            <article class="metric-card">
                <p class="metric-label">Session User ID</p>
                <p class="metric-value"><%= userId %></p>
                <p class="page-sub">Authenticated workflow enabled.</p>
            </article>
            <article class="metric-card">
                <p class="metric-label">Realtime Clock</p>
                <p class="metric-value" style="font-size:19px;"><span data-live-clock></span></p>
                <p class="page-sub">Updates every second.</p>
            </article>
        </section>

        <section class="panel reveal delay-2">
            <h2 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Operational Modules</h2>
            <p class="page-sub" style="margin-bottom:14px;">Choose a module below to run live finance workflows.</p>
            <div class="module-grid">
                <article class="module-card">
                    <div class="module-card-head">
                        <span class="module-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <circle cx="12" cy="8" r="3.5" stroke="currentColor" stroke-width="1.8"/>
                                <path d="M5 19c0-3.1 3-5 7-5s7 1.9 7 5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                            </svg>
                        </span>
                        <h3>User Module</h3>
                    </div>
                    <p>Manage profile details and account security settings.</p>
                    <a class="btn" href="ProfileServlet">Open Profile</a>
                </article>
                <article class="module-card">
                    <div class="module-card-head">
                        <span class="module-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <rect x="3" y="6" width="18" height="12" rx="2.4" stroke="currentColor" stroke-width="1.8"/>
                                <circle cx="12" cy="12" r="2.2" stroke="currentColor" stroke-width="1.8"/>
                            </svg>
                        </span>
                        <h3>Income Management</h3>
                    </div>
                    <p>Add, edit, delete, and review all income entries.</p>
                    <a class="btn" href="IncomeServlet">Manage Income</a>
                </article>
                <article class="module-card">
                    <div class="module-card-head">
                        <span class="module-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M3 7.5A2.5 2.5 0 0 1 5.5 5H19a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5.5A2.5 2.5 0 0 1 3 16.5v-9Z" stroke="currentColor" stroke-width="1.8"/>
                                <path d="M3 10h18" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                            </svg>
                        </span>
                        <h3>Expense Management</h3>
                    </div>
                    <p>Track categorized expenses with CRUD operations.</p>
                    <a class="btn" href="ExpenseServlet">Manage Expenses</a>
                </article>
                <article class="module-card">
                    <div class="module-card-head">
                        <span class="module-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M5 20V10m7 10V6m7 14v-8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                                <path d="M3 20h18" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                            </svg>
                        </span>
                        <h3>Report Engine</h3>
                    </div>
                    <p>Generate daily, monthly, yearly summaries instantly.</p>
                    <a class="btn" href="ReportServlet">View Reports</a>
                </article>
                <article class="module-card">
                    <div class="module-card-head">
                        <span class="module-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M3.5 18.5h17" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                                <path d="M5.5 15 10 10.5l3 3L18.5 8" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </span>
                        <h3>Analytics &amp; Charts</h3>
                    </div>
                    <p>Monitor savings, top categories, and spending trends.</p>
                    <a class="btn" href="AnalysisServlet">Open Analysis</a>
                </article>
                <article class="module-card">
                    <div class="module-card-head">
                        <span class="module-icon" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none">
                                <rect x="4" y="3.5" width="16" height="17" rx="2.4" stroke="currentColor" stroke-width="1.8"/>
                                <path d="M8 8h8M8 12h8M8 16h5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
                            </svg>
                        </span>
                        <h3>AI Bill Scan</h3>
                    </div>
                    <p>Extract amount/date/category from OCR text files.</p>
                    <a class="btn" href="BillScanServlet">Scan Bills</a>
                </article>
            </div>
        </section>
    </main>
    <script src="assets/js/app.js?v=20260304"></script>
    </body>
    </html>

    ```

    ## src/main/webapp/income.jsp

    ```jsp
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

    ```

    ## src/main/webapp/expense.jsp

    ```jsp
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

    ```

    ## src/main/webapp/report.jsp

    ```jsp
    <%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
    <%@ page import="java.util.List" %>
    <%@ page import="com.expenses.model.Expense" %>
    <%@ page import="com.expenses.model.Income" %>
    <%
    Integer userId = (Integer) session.getAttribute("userId");
    if (userId == null) {
        response.sendRedirect("login.jsp?error=Please%20login%20first");
        return;
    }
    String period = (String) request.getAttribute("period");
    if (period == null) period = "daily";
    String selectedDate = (String) request.getAttribute("selectedDate");
    String selectedMonth = (String) request.getAttribute("selectedMonth");
    Object selectedYearObj = request.getAttribute("selectedYear");
    int selectedYear = selectedYearObj == null ? java.time.LocalDate.now().getYear() : (Integer) selectedYearObj;

    List<?> expenseList = (List<?>) request.getAttribute("expenseList");
    List<?> incomeList = (List<?>) request.getAttribute("incomeList");
    int expenseCount = expenseList == null ? 0 : expenseList.size();
    int incomeCount = incomeList == null ? 0 : incomeList.size();

    double totalExpense = request.getAttribute("totalExpense") == null ? 0.0 : (Double) request.getAttribute("totalExpense");
    double totalIncome = request.getAttribute("totalIncome") == null ? 0.0 : (Double) request.getAttribute("totalIncome");
    double netAmount = request.getAttribute("netAmount") == null ? 0.0 : (Double) request.getAttribute("netAmount");
    %>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Financial Reports</title>
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
                <a class="nav-link is-active" href="ReportServlet">Reports</a>
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
                <h2>Report Module</h2>
                <p class="page-sub">Generate daily, monthly, and yearly reports with income-expense comparison.</p>
            </div>
            <div class="live-clock">Live <span data-live-clock></span></div>
        </section>

        <section class="page-actions reveal delay-1">
            <p class="page-sub">Switch period instantly and review net savings with live totals.</p>
            <div class="action-row">
                <a class="btn ghost" href="dashboard.jsp">Dashboard</a>
                <a class="btn ghost" href="IncomeServlet">Income</a>
                <a class="btn ghost" href="ExpenseServlet">Expenses</a>
                <a class="btn secondary" href="AnalysisServlet">Open Analysis</a>
            </div>
        </section>

        <section class="panel reveal delay-1" style="margin-bottom:14px;">
            <div class="grid-auto">
                <form class="form-stack" action="ReportServlet" method="get">
                    <input type="hidden" name="period" value="daily">
                    <label>Daily Report</label>
                    <input type="date" name="date" value="<%= selectedDate %>">
                    <button type="submit" class="<%= "daily".equals(period) ? "" : "secondary" %>">Generate Daily</button>
                </form>

                <form class="form-stack" action="ReportServlet" method="get">
                    <input type="hidden" name="period" value="monthly">
                    <label>Monthly Report</label>
                    <input type="month" name="month" value="<%= selectedMonth %>">
                    <button type="submit" class="<%= "monthly".equals(period) ? "" : "secondary" %>">Generate Monthly</button>
                </form>

                <form class="form-stack" action="ReportServlet" method="get">
                    <input type="hidden" name="period" value="yearly">
                    <label>Yearly Report</label>
                    <input type="number" min="2000" max="2100" name="year" value="<%= selectedYear %>">
                    <button type="submit" class="<%= "yearly".equals(period) ? "" : "secondary" %>">Generate Yearly</button>
                </form>
            </div>
        </section>

        <section class="grid-3 reveal delay-2" style="margin-bottom:14px;">
            <article class="metric-card">
                <p class="metric-label">Selected Period</p>
                <p class="metric-value"><%= period.substring(0,1).toUpperCase() + period.substring(1) %></p>
            </article>
            <article class="metric-card">
                <p class="metric-label">Total Income</p>
                <p class="metric-value">Rs <span data-count-up="<%= String.format(java.util.Locale.US, "%.2f", totalIncome) %>"><%= String.format("%.2f", totalIncome) %></span></p>
            </article>
            <article class="metric-card">
                <p class="metric-label">Total Expense</p>
                <p class="metric-value">Rs <span data-count-up="<%= String.format(java.util.Locale.US, "%.2f", totalExpense) %>"><%= String.format("%.2f", totalExpense) %></span></p>
            </article>
        </section>

        <section class="panel reveal delay-3" style="margin-bottom:14px;">
            <div class="tag">Net Savings: Rs <%= String.format("%.2f", netAmount) %></div>
        </section>

        <section class="grid-2 report-entry-grid">
            <article class="panel report-entry-panel reveal delay-2">
                <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Income Entries</h3>
                <p class="page-sub history-meta"><%= incomeCount %> entries in current filter.</p>
                <% if (incomeList != null && !incomeList.isEmpty()) { %>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr><th>Date</th><th>Source</th><th>Amount</th></tr>
                            </thead>
                            <tbody>
                                <% for (Object obj : incomeList) { Income in = (Income) obj; %>
                                    <tr>
                                        <td><%= in.getDate() %></td>
                                        <td><%= in.getSource() %></td>
                                        <td>Rs <%= String.format("%.2f", in.getAmount()) %></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } else { %>
                    <div class="empty">
                        No income entries available for selected period.
                        <div style="margin-top:10px;"><a class="btn secondary" href="IncomeServlet">Add Income Entry</a></div>
                    </div>
                <% } %>
            </article>

            <article class="panel report-entry-panel reveal delay-3">
                <h3 style="margin-top:0;font-family:'Space Grotesk',sans-serif;">Expense Entries</h3>
                <p class="page-sub history-meta"><%= expenseCount %> entries in current filter.</p>
                <% if (expenseList != null && !expenseList.isEmpty()) { %>
                    <div class="table-wrap">
                        <table>
                            <thead>
                                <tr><th>Date</th><th>Category</th><th>Amount</th></tr>
                            </thead>
                            <tbody>
                                <% for (Object obj : expenseList) { Expense ex = (Expense) obj; %>
                                    <tr>
                                        <td><%= ex.getDate() %></td>
                                        <td><%= ex.getCategory() %></td>
                                        <td>Rs <%= String.format("%.2f", ex.getAmount()) %></td>
                                    </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                <% } else { %>
                    <div class="empty">
                        No expense entries available for selected period.
                        <div style="margin-top:10px;"><a class="btn secondary" href="ExpenseServlet">Add Expense Entry</a></div>
                    </div>
                <% } %>
            </article>
        </section>
    </main>
    <script src="assets/js/app.js?v=20260304"></script>
    </body>
    </html>

    ```

    ## src/main/webapp/analyzer.jsp

    ```jsp
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

    ```

    ## src/main/webapp/billscan.jsp

    ```jsp
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

    ```

    ## src/main/webapp/profile.jsp

    ```jsp
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

    ```

    ## src/main/webapp/assets/js/app.js

    ```javascript
    (function () {
    var THEME_KEY = 'expense_ui_theme';
    var DENSITY_KEY = 'expense_ui_density';

    function iconSvg(name) {
        var icons = {
        moon:
            '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><path d="M20 14.5A8.5 8.5 0 0 1 9.5 4 8.5 8.5 0 1 0 20 14.5Z" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>',
        sun:
            '<svg viewBox="0 0 24 24" fill="none" aria-hidden="true"><circle cx="12" cy="12" r="4.2" stroke="currentColor" stroke-width="1.8"/><path d="M12 2.5V5M12 19v2.5M4.93 4.93l1.77 1.77M17.3 17.3l1.77 1.77M2.5 12H5M19 12h2.5M4.93 19.07l1.77-1.77M17.3 6.7l1.77-1.77" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>'
        };
        return icons[name] || icons.sun;
    }

    function applyTheme(theme) {
        var safeTheme = theme === 'dark' ? 'dark' : 'light';
        var previousTheme = document.documentElement.getAttribute('data-theme');
        document.documentElement.setAttribute('data-theme', safeTheme);
        try {
        localStorage.setItem(THEME_KEY, safeTheme);
        } catch (err) {
        // no-op
        }
        var label = document.querySelector('[data-theme-label]');
        var icon = document.querySelector('[data-theme-icon]');
        if (label) {
        label.textContent = safeTheme === 'dark' ? 'Dark' : 'Light';
        }
        if (icon) {
        icon.innerHTML = safeTheme === 'dark' ? iconSvg('moon') : iconSvg('sun');
        }
        if (previousTheme !== safeTheme) {
        document.dispatchEvent(new CustomEvent('expense-theme-change', { detail: { theme: safeTheme } }));
        }
    }

    function applyDensity(density) {
        var safeDensity = density === 'compact' ? 'compact' : 'comfortable';
        document.documentElement.setAttribute('data-density', safeDensity);
        try {
        localStorage.setItem(DENSITY_KEY, safeDensity);
        } catch (err) {
        // no-op
        }
        document.querySelectorAll('[data-density-value]').forEach(function (btn) {
        btn.classList.toggle('is-active', btn.getAttribute('data-density-value') === safeDensity);
        });
    }

    function bootstrapPreferences() {
        var savedTheme = 'light';
        var savedDensity = 'comfortable';
        try {
        savedTheme = localStorage.getItem(THEME_KEY) || 'light';
        savedDensity = localStorage.getItem(DENSITY_KEY) || 'comfortable';
        } catch (err) {
        // no-op
        }
        applyTheme(savedTheme);
        applyDensity(savedDensity);
    }

    function createDisplayControls() {
        var controlsMarkup =
        '<div class="ui-controls" data-ui-controls>' +
        '<button type="button" class="ui-btn" data-theme-toggle aria-label="Toggle theme">' +
        '<span class="icon-inline" data-theme-icon>' + iconSvg('sun') + '</span>' +
        '<span data-theme-label>Light</span>' +
        '</button>' +
        '<div class="density-switch" role="group" aria-label="UI density">' +
        '<button type="button" class="density-btn" data-density-value="comfortable">Comfort</button>' +
        '<button type="button" class="density-btn" data-density-value="compact">Compact</button>' +
        '</div>' +
        '</div>';

        var navInner = document.querySelector('.nav-inner');
        if (navInner) {
        var navTools = document.createElement('div');
        navTools.className = 'nav-tools';
        navTools.innerHTML = controlsMarkup;
        navInner.appendChild(navTools);
        return;
        }

        var authShell = document.querySelector('.auth-shell');
        if (authShell) {
        var authTools = document.createElement('div');
        authTools.className = 'auth-tools';
        authTools.innerHTML = controlsMarkup;
        document.body.insertBefore(authTools, authShell);
        }
    }

    function wireDisplayControls() {
        var themeToggle = document.querySelector('[data-theme-toggle]');
        if (themeToggle) {
        themeToggle.addEventListener('click', function () {
            var current = document.documentElement.getAttribute('data-theme');
            applyTheme(current === 'dark' ? 'light' : 'dark');
        });
        }

        document.querySelectorAll('[data-density-value]').forEach(function (btn) {
        btn.addEventListener('click', function () {
            applyDensity(btn.getAttribute('data-density-value'));
        });
        });
    }

    function ensureTableSections(table) {
        if (!table.tHead && table.rows.length > 0) {
        var thead = table.createTHead();
        thead.appendChild(table.rows[0]);
        }
        if (!table.tBodies.length) {
        table.createTBody();
        }
        var body = table.tBodies[0];
        Array.prototype.slice.call(table.children).forEach(function (child) {
        if (child.tagName && child.tagName.toUpperCase() === 'TR') {
            body.appendChild(child);
        }
        });
    }

    function getTableTitle(table) {
        var panel = table.closest('.panel');
        if (!panel) {
        return 'entries';
        }
        var heading = panel.querySelector('h2, h3');
        if (!heading) {
        return 'entries';
        }
        heading.classList.add('is-sticky-title');
        return (heading.textContent || 'entries').trim();
    }

    function updateTableFilterState(table, query, colIndex, valueFilter, emptyState, countNode) {
        var body = table.tBodies[0];
        if (!body) {
        return;
        }
        var rows = Array.prototype.slice.call(body.rows);
        var visible = 0;
        rows.forEach(function (row) {
        var cells = Array.prototype.slice.call(row.cells);
        if (!cells.length) {
            return;
        }
        var hay = '';
        var cellValue = '';
        if (colIndex >= 0 && colIndex < cells.length) {
            cellValue = (cells[colIndex].textContent || '').trim();
            hay = cellValue.toLowerCase();
        } else {
            hay = (row.textContent || '').toLowerCase();
        }
        var matchSearch = !query || hay.indexOf(query) !== -1;
        var matchValue = valueFilter === '__all' || colIndex < 0 || cellValue === valueFilter;
        var match = matchSearch && matchValue;
        // Some table styles can interfere with `display`; `hidden` is a stronger signal.
        row.hidden = !match;
        row.style.display = match ? '' : 'none';
        if (match) {
            visible += 1;
        }
        });

        if (countNode) {
        countNode.textContent = visible + ' shown';
        }
        if (emptyState) {
        emptyState.classList.toggle('is-visible', visible === 0);
        }
    }

    function setupSmartTables() {
        var tables = document.querySelectorAll('.table-wrap table');
        tables.forEach(function (table, tableIndex) {
        if (table.getAttribute('data-enhanced') === 'true') {
            return;
        }
        table.setAttribute('data-enhanced', 'true');
        ensureTableSections(table);

        var title = getTableTitle(table);
        var wrap = table.closest('.table-wrap');
        if (!wrap) {
            return;
        }
        wrap.classList.add('table-wrap-enhanced');

        var tool = document.createElement('div');
        tool.className = 'table-tools';
        tool.innerHTML =
            '<div class="table-search">' +
            '<input type="search" autocomplete="off" placeholder="Search ' + title + '" data-table-search="' + tableIndex + '">' +
            '</div>' +
            '<div class="table-filter">' +
            '<select data-table-col="' + tableIndex + '" aria-label="Filter column"><option value="all">All Columns</option></select>' +
            '<select data-table-value="' + tableIndex + '" aria-label="Filter value" disabled><option value="__all">All Values</option></select>' +
            '<button type="button" class="btn ghost table-reset" data-table-reset="' + tableIndex + '">Reset</button>' +
            '<span class="table-count" data-table-count="' + tableIndex + '"></span>' +
            '</div>';
        wrap.parentNode.insertBefore(tool, wrap);

        var select = tool.querySelector('select');
        var valueSelect = tool.querySelector('[data-table-value]');
        var resetBtn = tool.querySelector('[data-table-reset]');
        var search = tool.querySelector('input[type="search"]');
        var countNode = tool.querySelector('[data-table-count]');
        var emptyState = document.createElement('div');
        emptyState.className = 'table-filter-empty';
        emptyState.textContent = 'No rows match this filter.';
        wrap.parentNode.insertBefore(emptyState, wrap.nextSibling);

        Array.prototype.slice.call(table.tHead.rows[0].cells).forEach(function (th, idx) {
            var txt = (th.textContent || '').trim();
            if (!txt) {
            return;
            }
            var opt = document.createElement('option');
            opt.value = String(idx);
            opt.textContent = txt;
            select.appendChild(opt);
        });

        function populateValueOptions(colIndex) {
            valueSelect.innerHTML = '<option value="__all">All Values</option>';
            if (colIndex < 0) {
            valueSelect.disabled = true;
            return;
            }

            var seen = {};
            var values = [];
            Array.prototype.slice.call(table.tBodies[0].rows).forEach(function (row) {
            if (!row.cells[colIndex]) {
                return;
            }
            var value = (row.cells[colIndex].textContent || '').trim();
            if (value && !seen[value]) {
                seen[value] = true;
                values.push(value);
            }
            });

            values.sort(function (a, b) {
            return a.localeCompare(b, undefined, { sensitivity: 'base', numeric: true });
            });

            values.forEach(function (value) {
            var opt = document.createElement('option');
            opt.value = value;
            opt.textContent = value;
            valueSelect.appendChild(opt);
            });
            valueSelect.disabled = false;
        }

        function runFilter() {
            var query = (search.value || '').toLowerCase().trim();
            var colValue = select.value;
            var colIndex = colValue === 'all' ? -1 : parseInt(colValue, 10);
            var valueFilter = valueSelect.disabled ? '__all' : valueSelect.value;
            updateTableFilterState(table, query, colIndex, valueFilter, emptyState, countNode);
        }

        populateValueOptions(-1);
        search.addEventListener('input', runFilter);
        select.addEventListener('change', function () {
            var colIndex = select.value === 'all' ? -1 : parseInt(select.value, 10);
            populateValueOptions(colIndex);
            runFilter();
        });
        valueSelect.addEventListener('change', runFilter);
        resetBtn.addEventListener('click', function () {
            search.value = '';
            select.value = 'all';
            populateValueOptions(-1);
            runFilter();
        });
        runFilter();
        });
    }

    function showBootLoader() {
        var loader = document.createElement('div');
        loader.className = 'app-loader';
        loader.setAttribute('aria-hidden', 'true');
        loader.innerHTML =
        '<div class=\"app-loader-card\">' +
        '<div class=\"sk-row w-78\"></div>' +
        '<div class=\"sk-row w-90\"></div>' +
        '<div class=\"sk-row w-62\"></div>' +
        '<div class=\"sk-row w-48\"></div>' +
        '</div>';

        document.body.appendChild(loader);
        requestAnimationFrame(function () {
        loader.classList.add('is-visible');
        });

        setTimeout(function () {
        loader.classList.add('is-hide');
        setTimeout(function () {
            if (loader.parentNode) {
            loader.parentNode.removeChild(loader);
            }
        }, 240);
        }, 520);
    }

    function updateClocks() {
        var nodes = document.querySelectorAll('[data-live-clock]');
        var now = new Date();
        var value = now.toLocaleString('en-IN', {
        hour12: true,
        year: 'numeric',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
        });
        nodes.forEach(function (node) {
        node.textContent = value;
        });
    }

    function setupFlash() {
        var flashes = document.querySelectorAll('[data-flash]');
        flashes.forEach(function (flash) {
        setTimeout(function () {
            flash.style.transition = 'opacity 0.35s ease, transform 0.35s ease';
            flash.style.opacity = '0';
            flash.style.transform = 'translateY(-4px)';
        }, 4200);
        setTimeout(function () {
            if (flash.parentNode) {
            flash.parentNode.removeChild(flash);
            }
        }, 4700);
        });
    }

    function setupTabs() {
        var triggers = document.querySelectorAll('[data-tab-target]');
        if (!triggers.length) {
        return;
        }

        triggers.forEach(function (trigger) {
        trigger.addEventListener('click', function () {
            var targetId = trigger.getAttribute('data-tab-target');
            document.querySelectorAll('[data-tab-pane]').forEach(function (pane) {
            pane.classList.remove('is-active');
            });
            document.querySelectorAll('[data-tab-target]').forEach(function (btn) {
            btn.classList.remove('is-active');
            });
            var target = document.getElementById(targetId);
            if (target) {
            target.classList.add('is-active');
            }
            trigger.classList.add('is-active');
        });
        });
    }

    function setupCountUp() {
        var items = document.querySelectorAll('[data-count-up]');
        items.forEach(function (item) {
        var target = parseFloat(item.getAttribute('data-count-up'));
        if (isNaN(target)) {
            return;
        }
        var decimals = (target.toString().split('.')[1] || '').length;
        var steps = 32;
        var current = 0;
        var step = target / steps;
        var tick = 0;
        var id = setInterval(function () {
            tick += 1;
            current += step;
            if (tick >= steps) {
            current = target;
            clearInterval(id);
            }
            item.textContent = current.toFixed(decimals);
        }, 18);
        });
    }

    function setupCardMotion() {
        var cards = document.querySelectorAll('.module-card, .metric-card');
        cards.forEach(function (card) {
        card.addEventListener('mousemove', function (event) {
            if (window.matchMedia('(max-width: 900px)').matches) {
            return;
            }
            var rect = card.getBoundingClientRect();
            var x = (event.clientX - rect.left) / rect.width;
            var y = (event.clientY - rect.top) / rect.height;
            var tiltX = (0.5 - y) * 2.2;
            var tiltY = (x - 0.5) * 2.2;
            card.style.transform = 'rotateX(' + tiltX.toFixed(2) + 'deg) rotateY(' + tiltY.toFixed(2) + 'deg) translateY(-2px)';
        });

        card.addEventListener('mouseleave', function () {
            card.style.transform = '';
        });
        });
    }

    function setupStickySections() {
        document.querySelectorAll('.page-head').forEach(function (head) {
        head.classList.add('is-sticky-section');
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        bootstrapPreferences();
        createDisplayControls();
        wireDisplayControls();
        applyTheme(document.documentElement.getAttribute('data-theme'));
        applyDensity(document.documentElement.getAttribute('data-density'));
        setupStickySections();
        showBootLoader();
        updateClocks();
        setInterval(updateClocks, 1000);
        setupFlash();
        setupTabs();
        setupCountUp();
        setupCardMotion();
        setupSmartTables();
    });
    })();

    ```

    ## src/main/webapp/assets/css/app.css

    ```css
    @import url('https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700;800&family=Plus+Jakarta+Sans:wght@500;700&family=Space+Grotesk:wght@500;700&display=swap');

    :root {
    --ink-950: #0f1b2d;
    --ink-900: #14253c;
    --ink-700: #2f435e;
    --ink-500: #5b6f88;
    --ink-300: #8ba0ba;
    --surface: #ffffff;
    --surface-soft: #f5f9ff;
    --line: #d7e1ee;
    --line-strong: #b9c8dc;
    --brand: #0f7a75;
    --brand-strong: #0b615d;
    --brand-soft: #dff5f3;
    --secondary: #2153c9;
    --secondary-soft: #e4edff;
    --accent: #f2991b;
    --danger: #dc3a44;
    --danger-soft: #ffe6e9;
    --ok: #0f8a5b;
    --ok-soft: #dcf8ea;
    --chart-text: #2f435e;
    --chart-grid: rgba(47, 67, 94, 0.16);
    --chart-income: #0f7a75;
    --chart-expense: #ea580c;
    --chart-line: #2153c9;
    --chart-line-fill: rgba(33, 83, 201, 0.16);
    --chart-tooltip-bg: rgba(15, 27, 45, 0.9);
    --chart-tooltip-text: #f3f8ff;
    --chart-palette-1: #0f7a75;
    --chart-palette-2: #2563eb;
    --chart-palette-3: #f97316;
    --chart-palette-4: #f43f5e;
    --chart-palette-5: #8b5cf6;
    --chart-palette-6: #22c55e;
    --chart-palette-7: #06b6d4;
    --radius-xl: 24px;
    --radius-lg: 18px;
    --radius-md: 12px;
    --radius-sm: 9px;
    --shadow-lg: 0 24px 60px rgba(10, 28, 58, 0.15);
    --shadow-md: 0 14px 36px rgba(16, 33, 54, 0.1);
    --shadow-sm: 0 7px 16px rgba(17, 28, 46, 0.08);
    }

    * {
    box-sizing: border-box;
    }

    html,
    body {
    margin: 0;
    padding: 0;
    }

    body {
    font-family: 'Manrope', sans-serif;
    color: var(--ink-900);
    }

    .app-body {
    min-height: 100vh;
    background:
        radial-gradient(850px 440px at -8% -10%, #d9f2f0 0%, transparent 70%),
        radial-gradient(760px 380px at 108% -8%, #ffeed4 0%, transparent 72%),
        radial-gradient(820px 460px at 50% 120%, #e6ecff 0%, transparent 70%),
        linear-gradient(180deg, #edf3fb 0%, #e8eff7 42%, #e1e9f3 100%);
    }

    .site-nav {
    position: sticky;
    top: 0;
    z-index: 40;
    backdrop-filter: blur(12px);
    background: rgba(255, 255, 255, 0.82);
    border-bottom: 1px solid rgba(20, 37, 60, 0.08);
    }

    .nav-inner {
    max-width: 1260px;
    margin: 0 auto;
    padding: 14px 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 14px;
    }

    .brand {
    display: flex;
    align-items: center;
    gap: 10px;
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-weight: 700;
    color: var(--ink-950);
    letter-spacing: 0.2px;
    }

    .brand-mark {
    width: 30px;
    height: 30px;
    border-radius: 9px;
    background: linear-gradient(145deg, #0f7a75, #3cc5b4);
    box-shadow: 0 8px 18px rgba(15, 122, 117, 0.34);
    }

    .nav-links {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 8px;
    }

    .nav-link {
    text-decoration: none;
    color: var(--ink-700);
    font-weight: 700;
    font-size: 13px;
    letter-spacing: 0.2px;
    padding: 8px 12px;
    border-radius: 999px;
    border: 1px solid transparent;
    transition: all 0.2s ease;
    }

    .nav-link:hover {
    border-color: var(--line);
    background: #f4f8ff;
    color: var(--ink-900);
    }

    .nav-link.is-active {
    border-color: #b8d9d6;
    background: var(--brand-soft);
    color: var(--brand-strong);
    }

    .nav-link.danger {
    color: #b01928;
    }

    .page-wrap {
    max-width: 1260px;
    margin: 22px auto 36px;
    padding: 0 20px;
    }

    .page-head {
    background: linear-gradient(145deg, rgba(255, 255, 255, 0.96), rgba(249, 252, 255, 0.96));
    border: 1px solid rgba(20, 37, 60, 0.1);
    border-radius: var(--radius-xl);
    padding: 20px 22px;
    box-shadow: var(--shadow-md);
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 16px;
    }

    .page-head h1,
    .page-head h2 {
    margin: 0;
    font-family: 'Plus Jakarta Sans', sans-serif;
    letter-spacing: -0.2px;
    }

    .page-sub {
    margin: 5px 0 0;
    color: var(--ink-500);
    font-size: 14px;
    }

    .live-clock {
    position: relative;
    padding: 8px 14px 8px 27px;
    border-radius: 999px;
    background: #e8f6f4;
    color: var(--brand-strong);
    font-weight: 800;
    font-size: 12px;
    white-space: nowrap;
    letter-spacing: 0.2px;
    }

    .live-clock::before {
    content: '';
    position: absolute;
    left: 11px;
    top: 50%;
    width: 8px;
    height: 8px;
    border-radius: 999px;
    background: var(--ok);
    transform: translateY(-50%);
    box-shadow: 0 0 0 5px rgba(15, 138, 91, 0.13);
    }

    .flash-wrap {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 12px;
    }

    .flash {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 10px 13px;
    border-radius: 999px;
    font-size: 13px;
    font-weight: 700;
    border: 1px solid transparent;
    }

    .flash.ok {
    background: var(--ok-soft);
    color: #0e6841;
    border-color: #b9efd5;
    }

    .flash.err {
    background: var(--danger-soft);
    color: #9f2431;
    border-color: #ffcad0;
    }

    .panel {
    background: linear-gradient(170deg, rgba(255, 255, 255, 0.98), rgba(247, 250, 255, 0.97));
    border-radius: var(--radius-xl);
    border: 1px solid rgba(20, 37, 60, 0.1);
    box-shadow: var(--shadow-md);
    padding: 18px;
    }

    .grid-2 {
    display: grid;
    grid-template-columns: 1.08fr 1fr;
    gap: 16px;
    }

    .report-entry-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    align-items: stretch;
    }

    .grid-2.report-entry-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .report-entry-panel {
    min-height: 360px;
    display: grid;
    grid-template-rows: auto auto 1fr;
    align-content: stretch;
    }

    .report-entry-panel .table-wrap {
    margin-top: 4px;
    height: 250px;
    overflow: auto;
    }

    .report-entry-panel table {
    min-width: 100%;
    table-layout: fixed;
    }

    .report-entry-panel th,
    .report-entry-panel td {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    }

    .report-entry-panel .empty {
    margin-top: 4px;
    min-height: 250px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    }

    .grid-3 {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
    }

    .grid-auto {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 14px;
    }

    .metric-card {
    position: relative;
    background: linear-gradient(165deg, #ffffff 0%, #f5f9ff 100%);
    border: 1px solid var(--line);
    border-radius: var(--radius-lg);
    padding: 15px;
    box-shadow: var(--shadow-sm);
    overflow: hidden;
    transform-style: preserve-3d;
    will-change: transform;
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    }

    .metric-card::after {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 3px;
    background: linear-gradient(90deg, #0f7a75, #2267d2);
    opacity: 0.75;
    }

    .metric-label {
    margin: 0;
    color: var(--ink-500);
    font-weight: 700;
    font-size: 12px;
    letter-spacing: 0.2px;
    }

    .metric-value {
    margin: 7px 0 0;
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 28px;
    line-height: 1;
    color: var(--ink-950);
    }

    .module-grid {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 14px;
    align-items: stretch;
    }

    .module-card {
    position: relative;
    background: linear-gradient(160deg, #ffffff 0%, #f4f8ff 100%);
    border: 1px solid var(--line);
    border-radius: var(--radius-lg);
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 10px;
    min-height: 190px;
    transform-style: preserve-3d;
    will-change: transform;
    transition: transform 0.22s ease, box-shadow 0.22s ease, border-color 0.22s ease;
    }

    .module-card::before {
    content: '';
    position: absolute;
    left: 16px;
    right: 16px;
    top: 0;
    height: 3px;
    border-radius: 999px;
    background: linear-gradient(90deg, #0f7a75, #2153c9, #f2991b);
    opacity: 0.65;
    }

    .module-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 18px 36px rgba(25, 46, 76, 0.16);
    border-color: #b9c8dc;
    }

    .module-card h3 {
    margin: 0;
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 18px;
    color: var(--ink-950);
    }

    .module-card p {
    margin: 0;
    color: var(--ink-500);
    line-height: 1.4;
    font-size: 14px;
    }

    .module-card-head {
    display: flex;
    align-items: center;
    gap: 10px;
    }

    .module-icon {
    width: 36px;
    height: 36px;
    border-radius: 10px;
    background: linear-gradient(145deg, #e9f4ff, #dff5f3);
    border: 1px solid #c8d9ef;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    box-shadow: var(--shadow-sm);
    }

    .btn,
    button,
    input[type='submit'] {
    border: none;
    border-radius: var(--radius-sm);
    background: linear-gradient(145deg, #0f7a75, #1ba293);
    color: #ffffff;
    font-weight: 800;
    font-size: 13px;
    letter-spacing: 0.1px;
    font-family: 'Manrope', sans-serif;
    padding: 10px 14px;
    cursor: pointer;
    transition: transform 0.18s ease, filter 0.18s ease, box-shadow 0.18s ease;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    box-shadow: 0 8px 16px rgba(14, 117, 112, 0.25);
    }

    .btn:hover,
    button:hover,
    input[type='submit']:hover {
    transform: translateY(-1px);
    filter: brightness(1.04);
    }

    .btn:focus-visible,
    button:focus-visible,
    input[type='submit']:focus-visible,
    input:focus-visible,
    select:focus-visible,
    textarea:focus-visible,
    .nav-link:focus-visible {
    outline: 3px solid rgba(33, 83, 201, 0.28);
    outline-offset: 2px;
    }

    .btn.secondary {
    background: linear-gradient(145deg, #2153c9, #3f7cff);
    box-shadow: 0 8px 16px rgba(33, 83, 201, 0.24);
    }

    .btn.warn {
    background: linear-gradient(145deg, #e0651c, #f59d3f);
    box-shadow: 0 8px 16px rgba(224, 101, 28, 0.24);
    }

    .btn.ghost {
    background: #f3f7fe;
    color: var(--ink-700);
    border: 1px solid var(--line);
    box-shadow: none;
    }

    .btn.link {
    background: transparent;
    box-shadow: none;
    color: var(--secondary);
    padding: 0;
    }

    .form-stack {
    display: grid;
    gap: 10px;
    }

    .page-actions {
    background: linear-gradient(170deg, rgba(255, 255, 255, 0.94), rgba(243, 248, 255, 0.95));
    border: 1px solid rgba(20, 37, 60, 0.1);
    border-radius: var(--radius-lg);
    padding: 12px 14px;
    box-shadow: var(--shadow-sm);
    margin-bottom: 14px;
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    justify-content: space-between;
    align-items: center;
    }

    .page-actions .page-sub {
    margin: 0;
    }

    .action-row {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    }

    label {
    color: var(--ink-700);
    font-weight: 800;
    font-size: 12px;
    letter-spacing: 0.2px;
    }

    input,
    select,
    textarea {
    width: 100%;
    border: 1px solid var(--line);
    border-radius: var(--radius-sm);
    padding: 11px 12px;
    font-size: 14px;
    font-family: 'Manrope', sans-serif;
    color: var(--ink-900);
    background: #fcfeff;
    transition: border-color 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
    }

    input::placeholder,
    textarea::placeholder {
    color: #93a4b8;
    }

    input:focus,
    select:focus,
    textarea:focus {
    outline: none;
    border-color: #8db6f8;
    box-shadow: 0 0 0 4px rgba(33, 83, 201, 0.14);
    background: #ffffff;
    }

    .table-wrap {
    overflow-x: auto;
    border: 1px solid var(--line);
    border-radius: var(--radius-md);
    }

    table {
    width: 100%;
    border-collapse: collapse;
    min-width: 640px;
    }

    th,
    td {
    padding: 10px 11px;
    border-bottom: 1px solid #e7edf5;
    text-align: left;
    font-size: 14px;
    }

    th {
    background: linear-gradient(180deg, #f2f7ff 0%, #edf4fe 100%);
    font-family: 'Plus Jakarta Sans', sans-serif;
    font-size: 12px;
    color: var(--ink-700);
    letter-spacing: 0.2px;
    }

    tr:nth-child(even) td {
    background: #fbfdff;
    }

    tr:hover td {
    background: #f3f8ff;
    }

    .tag {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: #eef4ff;
    color: var(--ink-700);
    border-radius: 999px;
    font-size: 11px;
    font-weight: 800;
    letter-spacing: 0.2px;
    padding: 6px 10px;
    border: 1px solid #d8e4f7;
    }

    .kbd {
    border-radius: 6px;
    border: 1px solid #d7e4f1;
    padding: 2px 6px;
    font-size: 12px;
    background: #f4f8ff;
    font-family: 'Plus Jakarta Sans', sans-serif;
    }

    .empty {
    padding: 26px 18px;
    text-align: center;
    color: var(--ink-500);
    border: 1px dashed #c7d8ec;
    border-radius: var(--radius-md);
    background: linear-gradient(160deg, #fbfdff 0%, #f2f8ff 100%);
    }

    .empty::before {
    content: 'No live records yet';
    display: block;
    font-family: 'Plus Jakarta Sans', sans-serif;
    color: var(--ink-700);
    font-weight: 700;
    margin-bottom: 4px;
    }

    .auth-shell {
    max-width: 1120px;
    margin: 44px auto;
    padding: 0 20px;
    display: grid;
    grid-template-columns: 1.2fr 0.9fr;
    gap: 20px;
    }

    .auth-hero {
    background:
        radial-gradient(280px 220px at 93% 16%, rgba(199, 233, 255, 0.45) 0%, transparent 78%),
        radial-gradient(220px 190px at 9% 91%, rgba(255, 215, 160, 0.34) 0%, transparent 80%),
        linear-gradient(146deg, #0f7a75 0%, #175c94 54%, #1e3f9f 100%);
    color: #f5fbff;
    border-radius: var(--radius-xl);
    padding: 34px;
    box-shadow: var(--shadow-lg);
    position: relative;
    overflow: hidden;
    }

    .auth-hero h1 {
    margin: 0;
    font-size: 48px;
    line-height: 1;
    font-family: 'Plus Jakarta Sans', sans-serif;
    letter-spacing: -0.8px;
    }

    .auth-hero p {
    margin-top: 13px;
    line-height: 1.5;
    color: rgba(245, 251, 255, 0.95);
    max-width: 80%;
    }

    .auth-list {
    margin: 16px 0 0;
    padding-left: 20px;
    line-height: 1.75;
    }

    .auth-list li::marker {
    color: #b8fff6;
    }

    .auth-card {
    background: linear-gradient(170deg, rgba(255, 255, 255, 0.98), rgba(247, 250, 255, 0.97));
    border-radius: var(--radius-xl);
    border: 1px solid rgba(20, 37, 60, 0.1);
    box-shadow: var(--shadow-md);
    padding: 26px;
    }

    .auth-tabs {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
    margin-bottom: 14px;
    }

    .tab-btn {
    border: 1px solid var(--line);
    border-radius: 10px;
    background: #f4f8ff;
    color: var(--ink-700);
    box-shadow: none;
    }

    .tab-btn.is-active {
    background: linear-gradient(145deg, #e3f7f4, #d9ecff);
    color: var(--brand-strong);
    border-color: #b8d6ef;
    }

    .tab-pane {
    display: none;
    animation: fade-up 0.24s ease both;
    }

    .tab-pane.is-active {
    display: block;
    }

    .chart-box {
    min-height: 280px;
    }

    .chart-box canvas {
    max-height: 320px;
    }

    .app-loader {
    position: fixed;
    inset: 0;
    z-index: 9999;
    background: rgba(236, 244, 252, 0.82);
    backdrop-filter: blur(8px);
    display: grid;
    place-items: center;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.2s ease;
    }

    .app-loader.is-visible {
    opacity: 1;
    pointer-events: all;
    }

    .app-loader.is-hide {
    opacity: 0;
    }

    .app-loader-card {
    width: min(760px, 88vw);
    border-radius: 18px;
    border: 1px solid #ccdaeb;
    background: #ffffff;
    padding: 20px;
    box-shadow: var(--shadow-lg);
    }

    .sk-row {
    height: 14px;
    border-radius: 999px;
    margin-bottom: 11px;
    background: linear-gradient(95deg, #e6edf7 30%, #f7fbff 45%, #e6edf7 60%);
    background-size: 260% 100%;
    animation: sk-shimmer 1.1s linear infinite;
    }

    .sk-row.w-90 { width: 90%; }
    .sk-row.w-78 { width: 78%; }
    .sk-row.w-62 { width: 62%; }
    .sk-row.w-48 { width: 48%; }

    @keyframes sk-shimmer {
    0% {
        background-position: 200% 0;
    }
    100% {
        background-position: -30% 0;
    }
    }

    .reveal {
    animation: fade-up 0.44s ease both;
    }

    .reveal.delay-1 {
    animation-delay: 0.08s;
    }

    .reveal.delay-2 {
    animation-delay: 0.16s;
    }

    .reveal.delay-3 {
    animation-delay: 0.24s;
    }

    @keyframes fade-up {
    from {
        opacity: 0;
        transform: translateY(8px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
    }

    @media (max-width: 1080px) {
    .auth-shell,
    .grid-2 {
        grid-template-columns: 1fr;
    }

    .module-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .page-head {
        flex-direction: column;
        align-items: flex-start;
    }
    }

    @media (max-width: 720px) {
    .nav-inner {
        flex-direction: column;
        align-items: flex-start;
    }

    .page-wrap {
        padding: 0 14px;
    }

    .page-head {
        padding: 14px;
        border-radius: var(--radius-lg);
    }

    .auth-shell {
        margin-top: 18px;
        padding: 0 14px;
    }

    .auth-hero,
    .auth-card {
        padding: 20px;
        border-radius: var(--radius-lg);
    }

    .auth-hero h1 {
        font-size: 34px;
    }

    .auth-hero p {
        max-width: 100%;
    }

    .module-grid {
        grid-template-columns: 1fr;
    }

    .page-actions {
        align-items: flex-start;
    }

    .action-row {
        width: 100%;
    }
    }

    /* ---------- UI System Enhancements ---------- */

    :root {
    --sticky-nav-offset: 78px;
    --control-pad-y: 10px;
    --control-pad-x: 14px;
    --table-cell-pad-y: 10px;
    --table-row-height: 48px;
    }

    :root[data-density='compact'] {
    --control-pad-y: 7px;
    --control-pad-x: 11px;
    --table-cell-pad-y: 7px;
    --table-row-height: 40px;
    }

    :root[data-density='comfortable'] {
    --control-pad-y: 10px;
    --control-pad-x: 14px;
    --table-cell-pad-y: 10px;
    --table-row-height: 48px;
    }

    :root[data-theme='dark'] {
    --ink-950: #f3f7ff;
    --ink-900: #dbe5f5;
    --ink-700: #aac0dc;
    --ink-500: #8ca2c0;
    --ink-300: #6880a1;
    --surface: #132034;
    --surface-soft: #101a2b;
    --line: #30455f;
    --line-strong: #3b5474;
    --brand-soft: #12343e;
    --secondary-soft: #1b2e55;
    --danger-soft: #3a1f2a;
    --ok-soft: #163928;
    --chart-text: #b8cbe4;
    --chart-grid: rgba(184, 203, 228, 0.2);
    --chart-income: #2bb8a8;
    --chart-expense: #ff924a;
    --chart-line: #7ba4ff;
    --chart-line-fill: rgba(123, 164, 255, 0.2);
    --chart-tooltip-bg: rgba(10, 17, 30, 0.96);
    --chart-tooltip-text: #f1f7ff;
    --chart-palette-1: #2bb8a8;
    --chart-palette-2: #6ea8ff;
    --chart-palette-3: #ffae66;
    --chart-palette-4: #ff6a8a;
    --chart-palette-5: #b793ff;
    --chart-palette-6: #7ad87a;
    --chart-palette-7: #62d3ea;
    --shadow-lg: 0 24px 60px rgba(1, 6, 16, 0.5);
    --shadow-md: 0 14px 36px rgba(1, 8, 19, 0.42);
    --shadow-sm: 0 7px 16px rgba(1, 7, 16, 0.36);
    }

    body,
    .site-nav,
    .panel,
    .metric-card,
    .module-card,
    .page-head,
    .page-actions,
    .auth-card,
    .auth-hero,
    input,
    select,
    textarea,
    .btn,
    .tab-btn {
    transition: background 0.24s ease, border-color 0.24s ease, color 0.24s ease, box-shadow 0.24s ease;
    }

    :root[data-theme='dark'] .app-body {
    background:
        radial-gradient(850px 440px at -8% -10%, rgba(13, 61, 77, 0.42) 0%, transparent 70%),
        radial-gradient(760px 380px at 108% -8%, rgba(74, 58, 25, 0.28) 0%, transparent 72%),
        radial-gradient(820px 460px at 50% 120%, rgba(32, 49, 88, 0.5) 0%, transparent 70%),
        linear-gradient(180deg, #0b1220 0%, #0d1626 40%, #101a2c 100%);
    }

    :root[data-theme='dark'] .site-nav {
    background: rgba(12, 20, 34, 0.84);
    border-bottom-color: rgba(113, 138, 176, 0.22);
    }

    :root[data-theme='dark'] .page-head,
    :root[data-theme='dark'] .page-actions,
    :root[data-theme='dark'] .panel,
    :root[data-theme='dark'] .metric-card,
    :root[data-theme='dark'] .module-card,
    :root[data-theme='dark'] .auth-card {
    background: linear-gradient(165deg, rgba(18, 31, 49, 0.97), rgba(15, 25, 40, 0.97));
    border-color: rgba(86, 113, 146, 0.45);
    }

    :root[data-theme='dark'] .auth-hero {
    background:
        radial-gradient(280px 220px at 93% 16%, rgba(54, 102, 152, 0.35) 0%, transparent 78%),
        radial-gradient(220px 190px at 9% 91%, rgba(125, 93, 43, 0.32) 0%, transparent 80%),
        linear-gradient(146deg, #0f5f62 0%, #1a3c6e 54%, #1f3276 100%);
    }

    :root[data-theme='dark'] input,
    :root[data-theme='dark'] select,
    :root[data-theme='dark'] textarea {
    background: #0f1c2f;
    color: #dce7f8;
    border-color: #365071;
    }

    :root[data-theme='dark'] input::placeholder,
    :root[data-theme='dark'] textarea::placeholder {
    color: #7d93b2;
    }

    :root[data-theme='dark'] tr:nth-child(even) td {
    background: #122238;
    }

    :root[data-theme='dark'] tr:hover td {
    background: #162b46;
    }

    :root[data-theme='dark'] th {
    background: linear-gradient(180deg, #152a44 0%, #14263c 100%);
    color: #bad0ea;
    }

    :root[data-theme='dark'] .empty {
    background: linear-gradient(160deg, #102036 0%, #132844 100%);
    border-color: #406081;
    color: #9eb5d1;
    }

    .nav-tools,
    .auth-tools {
    display: flex;
    align-items: center;
    gap: 10px;
    }

    .auth-tools {
    max-width: 1120px;
    margin: 16px auto -28px;
    padding: 0 20px;
    justify-content: flex-end;
    }

    .ui-controls {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    }

    .ui-btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    border: 1px solid var(--line);
    background: var(--surface);
    color: var(--ink-900);
    border-radius: 999px;
    padding: 6px 11px;
    box-shadow: none;
    font-size: 12px;
    min-height: 34px;
    }

    .ui-btn:hover {
    transform: none;
    }

    .density-switch {
    display: inline-flex;
    align-items: center;
    border: 1px solid var(--line);
    border-radius: 999px;
    overflow: hidden;
    background: var(--surface);
    }

    .density-btn {
    border: none;
    padding: 6px 11px;
    font-size: 12px;
    min-height: 34px;
    color: var(--ink-700);
    background: transparent;
    box-shadow: none;
    border-radius: 0;
    }

    .density-btn:hover {
    transform: none;
    }

    .density-btn.is-active {
    background: var(--brand-soft);
    color: var(--brand-strong);
    }

    .icon-inline {
    width: 14px;
    height: 14px;
    display: inline-flex;
    }

    .icon-inline svg,
    .module-icon svg {
    width: 100%;
    height: 100%;
    stroke: currentColor;
    }

    .module-icon {
    color: #1c4f9d;
    }

    .module-icon svg {
    width: 20px;
    height: 20px;
    }

    .is-sticky-section {
    position: sticky;
    top: var(--sticky-nav-offset);
    z-index: 26;
    }

    .page-head.is-sticky-section {
    backdrop-filter: blur(8px);
    }

    button,
    input[type='submit'],
    .btn {
    padding: var(--control-pad-y) var(--control-pad-x);
    }

    input,
    select,
    textarea {
    padding: calc(var(--control-pad-y) + 1px) 12px;
    }

    .table-tools {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 8px;
    flex-wrap: wrap;
    }

    .table-search {
    flex: 1 1 260px;
    }

    .table-search input {
    max-width: 360px;
    }

    .table-filter {
    display: flex;
    align-items: center;
    gap: 8px;
    flex-wrap: wrap;
    }

    .table-filter select {
    width: auto;
    min-width: 160px;
    }

    .table-filter [data-table-value] {
    min-width: 170px;
    }

    .table-reset {
    box-shadow: none;
    min-height: 34px;
    padding: 6px 11px;
    }

    .table-count {
    display: inline-flex;
    align-items: center;
    min-height: 32px;
    padding: 0 10px;
    border-radius: 999px;
    background: var(--secondary-soft);
    color: var(--ink-700);
    border: 1px solid var(--line);
    font-size: 12px;
    font-weight: 700;
    }

    .table-wrap {
    position: relative;
    }

    table {
    border-collapse: separate;
    border-spacing: 0;
    }

    thead th {
    position: sticky;
    top: 0;
    z-index: 3;
    }

    th,
    td {
    padding: var(--table-cell-pad-y) 11px;
    min-height: var(--table-row-height);
    vertical-align: middle;
    }

    tbody tr {
    height: var(--table-row-height);
    }

    tbody td:last-child {
    white-space: nowrap;
    }

    .history-meta {
    margin: -2px 0 10px;
    font-size: 12px;
    }

    .id-pill {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 44px;
    height: 26px;
    border-radius: 999px;
    background: var(--secondary-soft);
    color: var(--ink-700);
    border: 1px solid var(--line);
    font-weight: 800;
    font-size: 12px;
    letter-spacing: 0.1px;
    }

    .amount-cell {
    font-weight: 700;
    font-variant-numeric: tabular-nums;
    }

    .action-cell {
    display: flex;
    gap: 6px;
    align-items: center;
    }

    .action-cell .btn {
    min-width: 68px;
    }

    .table-filter-empty {
    display: none;
    margin-top: 8px;
    border: 1px dashed #c7d8ec;
    border-radius: var(--radius-md);
    background: linear-gradient(160deg, #fbfdff 0%, #f2f8ff 100%);
    color: var(--ink-500);
    text-align: center;
    padding: 10px 12px;
    font-weight: 700;
    }

    .table-filter-empty.is-visible {
    display: block;
    }

    .is-sticky-title {
    position: sticky;
    top: calc(var(--sticky-nav-offset) + 84px);
    z-index: 8;
    background: inherit;
    padding-top: 3px;
    padding-bottom: 8px;
    }

    @media (max-width: 1080px) {
    .is-sticky-section,
    .is-sticky-title {
        position: static;
    }

    .nav-tools {
        width: 100%;
        justify-content: flex-end;
    }
    }

    @media (max-width: 720px) {
    .auth-tools {
        margin-top: 10px;
        margin-bottom: -4px;
        padding: 0 14px;
    }

    .table-search input {
        max-width: 100%;
    }

    .table-filter select {
        min-width: 130px;
    }
    }

    ```

    ## src/main/webapp/META-INF/MANIFEST.MF

    ```text
    Manifest-Version: 1.0
    Class-Path: 


    ```

    ## src/main/webapp/WEB-INF/web.xml

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
            http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
            version="4.0">

        <display-name>ExpenseAnalyzer</display-name>

        <servlet>
            <servlet-name>AuthServlet</servlet-name>
            <servlet-class>com.expenses.controller.AuthServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>AuthServlet</servlet-name>
            <url-pattern>/AuthServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>LoginServlet</servlet-name>
            <servlet-class>com.expenses.controller.LoginServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>LoginServlet</servlet-name>
            <url-pattern>/LoginServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>IncomeServlet</servlet-name>
            <servlet-class>com.expenses.controller.IncomeServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>IncomeServlet</servlet-name>
            <url-pattern>/IncomeServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>ExpenseServlet</servlet-name>
            <servlet-class>com.expenses.controller.ExpenseServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>ExpenseServlet</servlet-name>
            <url-pattern>/ExpenseServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>ReportServlet</servlet-name>
            <servlet-class>com.expenses.controller.ReportServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>ReportServlet</servlet-name>
            <url-pattern>/ReportServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>ProfileServlet</servlet-name>
            <servlet-class>com.expenses.controller.ProfileServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>ProfileServlet</servlet-name>
            <url-pattern>/ProfileServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>AnalysisServlet</servlet-name>
            <servlet-class>com.expenses.controller.AnalysisServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>AnalysisServlet</servlet-name>
            <url-pattern>/AnalysisServlet</url-pattern>
        </servlet-mapping>

        <servlet>
            <servlet-name>BillScanServlet</servlet-name>
            <servlet-class>com.expenses.controller.BillScanServlet</servlet-class>
        </servlet>
        <servlet-mapping>
            <servlet-name>BillScanServlet</servlet-name>
            <url-pattern>/BillScanServlet</url-pattern>
        </servlet-mapping>

        <welcome-file-list>
            <welcome-file>login.jsp</welcome-file>
        </welcome-file-list>

    </web-app>

    ```

    ## db/schema.sql

    ```sql
    CREATE DATABASE IF NOT EXISTS expense_db;
    USE expense_db;

    -- Table for Users
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL
    );

    -- Table for Income
    CREATE TABLE IF NOT EXISTS income (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        amount DOUBLE NOT NULL,
        source VARCHAR(255) NOT NULL,
        date DATE NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Table for Expenses
    CREATE TABLE IF NOT EXISTS expense (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        amount DOUBLE NOT NULL,
        category VARCHAR(255) NOT NULL,
        date DATE NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Initial admin user for first login
    INSERT INTO users (id, name, email, password)
    SELECT 1, 'Admin', 'admin@example.com', 'admin123'
    WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);

    ```

    ## scripts/start.bat

    ```bat
    @echo off
    setlocal EnableExtensions EnableDelayedExpansion
    title Expense Analyzer - Start

    set "NO_PAUSE=0"
    set "NO_OPEN=0"
    for %%A in (%*) do (
    if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
    if /I "%%~A"=="--no-open" set "NO_OPEN=1"
    )

    for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI\"
    set "CATALINA_BASE=%PROJECT_DIR%.tomcat-base"
    set "PF=%ProgramFiles%"

    call :resolveTomcatHome
    if not defined CATALINA_HOME (
    echo [ERROR] Tomcat home kandupidikka mudiyala.
    echo.
    echo One-time fix:
    echo   setx CATALINA_HOME "C:\path\to\apache-tomcat-9.x"
    echo.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    if not defined JAVA_HOME (
    echo [WARN] JAVA_HOME set panna better. Ippo system PATH Java use aagum.
    )

    set "STARTUP_BAT=%CATALINA_HOME%\bin\startup.bat"
    if not exist "%STARTUP_BAT%" (
    echo [ERROR] startup.bat kidaikkala:
    echo   %STARTUP_BAT%
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    call :prepareCatalinaBase
    if errorlevel 1 (
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    call :deployApp
    if errorlevel 1 (
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    echo [INFO] Starting Tomcat...
    echo [INFO] CATALINA_HOME=%CATALINA_HOME%
    echo [INFO] CATALINA_BASE=%CATALINA_BASE%
    call "%STARTUP_BAT%"

    set "APP_CTX=ExpenseAnalyzer"
    set "APP_URL=http://localhost:8080/%APP_CTX%/login.jsp"
    if "%NO_OPEN%"=="0" (
    echo [INFO] Opening %APP_URL%
    start "" "%APP_URL%"
    )
    echo [DONE] Server start command sent.
    exit /b 0

    :prepareCatalinaBase
    if not exist "%CATALINA_BASE%\conf\server.xml" (
    echo [INFO] Initializing project local Tomcat base...
    if exist "%CATALINA_BASE%" rmdir /s /q "%CATALINA_BASE%"
    mkdir "%CATALINA_BASE%\conf" "%CATALINA_BASE%\logs" "%CATALINA_BASE%\temp" "%CATALINA_BASE%\webapps" "%CATALINA_BASE%\work" 2>nul
    xcopy "%CATALINA_HOME%\conf\*" "%CATALINA_BASE%\conf\" /E /I /Y >nul
    if not exist "%CATALINA_BASE%\conf\server.xml" (
        echo [ERROR] CATALINA_BASE initialize aagala.
        exit /b 1
    )
    )
    exit /b 0

    :deployApp
    set "APP_CTX=ExpenseAnalyzer"
    set "APP_DIR=%CATALINA_BASE%\webapps\%APP_CTX%"
    set "SRC_WEBAPP=%PROJECT_DIR%src\main\webapp"
    set "SRC_JAVA=%PROJECT_DIR%src\main\java"
    set "CLASSES_DIR=%APP_DIR%\WEB-INF\classes"
    set "LIB_DIR=%APP_DIR%\WEB-INF\lib"
    set "SERVLET_JAR=%CATALINA_HOME%\lib\servlet-api.jar"
    set "ARGFILE=%TEMP%\expense_java_files_%RANDOM%.txt"

    if not exist "%SRC_WEBAPP%" (
    echo [ERROR] Source webapp path missing:
    echo   %SRC_WEBAPP%
    exit /b 1
    )

    if exist "%APP_DIR%" rmdir /s /q "%APP_DIR%"
    mkdir "%APP_DIR%" 2>nul
    xcopy "%SRC_WEBAPP%\*" "%APP_DIR%\" /E /I /Y >nul
    mkdir "%CLASSES_DIR%" 2>nul
    mkdir "%LIB_DIR%" 2>nul

    if exist "%SRC_WEBAPP%\WEB-INF\lib\*.jar" (
    copy /Y "%SRC_WEBAPP%\WEB-INF\lib\*.jar" "%LIB_DIR%\" >nul
    )

    where javac >nul 2>nul
    if errorlevel 1 (
    echo [WARN] javac kidaikkala. class compile skip pannrom.
    exit /b 0
    )

    if not exist "%SERVLET_JAR%" (
    echo [WARN] servlet-api.jar kidaikkala. class compile skip pannrom.
    exit /b 0
    )

    if not exist "%SRC_JAVA%" (
    echo [WARN] Java source path kidaikkala. class compile skip pannrom.
    exit /b 0
    )

    del /f /q "%ARGFILE%" >nul 2>nul
    for /r "%SRC_JAVA%" %%F in (*.java) do (
    set "SRC_FILE=%%~fF"
    set "SRC_FILE=!SRC_FILE:\=/!"
    echo "!SRC_FILE!">>"%ARGFILE%"
    )

    if not exist "%ARGFILE%" (
    echo [WARN] Java source files illa. class compile skip pannrom.
    exit /b 0
    )

    echo [INFO] Compiling Java classes...
    javac -cp "%SERVLET_JAR%" -d "%CLASSES_DIR%" @"%ARGFILE%"
    if errorlevel 1 (
    echo [ERROR] Java compile fail aayiduchu.
    del /f /q "%ARGFILE%" >nul 2>nul
    exit /b 1
    )
    del /f /q "%ARGFILE%" >nul 2>nul
    echo [INFO] App deployed to %APP_DIR%
    exit /b 0

    :resolveTomcatHome
    if defined CATALINA_HOME goto :eof
    if defined TOMCAT_HOME (
    if exist "%TOMCAT_HOME%\bin\startup.bat" set "CATALINA_HOME=%TOMCAT_HOME%"
    )
    if defined CATALINA_HOME goto :eof

    for /d %%D in ("%PF%\Apache Software Foundation\Tomcat 9.*") do (
    if exist "%%~fD\bin\startup.bat" (
        set "CATALINA_HOME=%%~fD"
        goto :eof
    )
    )

    for /d %%D in ("%PF%\Apache Tomcat 9.*") do (
    if exist "%%~fD\bin\startup.bat" (
        set "CATALINA_HOME=%%~fD"
        goto :eof
    )
    )

    for /d %%D in ("%PF%\TomCat\apache-tomcat*") do (
    if exist "%%~fD\bin\startup.bat" (
        set "CATALINA_HOME=%%~fD"
        goto :eof
    )
    for /d %%E in ("%%~fD\apache-tomcat*") do (
        if exist "%%~fE\bin\startup.bat" (
        set "CATALINA_HOME=%%~fE"
        goto :eof
        )
    )
    )

    goto :eof

    ```

    ## scripts/stop.bat

    ```bat
    @echo off
    setlocal EnableExtensions EnableDelayedExpansion
    title Expense Analyzer - Stop

    set "NO_PAUSE=0"
    for %%A in (%*) do (
    if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
    )

    for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI\"
    set "CATALINA_BASE=%PROJECT_DIR%.tomcat-base"
    set "PF=%ProgramFiles%"

    call :resolveTomcatHome
    if not defined CATALINA_HOME (
    echo [ERROR] Tomcat home kandupidikka mudiyala.
    echo.
    echo One-time fix:
    echo   setx CATALINA_HOME "C:\path\to\apache-tomcat-9.x"
    echo.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    if not exist "%CATALINA_BASE%\conf\server.xml" (
    set "CATALINA_BASE=%CATALINA_HOME%"
    )

    set "SHUTDOWN_BAT=%CATALINA_HOME%\bin\shutdown.bat"
    if not exist "%SHUTDOWN_BAT%" (
    echo [ERROR] shutdown.bat kidaikkala:
    echo   %SHUTDOWN_BAT%
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    echo [INFO] Stopping Tomcat...
    echo [INFO] CATALINA_HOME=%CATALINA_HOME%
    echo [INFO] CATALINA_BASE=%CATALINA_BASE%
    call "%SHUTDOWN_BAT%"
    echo [DONE] Stop command sent.
    exit /b 0

    :resolveTomcatHome
    if defined CATALINA_HOME goto :eof
    if defined TOMCAT_HOME (
    if exist "%TOMCAT_HOME%\bin\shutdown.bat" set "CATALINA_HOME=%TOMCAT_HOME%"
    )
    if defined CATALINA_HOME goto :eof

    for /d %%D in ("%PF%\Apache Software Foundation\Tomcat 9.*") do (
    if exist "%%~fD\bin\shutdown.bat" (
        set "CATALINA_HOME=%%~fD"
        goto :eof
    )
    )

    for /d %%D in ("%PF%\Apache Tomcat 9.*") do (
    if exist "%%~fD\bin\shutdown.bat" (
        set "CATALINA_HOME=%%~fD"
        goto :eof
    )
    )

    for /d %%D in ("%PF%\TomCat\apache-tomcat*") do (
    if exist "%%~fD\bin\shutdown.bat" (
        set "CATALINA_HOME=%%~fD"
        goto :eof
    )
    for /d %%E in ("%%~fD\apache-tomcat*") do (
        if exist "%%~fE\bin\shutdown.bat" (
        set "CATALINA_HOME=%%~fE"
        goto :eof
        )
    )
    )

    goto :eof

    ```

    ## scripts/DB.bat

    ```bat
    @echo off
    setlocal EnableExtensions EnableDelayedExpansion
    title Expense Analyzer - DB Setup

    set "NO_PAUSE=0"
    for %%A in (%*) do (
    if /I "%%~A"=="--no-pause" set "NO_PAUSE=1"
    )

    for %%I in ("%~dp0..") do set "PROJECT_DIR=%%~fI\"
    set "SCHEMA_FILE=%PROJECT_DIR%db\schema.sql"
    set "PF=%ProgramFiles%"

    if not exist "%SCHEMA_FILE%" (
    set "SCHEMA_FILE=%PROJECT_DIR%schema.sql"
    )

    if not exist "%SCHEMA_FILE%" (
    echo [ERROR] schema.sql kidaikkala:
    echo   %SCHEMA_FILE%
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    call :resolveMysqlExe
    if not defined MYSQL_EXE (
    echo [ERROR] mysql.exe kandupidikka mudiyala.
    echo.
    echo One-time fix options:
    echo 1^) MySQL bin PATH add pannunga
    echo 2^) allathu setx MYSQL_HOME "C:\Program Files\MySQL\MySQL Server 8.0"
    echo.
    if "%NO_PAUSE%"=="0" pause
    exit /b 1
    )

    set "MYSQL_HOST=localhost"
    if defined EXPENSE_MYSQL_HOST set "MYSQL_HOST=%EXPENSE_MYSQL_HOST%"

    set "MYSQL_PORT=3306"
    if defined EXPENSE_MYSQL_PORT set "MYSQL_PORT=%EXPENSE_MYSQL_PORT%"

    set "MYSQL_USER=root"
    if defined EXPENSE_MYSQL_USER set "MYSQL_USER=%EXPENSE_MYSQL_USER%"

    set "MYSQL_PASSWORD=root"
    if defined EXPENSE_MYSQL_PASSWORD set "MYSQL_PASSWORD=%EXPENSE_MYSQL_PASSWORD%"

    echo [INFO] MySQL executable: %MYSQL_EXE%
    echo [INFO] Host: %MYSQL_HOST%
    echo [INFO] Port: %MYSQL_PORT%
    echo [INFO] User: %MYSQL_USER%
    echo [INFO] Applying schema.sql...

    "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%MYSQL_USER%" -p"%MYSQL_PASSWORD%" < "%SCHEMA_FILE%"
    if errorlevel 1 (
    if "%NO_PAUSE%"=="1" (
        echo [ERROR] DB setup fail (no-pause mode). EXPENSE_MYSQL_USER / EXPENSE_MYSQL_PASSWORD set pannitu retry pannunga.
        exit /b 1
    )
    echo [WARN] Default credentials work aagala. Manual credential try pannalaam.
    set "INPUT_USER="
    set "INPUT_PASS="
    set /p INPUT_USER=MySQL username default root:
    if not defined INPUT_USER set "INPUT_USER=root"
    set /p INPUT_PASS=MySQL password empty na just Enter:
    if defined INPUT_PASS (
        "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%INPUT_USER%" -p"%INPUT_PASS%" < "%SCHEMA_FILE%"
    ) else (
        "%MYSQL_EXE%" -h "%MYSQL_HOST%" -P %MYSQL_PORT% -u "%INPUT_USER%" < "%SCHEMA_FILE%"
    )
    if errorlevel 1 (
        echo [ERROR] DB setup fail aayiduchu.
        echo.
        echo Check pannunga:
        echo - MySQL server run aagudha?
        echo - username/password correct-aa?
        echo - next time easy-ku env var set pannunga:
        echo     setx EXPENSE_MYSQL_USER "your_user"
        echo     setx EXPENSE_MYSQL_PASSWORD "your_password"
        echo.
        if "%NO_PAUSE%"=="0" pause
        exit /b 1
    )
    )

    echo [DONE] Database ready. (expense_db + tables + default admin user)
    echo [DONE] Login:
    echo   Email: admin@example.com
    echo   Password: admin123
    if "%NO_PAUSE%"=="0" pause
    exit /b 0

    :resolveMysqlExe
    if defined MYSQL_HOME (
    if exist "%MYSQL_HOME%\bin\mysql.exe" (
        set "MYSQL_EXE=%MYSQL_HOME%\bin\mysql.exe"
        goto :eof
    )
    )

    for /f "delims=" %%I in ('where mysql 2^>nul') do (
    set "MYSQL_EXE=%%I"
    goto :eof
    )

    if exist "%PF%\MySQL\MySQL Server 8.0\bin\mysql.exe" (
    set "MYSQL_EXE=%PF%\MySQL\MySQL Server 8.0\bin\mysql.exe"
    goto :eof
    )
    if exist "%PF%\MySQL\MySQL Server 8.4\bin\mysql.exe" (
    set "MYSQL_EXE=%PF%\MySQL\MySQL Server 8.4\bin\mysql.exe"
    goto :eof
    )
    goto :eof

    ```


