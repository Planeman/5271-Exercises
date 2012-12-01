import sys


def parseRounds(roundFile):
    """
    Reads in a file with a set of rounds and outputs a two tuple of 2D arrays.

    (send_rounds, receive_rounds)
    send_rounds = [[senders for round 1], [senders for round 2],....[senders for round n]]
    receive_rounds = [[rec for round 1, ..., [rec for round n]]
    """

    send_rounds = []
    receive_rounds = []
    with open(roundFile, "r") as rounds:
        content = rounds.readlines()
        print("Found {} lines in rounds file".format(len(content)))

        for line in content:
            if line[0] == 'S':
                (round_num, sep, senders) = line.partition(':')
                send_rounds.append(eval(senders))
            else:
                (round_num, sep, receivers) = line.partition(':')
                receive_rounds.append(eval(receivers))

    return send_rounds, receive_rounds

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: {} [round file]".format(sys.argv[0]))
        sys.exit(2)


    (senders, receivers) = parseRounds(sys.argv[1])
    print("Parsed {} sending rounds".format(len(senders)))
    if len(senders) > 0:
        print("\t{} senders per round".format(len(senders[0])))

    print("Parsed {} receving rounds".format(len(receivers)))
    if len(receivers) > 0:
        print("\t{} receivers per round".format(len(receivers[0])))
