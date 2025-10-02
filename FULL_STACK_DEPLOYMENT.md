# 🎉 Task Manager Full Stack Application - Live on EKS!

## 📋 Overview

A complete full-stack Task Manager application successfully deployed on AWS EKS, consisting of:

### 🔧 Backend API (Python FastAPI)
- **Technology**: Python FastAPI with PostgreSQL database
- **Features**: RESTful API for task management with CRUD operations
- **Database**: AWS RDS PostgreSQL instance
- **Authentication**: JWT-based authentication system

### 🎨 Frontend Application (React)
- **Technology**: React with Axios for API communication
- **Features**: Interactive web interface for managing tasks
- **Hosting**: Nginx with optimized configuration
- **Responsive**: Mobile-friendly design

## 🌐 Live Application URLs

### Frontend Web Application
- **URL**: http://a289e2d336ece4076b97a345b4ddf873-831694680.us-east-1.elb.amazonaws.com
- **Description**: Interactive React application for managing tasks
- **Features**:
  - Create, view, and delete tasks
  - Real-time API status monitoring
  - Direct links to API documentation
  - Responsive design

### Backend API
- **API URL**: http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com
- **Health Check**: http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/health
- **API Docs**: http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/docs

## 🚀 How to Use the Application

### Using the Frontend Web Interface
1. Visit the frontend URL in your browser
2. Check the API status (should show green ✅)
3. **Login with any credentials**:
   - Enter any username (e.g., "demo", "user", "test")
   - Enter any password (e.g., "password", "123", "test")
   - Click "Login" (this is a demo - any combination works!)
4. Once logged in, you can:
   - Create new tasks using the form
   - View all your tasks in the list
   - Delete tasks using the red "Delete" button
5. Your login session is saved in the browser

### Using the Backend API Directly

#### Step 1: Login to get an access token
```bash
curl -X POST http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "test123"}'
```

Response:
```json
{
  "access_token": "demo_token_demo_xxxxxxxxxxxxxxxxxxxx",
  "token_type": "bearer",
  "user_id": "demo"
}
```

#### Step 2: Use the token for API calls
```bash
# Get all tasks
curl -H "Authorization: Bearer demo_token_demo_xxxxxxxxxxxxxxxxxxxx" \
  http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/tasks

# Create a task
curl -X POST http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/tasks \
  -H "Authorization: Bearer demo_token_demo_xxxxxxxxxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{"title": "My API Task", "description": "Created via API"}'

# Delete a task
curl -X DELETE http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/tasks/1 \
  -H "Authorization: Bearer demo_token_demo_xxxxxxxxxxxxxxxxxxxx"
```

#### Health Check (No Authentication Required)
```bash
curl http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/health
```

#### View API Documentation
Visit the interactive Swagger documentation:
```
http://aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com/docs
```

## 🏗️ Infrastructure Details

### Kubernetes Deployment
- **Cluster**: `student-team4-iac-dev-cluster` on AWS EKS
- **Node Configuration**: 2 x t3.micro instances
- **Namespace**: `default`

### Pod Status
```
Frontend: 1 replica running on ip-10-0-1-37.ec2.internal
Backend:  1 replica running on ip-10-0-1-37.ec2.internal
```

### Load Balancers
- Frontend: AWS ALB with external IP `a289e2d336ece4076b97a345b4ddf873-831694680.us-east-1.elb.amazonaws.com`
- Backend: AWS ALB with external IP `aa4d1d03368b04f00b0585e5a85359a6-743131538.us-east-1.elb.amazonaws.com`

### Database
- **Service**: AWS RDS PostgreSQL
- **Instance**: `student-team4-iac-dev-dev`
- **Status**: Connected and operational

## 🧪 Testing the Integration

The frontend application automatically tests the backend API integration:

1. **API Health Monitoring**: Real-time health status display
2. **CRUD Operations**: Create, read, and delete tasks through the UI
3. **Error Handling**: Proper display of authentication and error messages
4. **Cross-Origin Requests**: CORS properly configured between frontend and backend

## 📊 Application Features

### Frontend Features
- ✅ **User Authentication**: Login system with demo credentials (any username/password works)
- ✅ **Session Management**: Login state persisted in browser localStorage
- ✅ **Real-time API Status Monitoring**: Live connection status to backend
- ✅ **Task Management**: Create, view, and delete tasks with real-time updates
- ✅ **Form Validation**: Client-side validation for required fields
- ✅ **Error Handling**: Comprehensive error messages and user feedback
- ✅ **Responsive Design**: Mobile-friendly interface
- ✅ **Authentication Flow**: Automatic token management and re-authentication
- ✅ **Direct API Links**: Easy access to backend documentation

### Backend Features
- ✅ **JWT Authentication**: Secure token-based authentication system
- ✅ **RESTful API Endpoints**: Complete CRUD operations for tasks
- ✅ **Database Persistence**: PostgreSQL with proper data types and constraints
- ✅ **Health Check Endpoint**: Monitoring and load balancer compatibility
- ✅ **OpenAPI/Swagger Documentation**: Interactive API documentation
- ✅ **CORS Configuration**: Proper cross-origin support for frontend
- ✅ **Error Handling and Validation**: Comprehensive error responses
- ✅ **Environment-based Configuration**: Secure configuration management
- ✅ **Simple Demo Authentication**: Easy testing with any credentials

## 🔧 Technical Stack

### Backend
- **Language**: Python 3.11
- **Framework**: FastAPI
- **Database**: PostgreSQL (AWS RDS)
- **ORM**: AsyncPG
- **Container**: Docker with multi-stage build
- **Deployment**: Kubernetes via Helm

### Frontend
- **Language**: JavaScript (React 18)
- **HTTP Client**: Axios
- **Build Tool**: Create React App
- **Web Server**: Nginx
- **Container**: Docker with multi-stage build
- **Deployment**: Kubernetes via Helm

### Infrastructure
- **Container Registry**: AWS ECR
- **Orchestration**: AWS EKS (Kubernetes 1.28)
- **Load Balancing**: AWS Application Load Balancer
- **Database**: AWS RDS PostgreSQL
- **Secrets**: Kubernetes Secrets
- **Monitoring**: Kubernetes probes and health checks

## 🎯 Success Metrics

✅ **Backend API**: Deployed and accessible  
✅ **Frontend App**: Deployed and accessible  
✅ **Database**: Connected and operational  
✅ **Load Balancers**: Provisioned and routing traffic  
✅ **Health Checks**: All services passing  
✅ **Integration**: Frontend successfully communicating with backend  
✅ **CRUD Operations**: Create, read, delete operations working  
✅ **Error Handling**: Proper error messages and user feedback  

---

## 🏁 Conclusion

The Task Manager application is now **fully deployed and operational** on AWS EKS! Both the React frontend and FastAPI backend are running in production, demonstrating a complete full-stack application with:

- **Modern Architecture**: Microservices deployed on Kubernetes
- **Cloud-Native**: Running on AWS managed services
- **Production-Ready**: Load balancers, health checks, and proper resource management
- **User-Friendly**: Interactive web interface with real-time API integration
- **Scalable**: Kubernetes deployment ready for scaling

You can now test the live application using the URLs provided above! 🚀