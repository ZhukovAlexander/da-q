#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <zhukovaa90@gmail.com> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return Alexander Zhukov
# ----------------------------------------------------------------------------
#

import json


class Queue:

    def __init__(self, connection, capacity):
        self.connection = connection
        self.capacity = capacity

    async def _setup(self):
        with open('install.sql', 'r') as script:
            await self.connection.execute(script.read())
            await self.connection.execute('SELECT create_queue($1)', self.capacity)

    @classmethod
    async def create(cls, connection, capacity):
        queue = cls(connection=connection, capacity=capacity)
        queue._setup()
        return queue

    async def put(self, item: dict):
        return await self.connection.execute('SELECT queue_put($1);', json.dumps(item))

    async def get(self):
        return await self.connection.execute('SELECT queue_get();')


async def create_queue(connection, capacity):
    return await Queue.create(connection, capacity)
