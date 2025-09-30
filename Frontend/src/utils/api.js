import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL || 'http://localhost:3001';

export const api = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  headers: {
    'Content-Type': 'application/json'
  }
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error?.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      // Let the caller decide what to do, but include a flag
      error.isUnauthorized = true;
    }
    return Promise.reject(error);
  }
);

export const authApi = {
  login: (payload) => api.post('/login', payload),
};

export const electionApi = {
  getPublicKey: () => api.get('/election/public-key'),
  getCandidates: () => api.get('/candidates'),
  castVote: (payload) => api.post('/vote/cast', payload),
  getResultsFor: (candidateId) => api.get(`/results/${candidateId}`),
  getVerify: () => api.get('/vote/verify'),
  seedCandidates: (candidates) => api.post('/candidates/seed', { candidates }),
};



