#!/bin/bash

# This test the embedding of another scirpt (python, perl) or even code into this script
# to make the whole exploit self contained

# This is a heredoc like in other languages but the syntax is a litte strange to get it to print
# out to a file
rm -f test.py
cat << END_OF_STR > "test.py"
#!/usr/bin/python
if __name__ == '__main__':
  print("Hello")
END_OF_STR

chmod +x test.py
./test.py
