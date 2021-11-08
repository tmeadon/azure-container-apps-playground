import logo from './logo.svg';
import './App.css';
import React, { useState, useEffect } from 'react';

const daprPort = process.env.DAPR_HTTP_PORT || 3500;
const daprSidecar = `http://localhost:${daprPort}`

const getData = async function () {
  let response = await fetch(`${daprSidecar}/v1.0/invoke/backend/method/`);
  return response.json();
}

function App() {
  const [data, setData] = useState([]);

  useEffect(() => {
    (async function () {
      let data = await getData();
      setData(data);
    })();
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Azure Container Apps playground!
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
        <p>
          {data}
        </p>
      </header>
    </div>
  );
}

export default App;
