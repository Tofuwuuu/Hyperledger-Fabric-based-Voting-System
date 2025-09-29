import React from 'react';
import { Navigate } from 'react-router-dom';

const getUser = () => {
  try {
    return JSON.parse(localStorage.getItem('user') || '{}');
  } catch (_) {
    return {};
  }
};

export const RequireAuth = ({ children }) => {
  const token = localStorage.getItem('token');
  if (!token) {
    return <Navigate to="/" replace />;
  }
  return children;
};

export const RequireRole = ({ role, children }) => {
  const token = localStorage.getItem('token');
  const user = getUser();
  if (!token) {
    return <Navigate to="/" replace />;
  }
  if (!user?.role || user.role !== role) {
    // Redirect user to their default route if role mismatches
    if (user?.role === 'admin') return <Navigate to="/admin" replace />;
    if (user?.role === 'voter') return <Navigate to="/vote" replace />;
    if (user?.role === 'auditor') return <Navigate to="/results" replace />;
    return <Navigate to="/" replace />;
  }
  return children;
};


