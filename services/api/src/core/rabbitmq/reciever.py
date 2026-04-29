
import pika
import time
from dotenv import load_dotenv
import os
import httpx
import json
import time
load_dotenv()
# def callback(ch, method, properties, body):
#     try:
    
#         print(f" [x] Received {body.decode()}")
#         data = json.loads(body.decode())
        
#         print(" [x] Done")

#         response = http_client.post(
#                 os.getenv("MODEL_MICRO_SERVICE_URL_FACE"),
#                 json={
#                     "storage_paths": data["payload"]["storage_paths"],
#                     "space_id": data["payload"]["space_id"]
#                 },
#                 timeout=httpx.Timeout(120.0, connect=10.0)
#             )
#         if response.status_code == 200:
#             # l   ogger.info(f" [x] Done with Job {job_id}")
#             # 4. Acknowledge ONLY on success
#             ch.basic_ack(delivery_tag=method.delivery_tag)
#     except Exception as e:
#         ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

# http_client = httpx.Client(timeout=httpx.Timeout(120.0, connect=10.0))




# while True:
#     try:
#         connection = pika.BlockingConnection(pika.URLParameters(os.getenv("RABBIT_URI")))
#         channel = connection.channel()
#         channel.queue_declare(
#             queue='image_queue',
#             durable=True,
#             arguments={
#         'x-queue-type': 'quorum',
#         'x-dead-letter-exchange': '',                 
#         'x-dead-letter-routing-key': 'image_queue_failed'  
#     })
#         channel.queue_declare(queue='image_queue_failed', durable=True)
#         channel.basic_qos(prefetch_count=1)
#         channel.basic_consume(queue='image_queue', on_message_callback=callback)
#         print("Connected. Waiting for messages...")
#         channel.start_consuming()
#     except pika.exceptions.AMQPConnectionError as e:
#         print(f"Connection lost: {e}. Retrying in 5 seconds...")
#         time.sleep(5)
#     except KeyboardInterrupt:
#         break




# New code structure for handling batches of images 

MAX_RETRIES = 3
RETRY_DELAY_MS = 10000

http_client = httpx.Client(timeout=httpx.Timeout(120.0, connect=10.0))


def get_retry_count(properties):
    if properties.headers and "x-retry-count" in properties.headers:
        return properties.headers["x-retry-count"]
    return 0


def retry_message(ch, method, properties, body, retry_count):
    new_headers = dict(properties.headers or {})
    new_headers["x-retry-count"] = retry_count + 1

    ch.basic_publish(
        exchange="",
        routing_key="image_queue_retry",
        body=body,
        properties=pika.BasicProperties(
            delivery_mode=2,
            headers=new_headers
        )
    )
    ch.basic_ack(delivery_tag=method.delivery_tag)
    print(f"[↻] Retry attempt {retry_count + 1}/{MAX_RETRIES} queued.")


def callback(ch, method, properties, body):
    retry_count = get_retry_count(properties)

    try:
        data = json.loads(body.decode())
        print(f"[x] Received job {data.get('job_id')} (attempt {retry_count + 1})")

        response = http_client.post(
            os.getenv("MODEL_MICRO_SERVICE_URL_FACE"),
            json={
                "storage_paths": data["payload"]["storage_paths"],
                "space_id": data["payload"]["space_id"]
            },
            timeout=httpx.Timeout(120.0, connect=10.0)
        )

        if response.status_code == 200:
            ch.basic_ack(delivery_tag=method.delivery_tag)
            print(f"[✓] Job {data.get('job_id')} done.")
        else:
            raise Exception(f"Face service returned {response.status_code}")

    except Exception as e:
        print(f"[!] Error: {e}")
        if retry_count < MAX_RETRIES:
            retry_message(ch, method, properties, body, retry_count)
        else:
            print(f"[x] Max retries reached. Sending to DLQ.")
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


def declare_queues(channel):
    channel.queue_declare(
        queue="image_queue",
        durable=True,
        arguments={
            "x-queue-type": "quorum",
            "x-dead-letter-exchange": "",
            "x-dead-letter-routing-key": "image_queue_failed"
        }
    )
    channel.queue_declare(
        queue="image_queue_retry",
        durable=True,
        arguments={
            "x-queue-type": "quorum",
            "x-message-ttl": RETRY_DELAY_MS,
            "x-dead-letter-exchange": "",
            "x-dead-letter-routing-key": "image_queue"
        }
    )
    channel.queue_declare(queue="image_queue_failed", durable=True)


while True:
    try:
        connection = pika.BlockingConnection(pika.URLParameters(os.getenv("RABBIT_URI")))
        channel = connection.channel()
        declare_queues(channel)
        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(queue="image_queue", on_message_callback=callback)
        print("[*] Waiting for messages. CTRL+C to exit.")
        channel.start_consuming()

    except pika.exceptions.AMQPConnectionError as e:
        print(f"[!] Connection lost: {e}. Reconnecting in 5s...")
        time.sleep(5)

    except KeyboardInterrupt:
        print("[x] Shutting down consumer.")
        break