import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Configuration - use environment variable or fallback to loadbalancer URL
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com';

function App() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [apiStatus, setApiStatus] = useState(null);
  
  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');

  // Check API health on component mount
  useEffect(() => {
    checkApiHealth();
    fetchTasks();
  }, []);

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

  const fetchTasks = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await axios.get(`${API_BASE_URL}/tasks`);
      setTasks(response.data);
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Authentication required. This API requires login to access tasks.');
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

    setLoading(true);
    setError('');
    setSuccess('');
    
    try {
      const response = await axios.post(`${API_BASE_URL}/tasks`, {
        title: title.trim(),
        description: description.trim()
      });
      
      setSuccess('Task created successfully!');
      setTitle('');
      setDescription('');
      
      // Refresh tasks list
      await fetchTasks();
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Authentication required. Cannot create tasks without login.');
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

    setLoading(true);
    setError('');
    setSuccess('');
    
    try {
      await axios.delete(`${API_BASE_URL}/tasks/${taskId}`);
      setSuccess('Task deleted successfully!');
      await fetchTasks();
    } catch (err) {
      if (err.response?.status === 401) {
        setError('Authentication required. Cannot delete tasks without login.');
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

      {/* API Information */}
      <div className="api-status" style={{ marginTop: '30px' }}>
        <h3>API Information</h3>
        <p><strong>Backend API:</strong> {API_BASE_URL}</p>
        <p><strong>Health Endpoint:</strong> <a href={`${API_BASE_URL}/health`} target="_blank" rel="noopener noreferrer">{API_BASE_URL}/health</a></p>
        <p><strong>API Documentation:</strong> <a href={`${API_BASE_URL}/docs`} target="_blank" rel="noopener noreferrer">{API_BASE_URL}/docs</a></p>
        <p><strong>Note:</strong> Some operations may require authentication depending on the backend configuration.</p>
      </div>
    </div>
  );
}

export default App;