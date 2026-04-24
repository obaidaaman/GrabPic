
import pika
import time
from dotenv import load_dotenv
import os
import httpx
import json
import time
load_dotenv()
def callback(ch, method, properties, body):
    try:
    
        print(f" [x] Received {body.decode()}")
        data = json.loads(body.decode())
        
        print(" [x] Done")

        response = http_client.post(
                os.getenv("MODEL_MICRO_SERVICE_URL_FACE"),
                json={
                    "storage_paths": data["payload"]["storage_paths"],
                    "space_id": data["payload"]["space_id"]
                },
                timeout=httpx.Timeout(120.0, connect=10.0)
            )
        if response.status_code == 200:
            # l   ogger.info(f" [x] Done with Job {job_id}")
            # 4. Acknowledge ONLY on success
            ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

http_client = httpx.Client(timeout=httpx.Timeout(120.0, connect=10.0))




while True:
    try:
        connection = pika.BlockingConnection(pika.URLParameters(os.getenv("RABBIT_URI")))
        channel = connection.channel()
        channel.queue_declare(
            queue='image_queue',
            durable=True,
            arguments={
        'x-queue-type': 'quorum',
        'x-dead-letter-exchange': '',                 
        'x-dead-letter-routing-key': 'image_queue_failed'  
    })
        channel.queue_declare(queue='image_queue_failed', durable=True)
        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(queue='image_queue', on_message_callback=callback)
        print("Connected. Waiting for messages...")
        channel.start_consuming()
    except pika.exceptions.AMQPConnectionError as e:
        print(f"Connection lost: {e}. Retrying in 5 seconds...")
        time.sleep(5)
    except KeyboardInterrupt:
        break