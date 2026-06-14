import React from 'react';

import './TaskList.css';

function TaskList(props) {
  return (
    <ul>
      {props.tasks.map((task) => (
        <li key={task.id}>
          <h2>{task.title}</h2>
          <p>{task.text}</p>

          {!props.hideCompleteButton && (
            <button onClick={() => props.onCompleteTask(task.id)}>
              Complete
            </button>
          )}
        </li>
      ))}
    </ul>
  );
}

export default TaskList;