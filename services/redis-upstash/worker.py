import asyncio
import json
import os
from redis_asyn_conn import redis_conn
from redis_asyn_conn import httpx_client
QUEUE = "face_jobs"

async def fetch_job():
    job = await redis_conn.rpop(QUEUE)
    return job

async def process_job(worker_id):
    print(f"Worker-{worker_id} started...")

    while True:
        job = await fetch_job()

        if not job:
            await asyncio.sleep(1)   # 🔑 important: prevent hot loop
            continue

        job = json.loads(job)

        job_id = job["job_id"]
        payload = job["payload"]

        try:
            await redis_conn.set(f"job_status:{job_id}", "processing")

            print(f"[Worker-{worker_id}] Processing:", payload)

            # call httpx service here
            response = await httpx_client.post(os.getenv("MODEL_MICRO_SERVICE_URL_FACE"), json={"storage_paths": payload["storage_paths"], "space_id": payload["space_id"]},timeout=30)
            
            await redis_conn.set(f"job_status:{job_id}", "done")

        except Exception as e:
            await redis_conn.set(f"job_status:{job_id}", "failed")
            print(f"[Worker-{worker_id}] Error:", e)
async def main():

    WORKER_COUNT = 3   

    tasks = [
        asyncio.create_task(process_job(i))
        for i in range(WORKER_COUNT)
    ]

    await asyncio.gather(*tasks)

asyncio.run(main())