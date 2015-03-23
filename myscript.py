import sys

if __name__ == "__main__":
	params = sys.argv[1:5]
	infile = sys.argv[5]
	print "\n*Note:* This text is being printed via myscript.py stdout"
	print "\tInput params are:", params
	print "\tInput file is:", infile
