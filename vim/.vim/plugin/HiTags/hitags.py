#!/bin/env python3

import sys
import re
import csv
from subprocess import run, PIPE

input_filename = ''
preprocessor='clang -fdirectives-only -E {input_} -o {output}'
tags_filename = 'vim.tags'
polution_directory = './'

def print2(s):
	print(s, file=sys.stderr)

def usage(name, x):
	print2("Usage: {0} <options>".format(name))
	print2("\t-h")
	print2("\t-i <file>")
	print2("\t-p <cmd>")
	print2("\t-t <path>")
	exit(x)

def opts(args):
	global input_filename, preprocessor, polution_directory

	try:
		i = args.index("--help") if "--help" in args else -1
		if i != -1:
			usage(args[0], 1)
		else:
			for idx, arg in enumerate(args[1:]):
				if arg in ("-h", "--help"):
					usage(args[0], 0)
				elif arg == "-i":
					input_filename = args[idx + 2]
				elif arg == "-p":
					preprocessor = args[idx + 2]
				elif arg == "-t":
					polution_directory = args[idx + 2]
	except IndexError:
		usage(args[0], 1)
	if input_filename == '':
		usage(args[0], 1)

def hi(group):
	return 'syn keyword\t\tHiTag{group} {{kw}}'.format(group=group)

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
		'type': 'd',
		'out': hi('Constant')
	},
	{
		'type': 'x',
		'out': hi('Identifier')
	},
]
PATTERN_INDEX = 1 - 1
TYPE_INDEX = 4 - 1

def do_ignore(row):
	IGNORE_IF_BEGINS_WITH = '!_'
	for i in IGNORE_IF_BEGINS_WITH:
		if row[0][0] == i:
			return True
	if row[PATTERN_INDEX].find('operator') != -1:
		return True
	return False

def render(target, pattern):
	return target['out'].format(kw=pattern)

def mimetype(filename):
	# Totally broken, it's left here as a reminder to not do this:
	# cmd = "file -i {input_}".format(input_=filename)
	cmd = "mimetype {input_}".format(input_=filename)
	r = run(cmd, shell=True, stdout=PIPE)
	r = r.stdout.decode('ascii', errors='replace').split(' ')[1].strip()
	return r

def preprocessfile(filename):
	global preprocessor, polution_directory
	output = polution_directory + "/" + "tags.i"
	run(preprocessor.format(input_=filename, output=output), shell=True)
	return output

def file2tags(filename, flags):
	global tags_filename, polution_directory
	ctags_command = "ctags --recurse --extras=+F --kinds-C=+px {extras} -o {output} {input_}"
	output = polution_directory + "/" + tags_filename
	cmd = ctags_command.format(extras=flags, output=output, input_=filename)
	run(cmd, shell=True)
	return output

def tags2hi(filename):
	output = set()
	print2(filename)
	try:
		with open(filename) as f:
			csv_reader = csv.reader(f, delimiter='\t')
			for row in csv_reader:
				if do_ignore(row):
					continue
				for t in targets:
					try:
						if t['type'] == row[TYPE_INDEX]:
							output.add(render(t, re.escape(row[PATTERN_INDEX])))
					except:
						print2(row)
	except FileNotFoundError as e:
		print2(sys.argv[0] + ": No such file or directory '{0}'.".format(filename))
		exit(1)
	return output

def main(argv):
	global input_filename
	opts(argv)
	mime = mimetype(input_filename)
	language = ''
	flags = ''
	if mime == 'text/x-csrc' or mime == 'text/x-chdr':
		language = 'C'
	elif mime == 'text/x-c++src' or mime == 'text/x-c++hdr':
		language = 'C++'
	if language != '':
		input_filename = preprocessfile(input_filename)
		flags += ' --language-force={0} '.format(language)
	output = tags2hi(file2tags(input_filename, flags))
	output = sorted(output)
	output = '\n'.join(output)
	print(output)

if __name__ == '__main__':
	raise SystemExit(main(sys.argv))
