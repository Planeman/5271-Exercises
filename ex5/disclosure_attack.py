import sys
from string import ascii_lowercase
from parse_rounds import parseRounds

numUsers = 260
num_rounds = 256
usersPerRound = 32
usersToIndex = {}
indexToUsers = {}

def findFriends(send_rounds, rec_rounds, user):
    """
    Returns the friends which the given user has as determined from the
    data from send and receive rounds using an extended statistical
    disclosure attack.
    """
    background_traffic = [1.0/numUsers] * 260

    rounds_not_in = 0
    total_messages = 0

    round_observations = [0] * 260

    num_rounds = float(len(send_rounds))

    for index,send_round in enumerate(send_rounds):
        if user in send_round:
            for user in rec_rounds[index]:
                round_observations[getIndexForUser(user)] += 1/num_rounds

            total_messages += send_round.count(user)
        else:
            for user in rec_rounds[index]:
                background_traffic[getIndexForUser(user)] += 1.0/usersPerRound
            rounds_not_in += 1

    background_traffic = map(lambda traffic: traffic / float(rounds_not_in), background_traffic)

    user_avg_msgs = total_messages / float(num_rounds)
    background_traffic = map(lambda traffic: (usersPerRound - user_avg_msgs) * traffic, background_traffic)

    user_recipient_prob = []
    for i in range(numUsers):
        obs = round_observations[i]
        traffic = background_traffic[i]
        user_recipient_prob.append((obs - traffic) / float(user_avg_msgs))

    return filter(lambda x: x > 0, user_recipient_prob)


def buildUserIndexes():
    lowest_char = ord(ascii_lowercase[0])
    for char in ascii_lowercase:
        for i in range(10):
            user = char + str(i)
            index = ((ord(char)*10) + i) - (lowest_char * 10)

            usersToIndex[user] = index
            indexToUsers[index] = user

def getIndexForUser(user):
    return usersToIndex[user]

def getUserForIndex(index):
    return indexToUsers[index]

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: {} [round file]".format(sys.argv[0]))
        sys.exit(1)

    buildUserIndexes()

    send_rounds, receive_rounds = parseRounds(sys.argv[1])

    for user,index in usersToIndex.items():
        friends = findFriends(send_rounds, receive_rounds, user)
        print("{} -> {}".format(user, friends))


