/**
 * User Service - Clean, well-formatted code
 * This should PASS all ESLint checks
 */

class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
    this.timestamp = new Date().toISOString();
  }
}

class UserService {
  constructor(database) {
    this.database = database;
    this.users = new Map();
    this.cache = new Map();
    this.cacheTimeout = 5000;
  }

  validateEmail(email) {
    if (!email || typeof email !== 'string') {
      return false;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  validatePassword(password) {
    if (!password || typeof password !== 'string') {
      return { valid: false, score: 0, reason: 'Password is required' };
    }

    let score = 0;
    const checks = {
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /[0-9]/.test(password),
      special: /[!@#$%^&*(),.?":{}|<>]/.test(password),
    };

    Object.values(checks).forEach((passed) => {
      if (passed) {
        score += 20;
      }
    });

    const minScore = 60;
    return {
      valid: score >= minScore,
      score,
      checks,
      reason: score < minScore ? 'Password too weak' : 'Password acceptable',
    };
  }

  async createUser(userData) {
    const { email, password, name, age } = userData;

    if (!this.validateEmail(email)) {
      throw new ValidationError('Invalid email format', 'email');
    }

    const passwordValidation = this.validatePassword(password);
    if (!passwordValidation.valid) {
      throw new ValidationError(passwordValidation.reason, 'password');
    }

    const minNameLength = 2;
    if (!name || name.trim().length < minNameLength) {
      throw new ValidationError('Name must be at least 2 characters', 'name');
    }

    const minAge = 13;
    const maxAge = 120;
    if (age !== undefined && (typeof age !== 'number' || age < minAge || age > maxAge)) {
      throw new ValidationError('Age must be between 13 and 120', 'age');
    }

    if (this.users.has(email)) {
      throw new ValidationError('User already exists', 'email');
    }

    const user = {
      id: this.generateUserId(),
      email,
      name: name.trim(),
      age: age || null,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      isActive: true,
    };

    await this.saveToDatabase(user);
    this.users.set(email, user);
    this.cache.clear();

    return this.sanitizeUser(user);
  }

  async getUserByEmail(email) {
    if (!this.validateEmail(email)) {
      return null;
    }

    const cacheKey = `user:${email}`;
    if (this.cache.has(cacheKey)) {
      const cached = this.cache.get(cacheKey);
      if (Date.now() - cached.timestamp < this.cacheTimeout) {
        return cached.data;
      }
      this.cache.delete(cacheKey);
    }

    let user = this.users.get(email);

    if (!user) {
      user = await this.fetchFromDatabase(email);
      if (user) {
        this.users.set(email, user);
      }
    }

    if (user) {
      this.cache.set(cacheKey, {
        data: this.sanitizeUser(user),
        timestamp: Date.now(),
      });
    }

    return user ? this.sanitizeUser(user) : null;
  }

  generateUserId() {
    const randomPart = 9;
    return `user_${Date.now()}_${Math.random().toString(36).substr(2, randomPart)}`;
  }

  sanitizeUser(user) {
    // eslint-disable-next-line no-unused-vars
    const { password, ...sanitized } = user;
    return sanitized;
  }

  async saveToDatabase(user) {
    if (this.database && typeof this.database.save === 'function') {
      return await this.database.save(user);
    }
    return Promise.resolve();
  }

  async fetchFromDatabase(email) {
    if (this.database && typeof this.database.fetch === 'function') {
      return await this.database.fetch(email);
    }
    return Promise.resolve(null);
  }
}

module.exports = { UserService, ValidationError };