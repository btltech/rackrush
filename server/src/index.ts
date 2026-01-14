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
        allowEIO3: true,  // Enable compatibility with older Socket.IO clients (v2/v3)
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

    // B3 Fix: Graceful shutdown
    const shutdown = () => {
        console.log('\n🛑 Shutting down gracefully...');
        io.close(() => {
            console.log('   Socket.IO closed');
            httpServer.close(() => {
                console.log('   HTTP server closed');
                process.exit(0);
            });
        });
        // Force exit after timeout
        setTimeout(() => {
            console.log('   Force exit after timeout');
            process.exit(1);
        }, 5000);
    };

    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);
}

main().catch(console.error);
