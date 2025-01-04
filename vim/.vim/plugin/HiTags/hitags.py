#!/bin/env python3

import sys
import re
import csv
from subprocess import run, PIPE

input_filename = ''
preprocessor='clang -fdirectives-only -E {input_} -o {output}'
tags_filename = 'vim.tags'
polution_directory = './'
action = 'hi'

# --- Console
#pragma region
def print2(s): print(s, file=sys.stderr)

def usage(name : str, exit_code : int):
	print2("Usage: {0} <options> <verb>".format(name))
	print2("\t-h")
	print2("\t-i <file> : input")
	print2("\t-p <cmd>  : preprocessor (e.g.: 'clang -fdirectives-only -E {input_} -o {output}')")
	print2("\t-t <path> : polution directory")
	print2("\t---")
	print2("\thi")
	print2("\tsig")
	exit(exit_code)

def opts(args):
	global input_filename, preprocessor, polution_directory, action

	if "--help" in args: usage(args[0], 1)

	try:
		for idx, arg in enumerate(args[1:]): # this is terrible
			if arg in ("-h", "--help"): usage(args[0], 0)
			elif arg == "-i":  input_filename = args[idx + 2]
			elif arg == "-p":  preprocessor = args[idx + 2]
			elif arg == "-t":  polution_directory = args[idx + 2]
			elif arg == "hi":  action = "hi"
			elif arg == "sig": action = "sig"
	except IndexError: usage(args[0], 1)

	if input_filename == '': usage(args[0], 1)
#pragma endregion

# --- Highlighting
#pragma region
def hi(group : str) -> str: return 'syn keyword\t\tHiTag{group} {{kw}}'.format(group=group)

targets = [
	{
		'type': 'v',
		'out': hi('Special')
	},
	{
		'type': 'f',
		'out': hi('Function')
	},
	{
		'type': 'p',
		'out': hi('Function')
	},
	{
		'type': 't',
		'out': hi('Type')
	},
	{
		'type': 's',
		'out': hi('Type')
	},
	{
		'type': 'c',
		'out': hi('Type')
	},
	{
		'type': 'e',
		'out': hi('Type')
	},
	{
		'type': 'u',
		'out': hi('Type')
	},
	{
		'type': 'g',
		'out': hi('Type')
	},
	{
		'type': 'd',
		'out': hi('Constant')
	},
	{
		'type': 'x',
		'out': hi('Identifier')
	},
]
#pragma endregion

# --- Ctags
#pragma region
NAME_INDEX	  = (1) - 1
PATTERN_INDEX = (3) - 1
TYPE_INDEX	  = (4) - 1

has_signature = ['f', 'p']

def do_ignore(row):
	IGNORE_IF_BEGINS_WITH = '!_'
	for i in IGNORE_IF_BEGINS_WITH:
		if row[0][0] == i:
			return True
	if row[NAME_INDEX].find('operator') != -1:
		return True
	return False


def file2tags(filename, flags):
	global tags_filename, polution_directory
	output = polution_directory + "/" + tags_filename
	cmd = f"ctags --recurse --extras=+F --kinds-C=+px {flags} -o {output} {filename}"
	run(cmd, shell=True)
	return output

def tags2hi(filename):
	def render(target : {}, pattern : str): return target['out'].format(kw=pattern)

	output = set()
	#print2(filename)
	try:
		with open(filename) as f:
			csv_reader = csv.reader(f, delimiter='\t')
			for row in csv_reader:
				if do_ignore(row):
					continue
				for t in targets:
					try:
						if t['type'] == row[TYPE_INDEX]:
							output.add(render(t, re.escape(row[NAME_INDEX])))
					except:
						#print2(row)
						pass
	except FileNotFoundError as e:
		print2(sys.argv[0] + ": No such file or directory '{0}'.".format(filename))
		exit(1)
	return output


def tags2sigs(filename):
	def pattern2signature(name, pattern):
		start = pattern.find(name)
		if pattern.find(')') != -1:
			end = pattern.find(')') + 1
		else:
			end = pattern.find('$')
		return pattern[start : end]
	output = dict()
	#print2(filename)
	with open(filename) as f:
		csv_reader = csv.reader(f, delimiter='\t')
		for row in csv_reader:
			if do_ignore(row):
				continue
			if row[TYPE_INDEX] in has_signature:
				signature = pattern2signature(row[NAME_INDEX], row[PATTERN_INDEX])
				if row[NAME_INDEX] in output:
					output[row[NAME_INDEX]].append(signature)
				else:
					output[row[NAME_INDEX]] = [signature]
	return output
#pragma endregion

# --- Misc. helper
#pragma region
def mimetype(filename):
	# NOTE: `file` is totally broken,
	# this left here as a reminder to not do this:
	# cmd = "file -i {input_}".format(input_=filename)
	cmd = "mimetype {input_}".format(input_=filename)	# I hope you are on gentoo, bud
	r = run(cmd, shell=True, stdout=PIPE)
	r = r.stdout.decode('ascii', errors='replace').split(' ')[1].strip()
	return r

def prepare(file):
	mime = mimetype(file)
	language = None
	flags = ''
	if mime == 'text/x-csrc' or mime == 'text/x-chdr':
		language = 'C'
	elif mime == 'text/x-c++src' or mime == 'text/x-c++hdr':
		language = 'C++'
	if language != None:
		file = preprocessfile(file)
		flags += ' --language-force={0} '.format(language)
	return file, flags

def preprocessfile(filename):
	global preprocessor, polution_directory
	output = polution_directory + "/" + "tags.i"
	run(preprocessor.format(input_=filename, output=output), shell=True)
	return output
#pragma endregion

def main(argv):
	global input_filename
	opts(argv)
	input_filename, flags = prepare(input_filename)
	if action == 'hi':
		output = tags2hi(file2tags(input_filename, flags))
		output = sorted(output)
		output = '\n'.join(output)
	elif action == 'sig':
		output = "let signatures = " + str(tags2sigs(file2tags(input_filename, flags)))
	print(output)

if __name__ == '__main__':
	raise SystemExit(main(sys.argv))
