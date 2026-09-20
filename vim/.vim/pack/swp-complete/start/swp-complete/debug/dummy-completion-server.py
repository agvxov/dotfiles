#!/bin/python3
import socket
import os
import random
import signal
from sys import exit

# Path for the Unix domain socket
SOCKET_PATH = '/tmp/completion_server.sock'

# Fixed word list
WORDS = [
	'apple', 'application', 'banana', 'band', 'bandana',
	'candy', 'dog', 'cat', 'caterpillar', 'dogma', 'anchor', 'antagonist'
]

# Current filter string (last query received)
filter_str = ''

def cleanup_and_exit(signum, frame):
	try: os.unlink(SOCKET_PATH)
	except FileNotFoundError: pass
	print(f"Completion server shutting down.")
	exit(0)

signal.signal(signal.SIGINT, cleanup_and_exit)
signal.signal(signal.SIGTERM, cleanup_and_exit)

# Remove existing socket file if present
if os.path.exists(SOCKET_PATH):
	os.unlink(SOCKET_PATH)

server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
server.bind(SOCKET_PATH)
server.listen(1)
print(f"Completion server listening on {SOCKET_PATH}")

try:
	while True:
		conn, _ = server.accept()
		print("Client connected.")
		# Wrap socket in file-like objects for reading/writing text lines
		reader = conn.makefile('r')
		writer = conn.makefile('w')

		try:
			for line in reader:
				line = line.rstrip('\n')
				if not line:
					continue
				prefix, *args = line.split(' ', 1)

				if prefix == '<':
					print("# Bump: resource changed, no response")
					continue

				elif prefix == '?':
					print("# Query: update filter string, no response")
					filter_str = args[0] if args else ''
					continue

				elif prefix == '=':
					print("# Poll: decide to pass or push")
					do_push = random.choice([True, False])
					if not do_push:
						print("## Send pass")
						writer.write('-\n')
						writer.flush()
					else:
						print("## Find matching words")
						matches = [w for w in WORDS if filter_str in w]
						response = '> ' + ' '.join(matches) + '\n'
						writer.write(response)
						writer.flush()

				else:
					print("# Unknown prefix, ignore")
					continue

		except Exception as e:
			print(f"Connection error: {e}")
		finally:
			reader.close()
			writer.close()
			conn.close()
			print("Client disconnected.")

finally:
	cleanup_and_exit(None, None)
