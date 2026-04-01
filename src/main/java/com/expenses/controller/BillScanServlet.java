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
