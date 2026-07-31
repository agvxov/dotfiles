#!/bin/python3

# Periodically display all forders and the number of contents in $PWD

import sys
import os
from time import sleep
import curses
import signal

def handler(signum, frame):
	curses.endwin()
	exit(0)

def main(argv):
	signal.signal(signal.SIGTERM, handler)
	stdscr = curses.initscr()
	curses.noecho()
	while True:
		stdscr.clear()
		folders = os.listdir(".")
		folders.sort()
		width = 0
		for i in folders:
			if len(i) > width:
				width = len(i)
		for i in folders:
			if not os.path.isdir(i):
				continue
			h = os.listdir(i)
			while len(i) < width:
				i += " "
			if not h:
				stdscr.addstr(i, curses.A_BOLD)
				stdscr.addstr(" :  [_]\n")
			else:
				stdscr.addstr(i, curses.A_BOLD)
				stdscr.addstr(" :  [X] (" + str(len(h)) + ")\n")
		stdscr.refresh()
		sleep(0.5)


if __name__ == '__main__':
	raise SystemExit(main(sys.argv[1:]))
