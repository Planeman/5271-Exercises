import sys
from string import ascii_lowercase
from parse_rounds import parseRounds

numUsers = 260
usersPerRound = 32
usersToIndex = {}
indexToUsers = {}

def findFriends(send_rounds, rec_rounds, user):
    """
    Returns the friends which the given user has as determined from the
    data from send and receive rounds using an extended statistical
    disclosure attack.
    """
    user_send_prob = [0] * 260
    background_traffic = [1.0/numUsers] * 260
    for index,value in enumerate(background_traffic):
        background_traffic[index] = (usersPerRound - 1) * value

    round_observations = [0] * 260

    num_rounds = float(len(send_rounds))

    for index,send_round in enumerate(send_rounds):
        if user in send_round:
            for user in rec_rounds[index]:
                round_observations[getIndexForUser(user)] += 1/num_rounds

    friends = []
    for index,obs in enumerate(round_observations):
        friend_val = obs - background_traffic[index]
        if friend_val > 0:
            friends.append(getUserForIndex(index))

    return friends


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
    print(usersToIndex)

    send_rounds, receive_rounds = parseRounds(sys.argv[1])

    for user,index in usersToIndex.items():
        friends = findFriends(send_rounds, receive_rounds, user)
        print("{} -> {}".format(user, friends))


