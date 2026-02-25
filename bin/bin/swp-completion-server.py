#!/usr/bin/env python3

import os
import socket
import csv
from time import sleep
from sys import exit, argv
import multiprocessing as mp

# NOTE: the exit code might be useless because i think jobs are auto killed

query = ""
parent_pid = None
input_file = None
socket_path = "/tmp/completion-server-{0}.sock"

MAX_RESULTS = 200

# --- Cli
#pragma region
if len(argv) != 3:
	print(f"Usage: {argv[0]} <pid> <file>")
	exit(1)

parent_pid = int(argv[1])
input_file = argv[2]

socket_path = socket_path.format(parent_pid)

# pedantic flush
def print(*args, **kwargs):
	import builtins
	builtins.print(*args, flush=True, **kwargs)
#pragma endregion

# --- Completion Generation
#pragma region
def get_words(input_file : str) -> [str]:
	NAME_INDEX	  = (1) - 1
	TYPE_INDEX	  = (4) - 1
	# Ctags field type filter
	# C++ ["variable", "function", "prototype", "typedef",
	#      "struct", "class", "enum (value)", "union",
	#      "enum", "macro", "extern variable"]
	targets = "vfptsceugdx"
	# ["local", "member", "parameter"]
	targets += "lmz"
	# Ctags noise entry filter
	def do_ignore(row):
		IGNORE_IF_BEGINS_WITH = '!_'
		if row[0][0] in IGNORE_IF_BEGINS_WITH:
			return True
		if row[NAME_INDEX].find('operator') != -1:
			return True
		return False

	r = set()
	with open(input_file) as f:
		csv_reader = csv.reader(f, delimiter='\t')
		for row in csv_reader:
			if do_ignore(row): continue
			try:
				if row[TYPE_INDEX] in targets:
					r.add(row[NAME_INDEX])
			except: print("Suspicious ctags entry without a type: ", row)
	return r

def filter_words(query: str, words: [str]) -> str:
	def filter_words_simple(query, words):
		r = {w for w in words if w.startswith(query)}
		return r
	def filter_words_case_insensitive(query, words):
		query = query.lower()
		r = [w for w in words if w.lower().startswith(query)]
		return r
	def filter_words_smart(query, words):
		if any(c.isupper() for c in query): return filter_words_simple(query, words)
		else: return filter_words_case_insensitive(query, words)
	if query != '':
		# XXX there should be a config to set this
		words = filter_words_smart(query, words)
	words = list(dict.fromkeys(words)) # dedup
	return " ".join(words[:MAX_RESULTS])

#pragma endregion

# --- Server
#pragma region
class NullProcess:
	def is_alive(self): return False

conn = None

manager = mp.Manager()
shared_state = manager.dict()
shared_state["words"]		   = None
shared_state["filtered_words"] = None
word_process   = NullProcess()
filter_process = NullProcess()

server_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

buffer = b''

def do_abort(process):
	if process.is_alive():
		process.terminate()
		process.join()

def bg_filter_words():
	global filter_process
	def mp_filter_words(shared_state : dict, query : str) -> None:
		if shared_state["words"] == None: return
		filtered_words = filter_words(query, shared_state["words"])
		shared_state["filtered_words"] = filtered_words

	filter_process = mp.Process(
		target=mp_filter_words,
		args=(shared_state, query)
	)
	filter_process.start()

def bg_process_words():
	global word_process
	def mp_get_words(shared_state : dict, input_file : str) -> None:
		words = get_words(input_file)
		shared_state["words"] = words

	word_process = mp.Process(
		target=mp_get_words,
		args=(shared_state, input_file)
	)
	word_process.start()

def clean_up() -> None:
	do_abort(word_process)
	do_abort(filter_process)
	# Clean up any previous socket file
	if os.path.exists(socket_path):
		os.remove(socket_path)

def establish_connection() -> int:
	global conn
	try:
		conn, _ = server_socket.accept()
		print("Client connected.")
		conn.setblocking(False)
	except BlockingIOError: return 1
	return 0

def send(msg : str) -> None:
	conn.sendall(msg.encode())

try:
	clean_up()

	server_socket.bind(socket_path)
	server_socket.listen(1)
	server_socket.setblocking(False)
	print(f"Server listening on {socket_path}")

	bg_process_words()

	while True:
		if shared_state["words"] is None:
			if not word_process.is_alive():
				bg_process_words()
		elif shared_state["filtered_words"] is None and not filter_process.is_alive():
			bg_filter_words()

		sleep(0.01) # 10 ms

		if not os.path.exists("/proc/" + str(parent_pid)):
			break

		if conn is None:
			if establish_connection(): continue

		try:
			data = conn.recv(4096)

			if not data:
				print("Client disconnected.")
				conn.close()
				conn = None
				continue

			lines = []
			buffer += data
			while b'\n' in buffer:
				line, buffer = buffer.split(b'\n', 1)
				line = line.decode('utf-8').rstrip('\r')
				if not line: continue
				else: lines.append(line)
		except (socket.error, BlockingIOError): continue

		for line in lines:
			prefix, arg = line[0], line[1:].strip()

			# Query
			if '?' == prefix:
				if query != arg:
					print("# Query: update filter string, '{0}'".format(arg))
					query = arg
					do_abort(filter_process)
					shared_state["filtered_words"] = None
				else:
					print("# Query: nothing to update, '{0}' == '{1}'".format(query, arg))
				continue

			# Bump
			if '<' == prefix:
				print("# Bump: resource changed")
				do_abort(filter_process)
				do_abort(word_process)
				shared_state["words"] = None
				shared_state["filtered_words"] = None
				continue

			# Poll
			if '=' == prefix:
				print("# Poll: decide to pass or push")
				if shared_state["filtered_words"] is not None:
					#print(shared_state["filtered_words"])
					send("> " + shared_state["filtered_words"] + "\n")
					print("## Pushed: {0}...".format(shared_state["filtered_words"][:15]))
				else:
					send("- \n")
					print("## Pass: not ready yet")
				continue

			# Debug
			if '*' == prefix:
				print("# DEBUG: dump all")
				conn.setblocking(True)
				send("> " + " ".join(shared_state["words"]) + '\n')
				conn.setblocking(False)
				continue

			if '#' == prefix:
				print("# DEBUG: dump filtered")
				send("> " + shared_state["filtered_words"] + '\n')
				continue

			# N/A
			print("# Unknown message '{0}', ignore".format(str(line)))

except KeyboardInterrupt:
	print("Server shutting down.")
finally:
	server_socket.close()
	clean_up()
#pragma endregion
