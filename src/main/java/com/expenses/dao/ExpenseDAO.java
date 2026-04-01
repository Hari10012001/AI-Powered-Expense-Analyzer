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
