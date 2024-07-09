import { Router } from "express";
import { AppDataSource } from "../data-source";
import { Message } from "../entities/Message";

const router = Router();

router.get("/messages", async (_req, res) => {
    const messageRepository = AppDataSource.getRepository(Message);
    const messages = await messageRepository.find();
    res.send(messages);
});

export default router;
