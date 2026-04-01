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
