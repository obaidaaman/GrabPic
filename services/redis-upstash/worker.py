# import asyncio
# import json
# import os
# from redis_asyn_conn import redis_conn
# from redis_asyn_conn import httpx_client
# from dotenv import load_dotenv
# load_dotenv()
# QUEUE = "face_jobs"

# async def fetch_job():
#     result = await redis_conn.blpop(QUEUE, timeout=5)
#     if result is None:
#         return None
#     _, job_data = result
#     return job_data

# async def process_job(worker_id):
#     """
#     Worker function that continuously fetches and processes jobs from the Redis queue.
#     Args:
#     worker_id: An identifier for the worker (useful for logging).
    
#     Status Updates:
# - "queued": Job is waiting in the queue.
# - "processing": Job is currently being processed by a worker.
# - "completed": Job has been successfully processed.
# - "failed": An error occurred during processing.
#     """
#     print(f"Worker-{worker_id} started...")

#     while True:
#         job = await fetch_job()


#         if not job:
             
#             continue

#         job = json.loads(job)

#         job_id = job["job_id"]
#         payload = job["payload"]

#         try:
#             await redis_conn.set(f"job_status:{job_id}", "processing")

#             print(f"[Worker-{worker_id}] Processing:", payload)

          
#             response = await httpx_client.post(os.getenv("MODEL_MICRO_SERVICE_URL_FACE"), json={"storage_paths": payload["storage_paths"], "space_id": payload["space_id"]},timeout=120)
#             if response.status_code !=200:
#                 await redis_conn.set(f"job_status:{job_id}", "failed")
#                 raise Exception(f"Failed to process job {job_id}: {response.text}")
                
#             await redis_conn.set(f"job_status:{job_id}", "completed")


#         except Exception as e:
#             await redis_conn.set(f"job_status:{job_id}", "failed")
#             print(f"[Worker-{worker_id}] Error:", e)
# async def main():

#     WORKER_COUNT = 3   

#     tasks = [
#         asyncio.create_task(process_job(i))
#         for i in range(WORKER_COUNT)
#     ]

#     await asyncio.gather(*tasks)

# asyncio.run(main())







import asyncio
import json
import os
from redis_asyn_conn import redis_conn, httpx_client
from dotenv import load_dotenv
import httpx
load_dotenv()

QUEUE = "face_jobs"


async def fetch_job():
    return await redis_conn.rpop(QUEUE)


async def process_job(worker_id):
    print(f"Worker-{worker_id} started...")

    while True:
        job = await fetch_job()

        if not job:
            print(f"[Worker-{worker_id}] No job, sleeping...")
            await asyncio.sleep(0.5)
            continue

        job = json.loads(job)
        job_id = job["job_id"]
        payload = job["payload"]

        try:
            await redis_conn.set(f"job_status:{job_id}", "processing")
            print(f"[Worker-{worker_id}] Processing job {job_id}")

            response = await httpx_client.post(
                os.getenv("MODEL_MICRO_SERVICE_URL_FACE"),
                json={
                    "storage_paths": payload["storage_paths"],
                    "space_id": payload["space_id"]
                },
                timeout=httpx.Timeout(120.0, connect=10.0)
            )

            if response.status_code != 200:
                raise Exception(f"{response.status_code}: {response.text}")

            await redis_conn.set(f"job_status:{job_id}", "completed")
            print(f"[Worker-{worker_id}] Completed {job_id}")

        except Exception as e:
            await redis_conn.set(f"job_status:{job_id}", "failed")
            print(f"[Worker-{worker_id}] Failed {job_id}: {e}")

            
async def main():
    WORKER_COUNT = 3

    tasks = [
        asyncio.create_task(process_job(i))
        for i in range(WORKER_COUNT)
    ]

    await asyncio.gather(*tasks,return_exceptions=True)


asyncio.run(main())