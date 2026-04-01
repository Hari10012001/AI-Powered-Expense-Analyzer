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
