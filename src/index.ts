import "reflect-metadata";
import express from "express";
import https from "https";
import { Server, WebSocket } from "ws";
import cors from "cors";
import { AppDataSource } from "./data-source";
import messageRoutes from "./routes/messageRoutes";
import { Message } from "./entities/Message";
import dotenv from 'dotenv';
import fs from 'fs';

dotenv.config();

const privateKeyPath = process.env.PRIVATE_KEY_PATH;
const certificatePath = process.env.CERTIFICATE_PATH;

if (!privateKeyPath || !certificatePath) {
    console.error('Failed to find environment variables PRIVATE_KEY_PATH or CERTIFICATE_PATH.');
    process.exit(1);
}

let privateKey;
let certificate;

try {
    privateKey = fs.readFileSync(privateKeyPath, 'utf8');
    certificate = fs.readFileSync(certificatePath, 'utf8');
} catch (err) {
    if (err instanceof Error) {
        console.error('Error reading key or certificate:', err.message);
    } else {
        console.error('Unknown error:', err);
    }
    process.exit(1);
}

const credentials = {
    key: privateKey,
    cert: certificate,
};

const app = express();
const server = https.createServer(credentials, app);
const wss = new Server({ server });

app.use(cors());
app.use(express.json());
app.use("/", messageRoutes);

wss.on("connection", (ws) => {
    ws.on("message", async (message) => {
        const messageRepository = AppDataSource.getRepository(Message);
        const newMessage = messageRepository.create({ content: message.toString() });
        await messageRepository.save(newMessage);

        const newMessageData = JSON.stringify(newMessage);
        wss.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(newMessageData);
            }
        });
    });

    ws.send("Connected to WebSocket server");
});

const start = async () => {
    try {
        await AppDataSource.initialize();
        console.log("Data Source has been initialized!");

        server.listen(3000, () => {
            console.log("Server is running on port 3000");
        });
    } catch (err) {
        console.error("Error during Data Source initialization:", err);
    }
};

start();
