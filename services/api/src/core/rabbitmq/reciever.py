#!/usr/bin/env python
import pika
import time
from dotenv import load_dotenv
import os
load_dotenv()
connection = pika.BlockingConnection(
    pika.URLParameters('amqps://qjwtdcql:6mdN39bD3J-oYd20njHK6egPJ7BxvZN9@jaragua.lmq.cloudamqp.com/qjwtdcql'))
channel = connection.channel()

channel.queue_declare(queue='task_queue', durable=True, arguments={'x-queue-type': 'quorum'})
print(' [*] Waiting for messages. To exit press CTRL+C')


def callback(ch, method, properties, body):
    print(f" [x] Received {body.decode()}")
    time.sleep(body.count(b'.'))
    print(" [x] Done")
    ch.basic_ack(delivery_tag=method.delivery_tag)


channel.basic_qos(prefetch_count=1)
channel.basic_consume(queue='task_queue', on_message_callback=callback)

channel.start_consuming()