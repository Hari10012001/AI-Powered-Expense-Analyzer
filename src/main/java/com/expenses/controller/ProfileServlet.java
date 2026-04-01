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
