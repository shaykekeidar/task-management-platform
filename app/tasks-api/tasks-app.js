const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const { Pool } = require('pg');

const app = express();

const pool = new Pool({
  host: process.env.DB_HOST || 'postgres',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'tasksdb',
  user: process.env.DB_USER || 'taskuser',
  password: process.env.DB_PASSWORD || 'taskpass'
});

async function initDb() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS tasks (
      id SERIAL PRIMARY KEY,
      title TEXT,
      text TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS completed_tasks (
      id INTEGER PRIMARY KEY,
      title TEXT,
      text TEXT NOT NULL,
      created_at TIMESTAMP,
      completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  console.log('PostgreSQL tasks tables are ready');
}

app.use(bodyParser.json());

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST,GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  next();
});

app.get('/versions', function (req, res) {
  res.json({
    frontend: process.env.FRONTEND_VERSION || 'unknown',
    tasks: process.env.TASKS_VERSION || 'unknown',
    users: process.env.USERS_VERSION || 'unknown',
    auth: process.env.AUTH_VERSION || 'unknown'
  });
});

const extractAndVerifyToken = async (headers) => {
  if (!headers.authorization) {
    throw new Error('No token provided.');
  }

  const token = headers.authorization.split(' ')[1];

  const response = await axios.get(
    `http://${process.env.AUTH_SERVICE_SERVICE_HOST}/verify-token/` + token
  );

  return response.data.uid;
};

app.get('/tasks', async (req, res) => {
  try {
    await extractAndVerifyToken(req.headers);

    const result = await pool.query(
      'SELECT id, title, text, created_at FROM tasks ORDER BY id'
    );

    res.status(200).json({
      message: 'Tasks loaded.',
      tasks: result.rows
    });
  } catch (err) {
    console.log(err);

    return res.status(401).json({
      message: err.message || 'Failed to load tasks.'
    });
  }
});

app.post('/tasks', async (req, res) => {
  try {
    await extractAndVerifyToken(req.headers);

    const text = req.body.text;
    const title = req.body.title;

    if (!text) {
      return res.status(400).json({
        message: 'Task text is required.'
      });
    }

    const result = await pool.query(
      'INSERT INTO tasks (title, text) VALUES ($1, $2) RETURNING id, title, text, created_at',
      [title, text]
    );

    res.status(201).json({
      message: 'Task stored.',
      createdTask: result.rows[0]
    });
  } catch (err) {
    console.log(err);

    return res.status(401).json({
      message: 'Could not verify token.'
    });
  }
});

app.post('/tasks/:id/complete', async (req, res) => {
  const client = await pool.connect();

  try {
    await extractAndVerifyToken(req.headers);

    const taskId = req.params.id;

    await client.query('BEGIN');

    const taskResult = await client.query(
      'SELECT id, title, text, created_at FROM tasks WHERE id = $1',
      [taskId]
    );

    if (taskResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        message: 'Task not found.'
      });
    }

    const task = taskResult.rows[0];

    await client.query(
      'INSERT INTO completed_tasks (id, title, text, created_at) VALUES ($1, $2, $3, $4)',
      [task.id, task.title, task.text, task.created_at]
    );

    await client.query('DELETE FROM tasks WHERE id = $1', [taskId]);

    await client.query('COMMIT');

    res.status(200).json({
      message: 'Task completed.',
      completedTask: task
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.log(err);

    res.status(500).json({
      message: err.message || 'Failed to complete task.'
    });
  } finally {
    client.release();
  }
});

app.get('/completed-tasks', async (req, res) => {
  try {
    await extractAndVerifyToken(req.headers);

    const result = await pool.query(
      'SELECT id, title, text, created_at, completed_at FROM completed_tasks ORDER BY completed_at DESC'
    );

    res.status(200).json({
      message: 'Completed tasks loaded.',
      completedTasks: result.rows
    });
  } catch (err) {
    console.log(err);

    return res.status(401).json({
      message: err.message || 'Failed to load completed tasks.'
    });
  }
});

initDb()
  .then(() => {
    app.listen(8000, () => {
      console.log('Tasks API started');
      console.log(`PostgreSQL host: ${process.env.DB_HOST || 'postgres'}`);
    });
  })
  .catch((err) => {
    console.error('Failed to initialize PostgreSQL:', err);
    process.exit(1);
  });