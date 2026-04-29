import aio_pika
import json
import os
from dotenv import load_dotenv

load_dotenv()

async def create_rabbitmq_connection():
    connection = await aio_pika.connect_robust(os.getenv("RABBIT_URI"))
    return connection

async def declare_queues(channel):
    await channel.declare_queue(
        "image_queue",
        durable=True,
        arguments={
            "x-queue-type": "quorum",
            "x-dead-letter-exchange": "",
            "x-dead-letter-routing-key": "image_queue_failed"
        }
    )
    await channel.declare_queue(
        "image_queue_retry",
        durable=True,
        arguments={
            "x-queue-type": "quorum",
            "x-message-ttl": 10000,              
            "x-dead-letter-exchange": "",
            "x-dead-letter-routing-key": "image_queue"
        }
    )
    await channel.declare_queue("image_queue_failed", durable=True)