import React, { useState, useEffect, useCallback } from 'react';

import './App.css';
import TaskList from './components/TaskList';
import NewTask from './components/NewTask';

function App() {
  const [tasks, setTasks] = useState([]);
  const [completedTasks, setCompletedTasks] = useState([]);
  const [versions, setVersions] = useState({});
  const [showVersions, setShowVersions] = useState(false);
  const [showCompletedTasks, setShowCompletedTasks] = useState(false);

  const fetchTasks = useCallback(function () {
    fetch('/api/tasks', {
      headers: {
        Authorization: 'Bearer abc'
      }
    })
      .then(function (response) {
        return response.json();
      })
      .then(function (jsonData) {
        setTasks(jsonData.tasks || []);
      });
  }, []);

  const fetchCompletedTasks = useCallback(function () {
    fetch('/api/completed-tasks', {
      headers: {
        Authorization: 'Bearer abc'
      }
    })
      .then(function (response) {
        return response.json();
      })
      .then(function (jsonData) {
        setCompletedTasks(jsonData.completedTasks || []);
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
      fetchCompletedTasks();
      fetchVersions();
    },
    [fetchTasks, fetchCompletedTasks, fetchVersions]
  );

  function addTaskHandler(task) {
    fetch('/api/tasks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer abc'
      },
      body: JSON.stringify(task)
    })
      .then(function (response) {
        return response.json();
      })
      .then(function () {
        fetchTasks();
      });
  }

  function completeTaskHandler(taskId) {
    fetch(`/api/tasks/${taskId}/complete`, {
      method: 'POST',
      headers: {
        Authorization: 'Bearer abc'
      }
    })
      .then(function (response) {
        return response.json();
      })
      .then(function () {
        fetchTasks();
        fetchCompletedTasks();
      });
  }

  return (
    <div className='App'>
      <section>
        <NewTask onAddTask={addTaskHandler} />
      </section>

      <section>
        <button onClick={fetchTasks}>Fetch Tasks</button>
        <TaskList tasks={tasks} onCompleteTask={completeTaskHandler} />
      </section>

      <section>
        <button onClick={() => setShowCompletedTasks(!showCompletedTasks)}>
          {showCompletedTasks ? 'Hide Completed Tasks' : 'Show Completed Tasks'}
        </button>

        {showCompletedTasks && (
          <div>
            <h3>Completed Tasks</h3>
            <TaskList tasks={completedTasks} hideCompleteButton={true} />
          </div>
        )}
      </section>

      <section>
        <button onClick={() => setShowVersions(!showVersions)}>
          {showVersions ? 'Hide Versions' : 'Show Versions'}
        </button>

        {showVersions && (
          <div>
            <h3>Application Versions</h3>
            <p>Frontend: {versions.frontend || 'unknown'}</p>
            <p>Tasks: {versions.tasks || 'unknown'}</p>
            <p>Users: {versions.users || 'unknown'}</p>
            <p>Auth: {versions.auth || 'unknown'}</p>
          </div>
        )}
      </section>
    </div>
  );
}

export default App;