from redis import Redis
from rq import Queue

redis_conn = Redis(host='localhost', port=6379)
face_queue = Queue('face_queue',connection=redis_conn)

