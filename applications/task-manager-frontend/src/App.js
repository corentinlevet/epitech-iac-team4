import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Configuration - use environment variable or fallback to loadbalancer URL
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://a5dda51db0b2d4dbeb49d4aa6c79f3a0-256327804.us-east-1.elb.amazonaws.com';

function App() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [apiStatus, setApiStatus] = useState(null);
  
  // Authentication state
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [token, setToken] = useState(localStorage.getItem('token') || '');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  
  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  // Check API health on component mount
  useEffect(() => {
    checkApiHealth();
    if (token) {
      setIsAuthenticated(true);
      fetchTasks();
    }
  }, [token]);

  // Configure axios to use token
  const getAuthHeaders = () => {
    return token ? { Authorization: `Bearer ${token}` } : {};
  };

  const checkApiHealth = async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/health`);
      setApiStatus({
        healthy: true,
        data: response.data
      });
    } catch (err) {
      setApiStatus({
        healthy: false,
        error: err.message
      });
    }
  };

  const login = async (e) => {
    e.preventDefault();
    if (!username.trim() || !password.trim()) {
      setError('Username and password are required');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const response = await axios.post(`${API_BASE_URL}/auth/login`, {
        username: username.trim(),
        password: password.trim()
      });

      const newToken = response.data.access_token;
      setToken(newToken);
      localStorage.setItem('token', newToken);
      setIsAuthenticated(true);
      setSuccess(`Logged in successfully as ${response.data.user_id}!`);
      setUsername('');
      setPassword('');
      
      // Fetch tasks after login
      await fetchTasks();
    } catch (err) {
      setError(`Login failed: ${err.response?.data?.detail || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    setToken('');
    localStorage.removeItem('token');
    setIsAuthenticated(false);
    setTasks([]);
    setSuccess('Logged out successfully');
    setError('');
  };

  const fetchTasks = async () => {
    if (!token) {
      setError('Please login first');
      return;
    }

    setLoading(true);
    setError('');
    try {
      const response = await axios.get(`${API_BASE_URL}/tasks`, {
        headers: getAuthHeaders()
      });
      setTasks(response.data);
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Authentication expired. Please login again.');
        logout();
      } else {
        setError(`Failed to fetch tasks: ${err.message}`);
      }
    } finally {
      setLoading(false);
    }
  };

  const createTask = async (e) => {
    e.preventDefault();
    if (!title.trim()) {
      setError('Task title is required');
      return;
    }

    if (!token) {
      setError('Please login first');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');
    
    try {
      const response = await axios.post(`${API_BASE_URL}/tasks`, {
        title: title.trim(),
        description: description.trim() || null
      }, {
        headers: getAuthHeaders()
      });
      
      setSuccess('Task created successfully!');
      setTitle('');
      setDescription('');
      
      // Refresh tasks list
      await fetchTasks();
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Authentication expired. Please login again.');
        logout();
      } else {
        setError(`Failed to create task: ${err.response?.data?.detail || err.message}`);
      }
    } finally {
      setLoading(false);
    }
  };

  const deleteTask = async (taskId) => {
    if (!window.confirm('Are you sure you want to delete this task?')) {
      return;
    }

    if (!token) {
      setError('Please login first');
      return;
    }

    setLoading(true);
    setError('');
    setSuccess('');
    
    try {
      await axios.delete(`${API_BASE_URL}/tasks/${taskId}`, {
        headers: getAuthHeaders()
      });
      setSuccess('Task deleted successfully!');
      await fetchTasks();
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Authentication expired. Please login again.');
        logout();
      } else {
        setError(`Failed to delete task: ${err.response?.data?.detail || err.message}`);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <div className="header">
        <h1>Task Manager Frontend</h1>
        <p>A React application that consumes the Task Manager API</p>
        {isAuthenticated && (
          <div style={{ marginTop: '10px' }}>
            <span style={{ marginRight: '10px' }}>✅ Authenticated</span>
            <button onClick={logout} className="btn btn-danger">Logout</button>
          </div>
        )}
      </div>

      {/* API Status */}
      <div className="api-status">
        <h3>API Status</h3>
        {apiStatus ? (
          apiStatus.healthy ? (
            <div className="status-healthy">
              ✅ API is healthy - {apiStatus.data?.timestamp}
              <br />
              <strong>API URL:</strong> {API_BASE_URL}
            </div>
          ) : (
            <div className="status-error">
              ❌ API is not responding - {apiStatus.error}
              <br />
              <strong>API URL:</strong> {API_BASE_URL}
            </div>
          )
        ) : (
          <div>Checking API status...</div>
        )}
      </div>

      {/* Error/Success Messages */}
      {error && <div className="error">{error}</div>}
      {success && <div className="success">{success}</div>}

      {/* Login Form */}
      {!isAuthenticated && (
        <div className="task-form">
          <h2>Login Required</h2>
          <p>Please login to access the task management features.</p>
          <form onSubmit={login}>
            <div className="form-group">
              <label htmlFor="username">Username</label>
              <input
                type="text"
                id="username"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Enter any username (demo)"
                disabled={loading}
              />
            </div>
            
            <div className="form-group">
              <label htmlFor="password">Password</label>
              <input
                type="password"
                id="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter any password (demo)"
                disabled={loading}
              />
            </div>
            
            <button type="submit" className="btn" disabled={loading}>
              {loading ? 'Logging in...' : 'Login'}
            </button>
          </form>
          <div style={{ marginTop: '15px', padding: '10px', backgroundColor: '#e8f4f8', borderRadius: '4px' }}>
            <strong>Demo Note:</strong> This is a demo application. You can login with any username and password combination.
          </div>
        </div>
      )}

      {/* Task Management (only show when authenticated) */}
      {isAuthenticated && (
        <>
          {/* Task Creation Form */}
          <div className="task-form">
            <h2>Create New Task</h2>
            <form onSubmit={createTask}>
              <div className="form-group">
                <label htmlFor="title">Task Title *</label>
                <input
                  type="text"
                  id="title"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Enter task title"
                  disabled={loading}
                />
              </div>
              
              <div className="form-group">
                <label htmlFor="description">Description</label>
                <textarea
                  id="description"
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Enter task description (optional)"
                  disabled={loading}
                />
              </div>
              
              <button type="submit" className="btn" disabled={loading}>
                {loading ? 'Creating...' : 'Create Task'}
              </button>
            </form>
          </div>

          {/* Tasks List */}
          <div className="tasks-list">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
              <h2>Tasks</h2>
              <button onClick={fetchTasks} className="btn" disabled={loading}>
                {loading ? 'Loading...' : 'Refresh'}
              </button>
            </div>

            {loading && <div className="loading">Loading tasks...</div>}
            
            {!loading && tasks.length === 0 && (
              <div>No tasks found. Create your first task above!</div>
            )}

            {tasks.map((task) => (
              <div key={task.id} className="task-item">
                <div className="task-title">{task.title}</div>
                {task.description && (
                  <div className="task-description">{task.description}</div>
                )}
                <div className="task-meta">
                  ID: {task.id} | Created: {new Date(task.created_at).toLocaleString()}
                  {task.updated_at && task.updated_at !== task.created_at && (
                    <span> | Updated: {new Date(task.updated_at).toLocaleString()}</span>
                  )}
                </div>
                <button
                  onClick={() => deleteTask(task.id)}
                  className="btn btn-danger"
                  disabled={loading}
                >
                  Delete
                </button>
              </div>
            ))}
          </div>
        </>
      )}

      {/* API Information */}
      <div className="api-status" style={{ marginTop: '30px' }}>
        <h3>API Information</h3>
        <p><strong>Backend API:</strong> {API_BASE_URL}</p>
        <p><strong>Health Endpoint:</strong> <a href={`${API_BASE_URL}/health`} target="_blank" rel="noopener noreferrer">{API_BASE_URL}/health</a></p>
        <p><strong>API Documentation:</strong> <a href={`${API_BASE_URL}/docs`} target="_blank" rel="noopener noreferrer">{API_BASE_URL}/docs</a></p>
        <p><strong>Authentication:</strong> Demo login - any username/password combination works</p>
      </div>
    </div>
  );
}

export default App;