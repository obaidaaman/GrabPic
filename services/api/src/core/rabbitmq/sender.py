import pika
import os
import json
from dotenv import load_dotenv
load_dotenv()

class RabbitMQConnection:

    def __init__(self):
        url = os.getenv("RABBIT_URI")
        params = pika.URLParameters(url)

        self.connection = pika.BlockingConnection(params)
        self.channel = self.connection.channel()

    def get_channel(self):
        return self.channel

    def close(self):
        self.connection.close()


class RabbitMQPublisher:

    def __init__(self, connection):
        self.channel = connection.channel
        self.queue= "image_queue"
        self.connection = connection

        self.channel.queue_declare(queue = 'image_queue', durable=True, arguments ={'x-queue-type': 'quorum'})

    def publish_work(self, message):
        self.channel.basic_publish(
             exchange='',
        routing_key='image_queue',
        body=json.dumps(message).encode(),
        properties=pika.BasicProperties(
        delivery_mode=pika.DeliveryMode.Persistent
    )
        )
        print(f"[x] Sent {message}")
        