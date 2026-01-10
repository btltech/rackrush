import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { config } from './config.js';
import { dictionary } from './dictionary/Dictionary.js';
import { setupHandlers } from './socket/handlers.js';

async function main() {
    // Load dictionary
    console.log('Loading dictionary...');
    await dictionary.load();

    // Create Express app
    const app = express();

    // Health check endpoint (for Railway)
    app.get('/health', (req, res) => {
        res.json({ status: 'ok', timestamp: Date.now() });
    });

    // Create HTTP server
    const httpServer = createServer(app);

    // Create Socket.IO server
    const io = new Server(httpServer, {
        cors: {
            origin: '*',  // Allow all origins for mobile apps
            methods: ['GET', 'POST'],
        },
        pingInterval: config.pingInterval,
        pingTimeout: config.pingTimeout,
    });

    // Setup WebSocket handlers
    setupHandlers(io);

    // Start server
    httpServer.listen(config.port, () => {
        console.log(`🎮 RackRush server running on port ${config.port}`);
        console.log(`   Health check: http://localhost:${config.port}/health`);
    });
}

main().catch(console.error);
