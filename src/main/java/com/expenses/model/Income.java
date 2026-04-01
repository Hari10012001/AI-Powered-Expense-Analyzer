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
