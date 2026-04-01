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
