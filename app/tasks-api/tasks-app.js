const path = require('path');
const fs = require('fs');
const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');

const tasksFolder = process.env.TASKS_FOLDER || 'tasks';
const filePath = path.join(__dirname, tasksFolder, 'tasks.db');

const app = express();

app.get('/versions', function (req, res) {
  res.json({
    frontend: process.env.FRONTEND_VERSION || 'unknown',
    tasks: process.env.TASKS_VERSION || 'unknown',
    users: process.env.USERS_VERSION || 'unknown',
    auth: process.env.AUTH_VERSION || 'unknown'
  });
});

app.use(bodyParser.json());

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST,GET,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
  next();
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

    fs.readFile(filePath, (err, data) => {
      if (err) {
        console.log(err);
        return res.status(500).json({ message: 'Loading the tasks failed.' });
      }

      const strData = data.toString();

      if (!strData.trim()) {
        return res.status(200).json({ message: 'Tasks loaded.', tasks: [] });
      }

      const entries = strData.split('TASK_SPLIT');
      entries.pop();

      const tasks = entries
        .filter((json) => json.trim() !== '')
        .map((json) => JSON.parse(json));

      res.status(200).json({ message: 'Tasks loaded.', tasks: tasks });
    });
  } catch (err) {
    console.log(err);
    return res.status(401).json({ message: err.message || 'Failed to load tasks.' });
  }
});

app.post('/tasks', async (req, res) => {
  try {
    await extractAndVerifyToken(req.headers);

    const text = req.body.text;
    const title = req.body.title;

    const task = { title, text };
    const jsonTask = JSON.stringify(task);

    fs.appendFile(filePath, jsonTask + 'TASK_SPLIT', (err) => {
      if (err) {
        console.log(err);
        return res.status(500).json({ message: 'Storing the task failed.' });
      }

      res.status(201).json({ message: 'Task stored.', createdTask: task });
    });
  } catch (err) {
    console.log(err);
    return res.status(401).json({ message: 'Could not verify token.' });
  }
});

app.listen(8000);