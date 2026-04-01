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
