const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');
const http = require('http');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

// Read environment variables
const regionLocal = process.env.REGION_LOCAL || 'who knows where';
const regionRemote = process.env.REGION_REMOTE || 'who knows where';
const dbUser = process.env.DB_USER;
const dbPassword = process.env.DB_PASSWORD;
const dbHostLocal = process.env.DB_HOST_LOCAL;
const dbHostRemote = process.env.DB_HOST_REMOTE;
const dbPort = process.env.DB_PORT;
const dbName = process.env.DB_NAME;
const svcIpRemote = process.env.SVC_IP_REMOTE;
const sslCert = process.env.DB_CA_CERT;

// Read the SSL certificate
// const sslCert = fs.readFileSync('ca-certificate.crt');

// Create connection pools for both databases with a 1-second timeout
const poolLocal = new Pool({
  connectionString: `postgresql://${dbUser}:${dbPassword}@${dbHostLocal}:${dbPort}/${dbName}`,
  ssl: { ca: sslCert },
  idleTimeoutMillis: 1000,
  connectionTimeoutMillis: 1000, // 1-second connection timeout
});

const poolRemote = new Pool({
  connectionString: `postgresql://${dbUser}:${dbPassword}@${dbHostRemote}:${dbPort}/${dbName}`,
  ssl: { ca: sslCert },
  idleTimeoutMillis: 1000,
  connectionTimeoutMillis: 1000, // 1-second connection timeout
});

// Serve static files (e.g., background image and font)
app.use('/static', express.static(path.join(__dirname, 'static')));

// Function to check service availability via /health path
const checkServiceHealth = (ip) => {
  return new Promise((resolve) => {
    const options = {
      hostname: ip,
      port: 80,
      path: '/health',
      method: 'GET',
      timeout: 1000,
    };

    const req = http.request(options, (res) => {
      if (res.statusCode === 200) {
        resolve('up');
      } else {
        resolve('down');
      }
    });

    req.on('error', () => {
      resolve('down');
    });

    req.on('timeout', () => {
      req.destroy();
      resolve('down');
    });

    req.end();
  });
};

// Health status object to track the state
let healthStatus = {
  localDbHealthy: true,
};

app.get('/health', async (req, res) => {
  try {
    await poolLocal.query('SELECT 1');
    res.status(200).send('Healthy');
  } catch (error) {
    console.error(`Health check failed: ${error.message}`);
    res.status(500).send('Non-healthy: Local database connection failed.');
  }
});

// Dynamic route to display the status page
app.get('/', async (req, res) => {
  let localDbStatus = 'up';
  let remoteDbStatus = 'up';
  let remoteSvcStatus = 'up';

  try {
    await poolLocal.query('SELECT 1');
  } catch (error) {
    console.error(`Error connecting to Local database: ${error.message}`);
    localDbStatus = 'down';
  }

  try {
    await poolRemote.query('SELECT 1');
  } catch (error) {
    console.error(`Error connecting to Remote database: ${error.message}`);
    remoteDbStatus = 'down';
  }

  try {
    const serviceStatus = await checkServiceHealth(svcIpRemote);
    remoteSvcStatus = serviceStatus === 'up' ? 'up' : 'down';
  } catch (error) {
    console.error(`Error checking remote service health: ${error.message}`);
    remoteSvcStatus = 'down';
  }

  const statusMessages = {
    localDb: localDbStatus === 'up' ? `LOCAL DATABASE IN ${regionLocal} IS RIDING THE WAVES` : `LOCAL DATABASE IN ${regionLocal} HAS RUN AGROUND`,
    remoteDb: remoteDbStatus === 'up' ? `REMOTE DATABASE IN ${regionRemote} IS AFLOAT` : `REMOTE DATABASE IN ${regionRemote} IS LOST AT SEA`,
    remoteSvc: remoteSvcStatus === 'up' ? `REMOTE SERVICE IN ${regionRemote} IS SAILING` : `REMOTE SERVICE IN ${regionRemote} IS A SHIPWRECK`,
  };

  const bg1Source = (() => {
    if (localDbStatus === 'up' && remoteSvcStatus === 'up' && remoteDbStatus === 'up') {
      return '/static/scrollable-background-1-all-up.svg';
    } else if (localDbStatus === 'down' && remoteSvcStatus === 'up' && remoteDbStatus === 'up') {
      return '/static/scrollable-background-1-down-up-up.svg';
    } else if (localDbStatus === 'up' && remoteSvcStatus === 'down' && remoteDbStatus === 'down') {
      return '/static/scrollable-background-1-up-down-down.svg';
    } else if (localDbStatus === 'up' && remoteSvcStatus === 'down' && remoteDbStatus === 'up') {
      return '/static/scrollable-background-1-up-down-up.svg';
    } else if (localDbStatus === 'up' && remoteSvcStatus === 'up' && remoteDbStatus === 'down') {
      return '/static/scrollable-background-1-up-up-down.svg';      
    } else if (localDbStatus === 'down' && remoteSvcStatus === 'down' && remoteDbStatus === 'down') {
      return '/static/scrollable-background-1-down-down-down.svg';      
    } else {
      return '/static/scrollable-background-1-mixed-status.svg'; // Default for mixed or unhandled cases
    }
  })();

  res.send(`
    <html>
      <head>
        <link href="https://fonts.googleapis.com/css2?family=Epilogue:wght@700&display=swap" rel="stylesheet">
        <style>
          :root {
            --body-bg-color: white; /* Default body background color */
          }
    
  body {
    margin: 0;
    padding: 0;
    font-family: 'Epilogue', Arial, sans-serif;
    color: white;
    text-transform: uppercase;
    overflow-x: hidden; /* Prevent horizontal scroll */
    background: linear-gradient(rgb(0, 105, 255) 0%, rgb(0, 191, 255) 8.19%, rgb(181, 246, 255) 16.83%, rgb(255, 255, 255) 31.05%, rgb(0, 191, 255) 49.78%, rgb(0, 105, 255) 66.46%, rgb(0, 12, 42) 78.75%);
    min-height: 300%;
    }

    
          .scrollable-bg-1 {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: auto; /* Adjust to content */
            min-height: 300%;
            background: url('${bg1Source}') no-repeat center top;
            background-size: cover;
            z-index: -2;
          }
          
          .scrollable-bg-2 {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: auto; /* Adjust to content */
            min-height: 300%;
            background: url('/static/scrollable-background-2.svg') no-repeat center top;
            background-size: cover;
            z-index: -3;
          }
    
          .main-bg {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: url('/static/background.svg') no-repeat center center fixed;
            background-size: cover;
            z-index: 0;
          }
    
          .content {
            position: relative;
            z-index: -1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            text-align: center;
          }
    
          .proud-text {
            font-size: 2em;
            color: black;
            font-weight: bold;
            margin-bottom: 20px;
          }
    
          .region {
            font-size: 3em;
            color: black;
            font-weight: bold;
          }
    
          .statuses {
            margin-top: 30px;
            text-align: center;
          }
    
          .statuses p {
            font-size: 1.5em;
            margin: 10px 0;
          }
    
          .up {
            color: #50C878;
          }
    
          .down {
            color: #FF6347;
          }
        </style>
        <script>
          // JavaScript for dynamic scroll effect
          window.addEventListener('scroll', () => {
            const scrollPosition = window.scrollY;
            const bg1 = document.querySelector('.scrollable-bg-1');
            const bg2 = document.querySelector('.scrollable-bg-2');
            
            // Adjust scroll multipliers for speed control
            bg1.style.backgroundPositionY = \`\${scrollPosition * 0.5}px\`; // Slower scroll
            bg2.style.backgroundPositionY = \`\${scrollPosition * 0.5}px\`; // Faster scroll
          });
        </script>
      </head>
      <body>
        <div class="scrollable-bg-1"></div>
        <div class="scrollable-bg-2"></div>
        <div class="main-bg"></div>
        <div class="content">
          <div class="proud-text">
            YOUR REQUEST IS HANDLED BY DIGITALOCEAN FROM
            <div class="region">
              ${regionLocal}
            </div>
          </div>
          <div class="statuses">
            <p class="${localDbStatus === 'up' ? 'up' : 'down'}">${statusMessages.localDb}</p>
            <p class="${remoteDbStatus === 'up' ? 'up' : 'down'}">${statusMessages.remoteDb}</p>
            <p class="${remoteSvcStatus === 'up' ? 'up' : 'down'}">${statusMessages.remoteSvc}</p>
          </div>
        </div>
      </body>
    </html>
    `);
});



// Start the web server
app.listen(port, () => {
  console.log(`Web server running on port ${port}`);
});
