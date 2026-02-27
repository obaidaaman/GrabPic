from upstash_redis.asyncio import Redis
import os
from dotenv import load_dotenv
import httpx
load_dotenv()

httpx_client = httpx.AsyncClient()

redis_conn = Redis(url=os.getenv("UPSTASH_REDIS_URL"), token=os.getenv("UPSTASH_REDIS_TOKEN"))

