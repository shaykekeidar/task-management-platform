import React, { useState, useEffect, useCallback } from 'react';

import './App.css';
import TaskList from './components/TaskList';
import NewTask from './components/NewTask';

function App() {
  const [tasks, setTasks] = useState([]);
  const [versions, setVersions] = useState({});

  const fetchTasks = useCallback(function () {
    fetch('/api/tasks', {
      headers: {
        'Authorization': 'Bearer abc'
      }
    })
      .then(function (response) {
        return response.json();
      })
      .then(function (jsonData) {
        setTasks(jsonData.tasks);
      });
  }, []);

  const fetchVersions = useCallback(function () {
    fetch('/api/versions')
      .then(function (response) {
        return response.json();
      })
      .then(function (jsonData) {
        setVersions(jsonData);
      });
  }, []);

  useEffect(
    function () {
      fetchTasks();
      fetchVersions();
    },
    [fetchTasks, fetchVersions]
  );

  function addTaskHandler(task) {
    fetch('/api/tasks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer abc',
      },
      body: JSON.stringify(task),
    })
      .then(function (response) {
        console.log(response);
        return response.json();
      })
      .then(function (resData) {
        console.log(resData);
      });
  }

  return (
    <div className='App'>
      <section>
        <NewTask onAddTask={addTaskHandler} />
      </section>

      <section>
        <button onClick={fetchTasks}>Fetch Tasks</button>
        <TaskList tasks={tasks} />
      </section>

      <section>
        <h3>Application Versions</h3>
        <p>Frontend: {versions.frontend || 'unknown'}</p>
        <p>Tasks: {versions.tasks || 'unknown'}</p>
        <p>Users: {versions.users || 'unknown'}</p>
        <p>Auth: {versions.auth || 'unknown'}</p>
      </section>
    </div>
  );
}

export default App;