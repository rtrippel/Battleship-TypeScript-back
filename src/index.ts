import "reflect-metadata";
import express from "express";
import { createServer } from "http";
import { Server } from "ws";
import { AppDataSource } from "./data-source";
import messageRoutes from "./routes/messageRoutes";
import { Message } from "./entities/Message";

const app = express();
const server = createServer(app);
const wss = new Server({ server });

app.use(express.json());
app.use("/", messageRoutes);

wss.on("connection", (ws) => {
    ws.on("message", async (message) => {
        const messageRepository = AppDataSource.getRepository(Message);
        const newMessage = messageRepository.create({ content: message.toString() });
        await messageRepository.save(newMessage);
        ws.send(`Message saved: ${newMessage.content}`);
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
