#!/usr/bin/env python3
"""
app.py - Main entry point for Tech Enterprise Application
Author: Tech Enterprise Team
Description: Enterprise-grade web application with Flask framework
"""

import os
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
from flask import Flask, jsonify, request, render_template, session
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Configuration
class Config:
    """Application configuration"""
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', 'sqlite:///tech_enterprise.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    DEBUG = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    PORT = int(os.environ.get('PORT', 5000))
    
    # Enterprise settings
    UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max upload
    ALLOWED_EXTENSIONS = {'txt', 'pdf', 'png', 'jpg', 'jpeg', 'gif', 'csv', 'xlsx'}
    
    # API rate limiting (if using Flask-Limiter)
    RATELIMIT_DEFAULT = "100/hour"
    RATELIMIT_STORAGE_URL = "memory://"

app.config.from_object(Config)

# Initialize extensions
CORS(app, resources={r"/api/*": {"origins": "*"}})
db = SQLAlchemy(app)
migrate = Migrate(app, db)

# Configure logging
def setup_logging():
    """Setup application logging"""
    if not os.path.exists('logs'):
        os.mkdir('logs')
    
    file_handler = RotatingFileHandler('logs/tech_enterprise.log', maxBytes=10240, backupCount=10)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
    ))
    file_handler.setLevel(logging.INFO)
    
    app.logger.addHandler(file_handler)
    app.logger.setLevel(logging.INFO)
    app.logger.info('Tech Enterprise application startup')

setup_logging()

# Database Models
class User(db.Model):
    """User model for authentication"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_active = db.Column(db.Boolean, default=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'is_active': self.is_active
        }

class EnterpriseData(db.Model):
    """Enterprise data model"""
    __tablename__ = 'enterprise_data'
    
    id = db.Column(db.Integer, primary_key=True)
    data_key = db.Column(db.String(255), nullable=False)
    data_value = db.Column(db.Text)
    category = db.Column(db.String(100))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def to_dict(self):
        return {
            'id': self.id,
            'data_key': self.data_key,
            'data_value': self.data_value,
            'category': self.category,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Create tables
with app.app_context():
    db.create_all()
    app.logger.info("Database tables created/verified")

# Routes
@app.route('/')
def index():
    """Home page route"""
    return jsonify({
        'application': 'Tech Enterprise API',
        'version': '1.0.0',
        'status': 'operational',
        'timestamp': datetime.utcnow().isoformat(),
        'endpoints': {
            'health': '/health',
            'api': '/api/v1/',
            'users': '/api/v1/users',
            'data': '/api/v1/data'
        }
    })

@app.route('/health')
def health_check():
    """Health check endpoint for monitoring"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'database': 'connected' if db.engine else 'disconnected'
    }), 200

# API Routes
@app.route('/api/v1/users', methods=['GET'])
def get_users():
    """Get all users"""
    try:
        users = User.query.all()
        return jsonify({
            'success': True,
            'data': [user.to_dict() for user in users],
            'count': len(users)
        }), 200
    except Exception as e:
        app.logger.error(f"Error fetching users: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/users', methods=['POST'])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        
        if not data.get('username') or not data.get('email'):
            return jsonify({'success': False, 'error': 'Username and email required'}), 400
        
        # Check if user exists
        existing_user = User.query.filter(
            (User.username == data['username']) | (User.email == data['email'])
        ).first()
        
        if existing_user:
            return jsonify({'success': False, 'error': 'User already exists'}), 409
        
        user = User(username=data['username'], email=data['email'])
        db.session.add(user)
        db.session.commit()
        
        app.logger.info(f"User created: {user.username}")
        return jsonify({'success': True, 'data': user.to_dict()}), 201
    
    except Exception as e:
        db.session.rollback()
        app.logger.error(f"Error creating user: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/data', methods=['GET'])
def get_enterprise_data():
    """Get enterprise data with filtering"""
    try:
        category = request.args.get('category')
        query = EnterpriseData.query
        
        if category:
            query = query.filter_by(category=category)
        
        data = query.all()
        return jsonify({
            'success': True,
            'data': [item.to_dict() for item in data],
            'count': len(data)
        }), 200
    except Exception as e:
        app.logger.error(f"Error fetching data: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/v1/data', methods=['POST'])
def create_enterprise_data():
    """Create new enterprise data"""
    try:
        data = request.get_json()
        
        if not data.get('data_key'):
            return jsonify({'success': False, 'error': 'data_key is required'}), 400
        
        enterprise_data = EnterpriseData(
            data_key=data['data_key'],
            data_value=data.get('data_value', ''),
            category=data.get('category', 'general')
        )
        db.session.add(enterprise_data)
        db.session.commit()
        
        app.logger.info(f"Enterprise data created: {enterprise_data.data_key}")
        return jsonify({'success': True, 'data': enterprise_data.to_dict()}), 201
    
    except Exception as e:
        db.session.rollback()
        app.logger.error(f"Error creating enterprise data: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({'success': False, 'error': 'Resource not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    db.session.rollback()
    app.logger.error(f"Internal server error: {str(error)}")
    return jsonify({'success': False, 'error': 'Internal server error'}), 500

# Main execution
if __name__ == '__main__':
    app.logger.info(f"Starting Tech Enterprise application on port {app.config['PORT']}")
    app.run(
        host='0.0.0.0',
        port=app.config['PORT'],
        debug=app.config['DEBUG']
    )
