import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import Login from './components/Login';
import VotingPage from './components/VotingPage';
import Results from './components/Results';
import Navigation from './components/Navigation';
import Admin from './components/Admin';
import Verify from './components/Verify';
import DemoVoting from './components/DemoVoting';
import { RequireAuth, RequireRole } from './components/RouteGuards';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Navigation />
        <Routes>
          <Route path="/" element={<DemoVoting />} />
          <Route path="/login" element={<Login />} />
          <Route
            path="/vote"
            element={(<RequireRole role="voter"><VotingPage /></RequireRole>)}
          />
          <Route
            path="/admin"
            element={(<RequireRole role="admin"><Admin /></RequireRole>)}
          />
          <Route
            path="/results"
            element={(<RequireRole role="auditor"><Results /></RequireRole>)}
          />
          <Route
            path="/verify"
            element={(<RequireAuth><Verify /></RequireAuth>)}
          />
        </Routes>
      </Router>
    </ThemeProvider>
  );
}

export default App;