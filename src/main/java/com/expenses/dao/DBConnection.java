package com.expenses.dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;

public class DBConnection {

    private static final Map<String, String> ENV = System.getenv();

    private static final String MYSQL_URL = resolveMySqlUrl();
    private static final String MYSQL_USER = firstNonBlank("root", "EXPENSE_MYSQL_USER", "MYSQLUSER", "MYSQL_USER");
    private static final String MYSQL_PASSWORD = firstNonBlank(
            "root",
            "EXPENSE_MYSQL_PASSWORD",
            "MYSQLPASSWORD",
            "MYSQL_PASSWORD");

    private static final String H2_URL = firstNonBlank(
            "jdbc:h2:./data/expense_db;MODE=MySQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE",
            "EXPENSE_H2_URL");
    private static final String H2_USER = firstNonBlank("sa", "EXPENSE_H2_USER");
    private static final String H2_PASSWORD = firstNonBlank("", "EXPENSE_H2_PASSWORD");

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

    private static String resolveMySqlUrl() {
        String explicitUrl = firstEnvNonBlank("EXPENSE_MYSQL_URL", "MYSQL_URL");
        if (explicitUrl != null) {
            return explicitUrl;
        }

        String host = firstEnvNonBlank("MYSQLHOST", "MYSQL_HOST");
        String port = firstNonBlank("3306", "MYSQLPORT", "MYSQL_PORT");
        String database = firstNonBlank("expense_db", "MYSQLDATABASE", "MYSQL_DATABASE");

        if (host != null) {
            return "jdbc:mysql://" + host + ":" + port + "/" + database
                    + "?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC";
        }

        return "jdbc:mysql://localhost:3306/expense_db?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC";
    }

    private static String firstEnvNonBlank(String... keys) {
        for (String key : keys) {
            String value = ENV.get(key);
            if (value != null && !value.trim().isEmpty()) {
                return value.trim();
            }
        }
        return null;
    }

    private static String firstNonBlank(String defaultValue, String... keys) {
        String value = firstEnvNonBlank(keys);
        return value != null ? value : defaultValue;
    }
}
