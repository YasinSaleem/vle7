const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 8080;

// Read version from package.json
const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const version = packageJson.version;

// Get environment variables
const color = process.env.COLOR || 'blue';
const buildNumber = process.env.BUILD_NUMBER || 'dev';

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>MyApp - ${color.toUpperCase()}</title>
            <style>
                body { 
                    font-family: Arial, sans-serif; 
                    text-align: center; 
                    margin: 50px;
                    background-color: ${color === 'blue' ? '#e3f2fd' : '#e8f5e8'};
                }
                .container { 
                    max-width: 600px; 
                    margin: 0 auto; 
                    padding: 20px;
                    background: white;
                    border-radius: 10px;
                    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                }
                .color-badge { 
                    display: inline-block;
                    padding: 10px 20px;
                    color: white;
                    border-radius: 5px;
                    font-weight: bold;
                    background-color: ${color};
                    margin: 10px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 MyApp Dashboard</h1>
                <div class="color-badge">${color.toUpperCase()}</div>
                <p><strong>Version:</strong> ${version}</p>
                <p><strong>Build Number:</strong> ${buildNumber}</p>
                <p><strong>Environment:</strong> ${color} deployment</p>
                <p><strong>Server Time:</strong> ${new Date().toISOString()}</p>
            </div>
        </body>
        </html>
    `);
});

app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        version: version,
        color: color,
        buildNumber: buildNumber,
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`🚀 MyApp (${color}) running on port ${PORT}`);
    console.log(`📦 Version: ${version}`);
    console.log(`🔨 Build: ${buildNumber}`);
});